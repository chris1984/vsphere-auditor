require "test_helper"

class AuditEventTest < ActiveSupport::TestCase
  test "category_for returns direct match for known event types" do
    assert_equal "vm_lifecycle", AuditEvent.category_for("VmCreatedEvent")
    assert_equal "vm_power", AuditEvent.category_for("VmPoweredOnEvent")
    assert_equal "vm_snapshot", AuditEvent.category_for("VmSnapshotCreatedEvent")
    assert_equal "session", AuditEvent.category_for("UserLoginSessionEvent")
    assert_equal "permission", AuditEvent.category_for("PermissionAddedEvent")
    assert_equal "host", AuditEvent.category_for("EnteredMaintenanceModeEvent")
    assert_equal "folder", AuditEvent.category_for("FolderCreatedEvent")
    assert_equal "datastore", AuditEvent.category_for("DatastoreFileDeletedEvent")
  end

  test "category_for returns other for unknown event types" do
    assert_equal "other", AuditEvent.category_for("SomeRandomEvent")
  end

  test "category_for classifies TaskEvents by message content" do
    assert_equal "vm_snapshot", AuditEvent.category_for("TaskEvent", "Task: Create virtual machine snapshot")
    assert_equal "vm_power", AuditEvent.category_for("TaskEvent", "Task: Power on virtual machine")
    assert_equal "vm_power", AuditEvent.category_for("TaskEvent", "Task: Power off virtual machine")
    assert_equal "vm_lifecycle", AuditEvent.category_for("TaskEvent", "Task: Create virtual machine")
    assert_equal "vm_lifecycle", AuditEvent.category_for("TaskEvent", "Task: Deploy OVF template")
    assert_equal "vm_config", AuditEvent.category_for("TaskEvent", "Task: Reconfigure virtual machine")
    assert_equal "host", AuditEvent.category_for("TaskEvent", "Task: Enter maintenance mode")
    assert_equal "folder", AuditEvent.category_for("TaskEvent", "Task: Create folder")
  end

  test "category_for falls back to task for unrecognized TaskEvent messages" do
    assert_equal "task", AuditEvent.category_for("TaskEvent", "Task: Something unknown happened")
  end

  test "category_for ignores message for non-task event types" do
    assert_equal "vm_lifecycle", AuditEvent.category_for("VmCreatedEvent", "some message about snapshots")
  end

  test "severity_for returns warning for snapshot events" do
    assert_equal "warning", AuditEvent.severity_for("VmSnapshotCreatedEvent")
    assert_equal "warning", AuditEvent.severity_for("VmSnapshotRemovedEvent")
  end

  test "severity_for returns warning for delete and remove events" do
    assert_equal "warning", AuditEvent.severity_for("VmRemovedEvent")
    assert_equal "warning", AuditEvent.severity_for("DatastoreFileDeletedEvent")
  end

  test "severity_for returns warning for bad session events" do
    assert_equal "warning", AuditEvent.severity_for("BadUsernameSessionEvent")
  end

  test "severity_for returns error for error events" do
    assert_equal "error", AuditEvent.severity_for("SomeErrorEvent")
  end

  test "severity_for returns info by default" do
    assert_equal "info", AuditEvent.severity_for("VmCreatedEvent")
    assert_equal "info", AuditEvent.severity_for("UserLoginSessionEvent")
  end

  test "severity_for classifies by message for TaskEvents" do
    assert_equal "warning", AuditEvent.severity_for("TaskEvent", "Task: Create virtual machine snapshot")
    assert_equal "warning", AuditEvent.severity_for("TaskEvent", "Task: Delete virtual machine")
    assert_equal "warning", AuditEvent.severity_for("TaskEvent", "Task: Destroy folder")
    assert_equal "info", AuditEvent.severity_for("TaskEvent", "Task: Power on")
  end

  test "scopes filter correctly" do
    vm_event = create_event(event_category: "vm_lifecycle", username: "alice", severity: "info", event_timestamp: 1.hour.ago)
    snapshot_event = create_event(event_category: "vm_snapshot", username: "bob", severity: "warning", event_timestamp: 2.days.ago)

    assert_includes AuditEvent.by_category("vm_lifecycle"), vm_event
    assert_not_includes AuditEvent.by_category("vm_lifecycle"), snapshot_event

    assert_includes AuditEvent.by_username("alice"), vm_event
    assert_not_includes AuditEvent.by_username("alice"), snapshot_event

    assert_includes AuditEvent.by_severity("warning"), snapshot_event
    assert_not_includes AuditEvent.by_severity("warning"), vm_event
  end

  test "in_range scope filters by date range" do
    old_event = create_event(event_timestamp: 10.days.ago)
    recent_event = create_event(event_timestamp: 1.hour.ago)

    results = AuditEvent.in_range(3.days.ago, Time.current)
    assert_includes results, recent_event
    assert_not_includes results, old_event
  end

  test "scopes return all when given nil" do
    event = create_event
    assert_includes AuditEvent.by_category(nil), event
    assert_includes AuditEvent.by_username(nil), event
    assert_includes AuditEvent.by_severity(nil), event
    assert_includes AuditEvent.in_range(nil, nil), event
  end
end
