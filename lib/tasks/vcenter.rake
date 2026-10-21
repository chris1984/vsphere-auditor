namespace :vcenter do
  desc "Collect events from vCenter now"
  task collect: :environment do
    count = VcenterEventCollector.new.collect
    puts "Imported #{count} events"
  end

  desc "Send daily audit report email now"
  task send_daily_report: :environment do
    AuditReportMailer.daily_report.deliver_now
    puts "Daily report sent"
  end

  desc "Send weekly audit report email now"
  task send_weekly_report: :environment do
    AuditReportMailer.weekly_report.deliver_now
    puts "Weekly report sent"
  end
end
