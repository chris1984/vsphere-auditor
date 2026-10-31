class AuditReportMailer < ApplicationMailer
  default from: ENV.fetch("REPORT_FROM_EMAIL", "vsphere-auditor@example.com")

  def daily_report
    @date = Date.yesterday
    @events = AuditEvent.where(
      event_timestamp: @date.beginning_of_day..@date.end_of_day
    ).order(event_timestamp: :asc)

    @summary = build_summary(@events)

    mail(
      to: ENV.fetch("REPORT_RECIPIENTS", "admin@example.com"),
      subject: "vSphere Audit Report - #{@date.strftime('%B %d, %Y')}"
    )
  end

  def weekly_report
    @end_date = Date.yesterday
    @start_date = @end_date - 6
    @events = AuditEvent.where(
      event_timestamp: @start_date.beginning_of_day..@end_date.end_of_day
    ).order(event_timestamp: :asc)

    @summary = build_summary(@events)

    mail(
      to: ENV.fetch("REPORT_RECIPIENTS", "admin@example.com"),
      subject: "vSphere Weekly Audit Report - #{@start_date.strftime('%b %d')} to #{@end_date.strftime('%b %d, %Y')}"
    )
  end

  private

  def build_summary(events)
    unordered = events.reorder("")
    {
      total: events.count,
      by_category: unordered.group(:event_category).count,
      by_severity: unordered.group(:severity).count,
      by_user: unordered.group(:username).count,
      by_object_type: unordered.group(:object_type).count,
      warnings: events.where(severity: %w[warning error critical])
    }
  end
end
