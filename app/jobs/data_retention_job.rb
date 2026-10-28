class DataRetentionJob < ApplicationJob
  queue_as :default

  def perform
    months = ENV.fetch("RETENTION_MONTHS", "12").to_i
    cutoff = months.months.ago
    deleted = AuditEvent.where("event_timestamp < ?", cutoff).delete_all
    Rails.logger.info "DataRetentionJob: purged #{deleted} events older than #{cutoff.to_date}"
  end
end
