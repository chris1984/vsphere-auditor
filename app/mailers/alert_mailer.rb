class AlertMailer < ApplicationMailer
  def event_alert(alert_rule, audit_event)
    @rule = alert_rule
    @event = audit_event

    mail(
      to: alert_rule.recipient_list,
      subject: "[vSphere Alert] #{alert_rule.name}: #{audit_event.event_type} - #{audit_event.object_name}"
    )
  end
end
