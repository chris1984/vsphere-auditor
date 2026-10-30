class WeeklyReportJob < ApplicationJob
  queue_as :default

  def perform
    AuditReportMailer.weekly_report.deliver_now
  end
end
