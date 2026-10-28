require "test_helper"

class AuditEventsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @event = create_event
  end

  test "index renders successfully" do
    get audit_events_path
    assert_response :success
    assert_select "table"
  end

  test "index filters by category" do
    snapshot = create_event(event_category: "vm_snapshot", event_type: "VmSnapshotCreatedEvent")

    get audit_events_path(category: "vm_snapshot")
    assert_response :success
  end

  test "index filters by username" do
    get audit_events_path(username: "admin@vsphere.local")
    assert_response :success
  end

  test "index filters by severity" do
    get audit_events_path(severity: "info")
    assert_response :success
  end

  test "index filters by date range" do
    get audit_events_path(from: 1.week.ago.to_date, to: Date.current)
    assert_response :success
  end

  test "index exports CSV" do
    get audit_events_path(format: :csv)
    assert_response :success
    assert_equal "text/csv", response.media_type
    assert_includes response.body, "Timestamp"
    assert_includes response.body, @event.event_type
  end

  test "CSV export respects filters" do
    warning_event = create_event(severity: "warning", event_type: "VmSnapshotCreatedEvent", event_category: "vm_snapshot")
    info_event = create_event(severity: "info")

    get audit_events_path(format: :csv, severity: "warning")
    assert_response :success
    assert_includes response.body, "VmSnapshotCreatedEvent"
  end

  test "show renders event detail" do
    get audit_event_path(@event)
    assert_response :success
    assert_select ".detail-grid"
  end
end
