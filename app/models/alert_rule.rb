class AlertRule < ApplicationRecord
  validates :name, presence: true
  validates :recipients, presence: true

  scope :active, -> { where(enabled: true) }

  def matches?(audit_event)
    return false unless enabled?
    return false if event_category.present? && audit_event.event_category != event_category
    return false if severity.present? && audit_event.severity != severity
    return false if username_match.present? && !audit_event.username&.match?(/#{Regexp.escape(username_match)}/i)
    true
  end

  def recipient_list
    recipients.split(/[,;\s]+/).map(&:strip).reject(&:blank?)
  end
end
