namespace :vcenter do
  desc "Collect events from vCenter now"
  task collect: :environment do
    count = VcenterEventCollector.new.collect
    puts "Imported #{count} events"
  end

  desc "Re-categorize and re-severity existing events based on message content"
  task recategorize: :environment do
    updated = 0
    AuditEvent.find_each do |event|
      new_category = AuditEvent.category_for(event.event_type, event.message)
      new_severity = AuditEvent.severity_for(event.event_type, event.message)
      changes = {}
      changes[:event_category] = new_category if new_category != event.event_category
      changes[:severity] = new_severity if new_severity != event.severity
      if changes.any?
        event.update!(changes)
        updated += 1
        puts "#{event.id}: #{event.message&.truncate(60)} -> category:#{new_category} severity:#{new_severity}"
      end
    end
    puts "Updated #{updated} events"
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
