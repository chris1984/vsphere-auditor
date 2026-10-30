class AuditEvent < ApplicationRecord
  CATEGORIES = {
    "VmCreatedEvent" => "vm_lifecycle",
    "VmDeployedEvent" => "vm_lifecycle",
    "VmClonedEvent" => "vm_lifecycle",
    "VmRemovedEvent" => "vm_lifecycle",
    "VmPoweredOnEvent" => "vm_power",
    "VmPoweredOffEvent" => "vm_power",
    "VmSuspendedEvent" => "vm_power",
    "VmResetEvent" => "vm_power",
    "VmReconfiguredEvent" => "vm_config",
    "VmRenamedEvent" => "vm_config",
    "VmMigratedEvent" => "vm_config",
    "VmRelocatedEvent" => "vm_config",
    "DrsVmMigratedEvent" => "vm_config",
    "VmSnapshotCreatedEvent" => "vm_snapshot",
    "VmSnapshotRemovedEvent" => "vm_snapshot",
    "VmSnapshotRevertedEvent" => "vm_snapshot",
    "UserLoginSessionEvent" => "session",
    "UserLogoutSessionEvent" => "session",
    "BadUsernameSessionEvent" => "session",
    "AlreadyAuthenticatedSessionEvent" => "session",
    "PermissionAddedEvent" => "permission",
    "PermissionRemovedEvent" => "permission",
    "PermissionUpdatedEvent" => "permission",
    "RoleAddedEvent" => "permission",
    "RoleRemovedEvent" => "permission",
    "DatastoreFileMovedEvent" => "datastore",
    "DatastoreFileDeletedEvent" => "datastore",
    "DatastoreFileCopiedEvent" => "datastore",
    "EnteredMaintenanceModeEvent" => "host",
    "ExitMaintenanceModeEvent" => "host",
    "HostConnectionLostEvent" => "host",
    "HostReconnectionEvent" => "host",
    "FolderCreatedEvent" => "folder",
    "FolderRenamedEvent" => "folder",
    "FolderRemovedEvent" => "folder",
    "TaskEvent" => "task",
    "EventEx" => "other"
  }.freeze

  SEVERITIES = %w[info warning error critical].freeze

  scope :by_category, ->(cat) { where(event_category: cat) if cat.present? }
  scope :by_username, ->(user) { where(username: user) if user.present? }
  scope :by_object_type, ->(type) { where(object_type: type) if type.present? }
  scope :by_severity, ->(sev) { where(severity: sev) if sev.present? }
  scope :in_range, ->(from, to) {
    scope = all
    scope = scope.where("event_timestamp >= ?", from) if from.present?
    scope = scope.where("event_timestamp <= ?", to) if to.present?
    scope
  }
  scope :search, ->(query) {
    where("message ILIKE :q OR event_type ILIKE :q OR object_name ILIKE :q OR username ILIKE :q", q: "%#{sanitize_sql_like(query)}%") if query.present?
  }
  scope :recent, -> { order(event_timestamp: :desc) }

  TASK_MESSAGE_CATEGORIES = {
    /snapshot/i => "vm_snapshot",
    /power\s*(on|off)/i => "vm_power",
    /reset.*virtual\s*machine/i => "vm_power",
    /suspend.*virtual\s*machine/i => "vm_power",
    /create.*virtual\s*machine/i => "vm_lifecycle",
    /clone.*virtual\s*machine/i => "vm_lifecycle",
    /deploy/i => "vm_lifecycle",
    /delete.*virtual\s*machine/i => "vm_lifecycle",
    /destroy/i => "vm_lifecycle",
    /reconfigure/i => "vm_config",
    /rename/i => "vm_config",
    /migrate/i => "vm_config",
    /relocate/i => "vm_config",
    /maintenance\s*mode/i => "host",
    /network\s*config/i => "network",
    /update.*network/i => "network",
    /add.*network/i => "network",
    /remove.*network/i => "network",
    /vswitch/i => "network",
    /port\s*group/i => "network",
    /vmkernel/i => "network",
    /create.*folder/i => "folder",
    /rename.*folder/i => "folder",
    /delete.*folder/i => "folder",
    /remove.*folder/i => "folder",
  }.freeze

  def self.category_for(event_type, message = nil)
    direct = CATEGORIES[event_type]
    return direct if direct && direct != "task"

    if (event_type == "TaskEvent" || direct == "task") && message.present?
      TASK_MESSAGE_CATEGORIES.each do |pattern, category|
        return category if message.match?(pattern)
      end
    end

    direct || "other"
  end

  def self.severity_for(event_type, message = nil)
    case event_type
    when /Bad.*Session/, /ConnectionLost/
      "warning"
    when /Snapshot/, /Removed/, /Deleted/, /Reset/
      "warning"
    when /Error/
      "error"
    else
      if message.present?
        return "warning" if message.match?(/snapshot/i)
        return "warning" if message.match?(/delet|destroy|remov/i)
      end
      "info"
    end
  end
end
