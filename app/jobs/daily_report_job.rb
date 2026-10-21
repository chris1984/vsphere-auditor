class DailyReportJob < ApplicationJob
  queue_as :default

  def perform
    AuditReportMailer.daily_report.deliver_now
  end
end
