require "test_helper"

class DataRetentionJobTest < ActiveSupport::TestCase
  test "purges events older than retention period" do
    old_event = create_event(event_timestamp: 13.months.ago)
    recent_event = create_event(event_timestamp: 1.day.ago)

    DataRetentionJob.perform_now

    assert_not AuditEvent.exists?(old_event.id)
    assert AuditEvent.exists?(recent_event.id)
  end

  test "respects RETENTION_MONTHS env var" do
    event_7_months_old = create_event(event_timestamp: 7.months.ago)
    event_4_months_old = create_event(event_timestamp: 4.months.ago)

    ENV["RETENTION_MONTHS"] = "6"
    DataRetentionJob.perform_now

    assert_not AuditEvent.exists?(event_7_months_old.id)
    assert AuditEvent.exists?(event_4_months_old.id)
  ensure
    ENV.delete("RETENTION_MONTHS")
  end

  test "does nothing when no old events exist" do
    recent = create_event(event_timestamp: 1.day.ago)

    assert_no_difference "AuditEvent.count" do
      DataRetentionJob.perform_now
    end
  end
end
