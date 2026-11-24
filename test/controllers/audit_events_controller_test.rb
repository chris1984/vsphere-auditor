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

  test "toggle_pin pins an unpinned event" do
    assert_not @event.pinned?
    post toggle_pin_audit_event_path(@event)
    assert @event.reload.pinned?
    assert_redirected_to audit_event_path(@event)
  end

  test "toggle_pin unpins a pinned event" do
    @event.update!(pinned: true)
    post toggle_pin_audit_event_path(@event)
    assert_not @event.reload.pinned?
  end

  test "index filters by pinned" do
    pinned = create_event(pinned: true)
    unpinned = create_event(pinned: false)

    get audit_events_path(pinned: "1")
    assert_response :success
  end

  test "CSV includes pinned column" do
    @event.update!(pinned: true)
    get audit_events_path(format: :csv)
    assert_includes response.body, "Pinned"
    assert_includes response.body, "Yes"
  end
end
