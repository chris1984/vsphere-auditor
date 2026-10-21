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
  scope :recent, -> { order(event_timestamp: :desc) }

  def self.category_for(event_type)
    CATEGORIES[event_type] || "other"
  end

  def self.severity_for(event_type)
    case event_type
    when /Bad.*Session/, /ConnectionLost/
      "warning"
    when /Removed/, /Deleted/, /Reset/
      "warning"
    when /Error/
      "error"
    else
      "info"
    end
  end
end
