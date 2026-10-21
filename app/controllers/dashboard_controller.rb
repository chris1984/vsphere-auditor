class DashboardController < ApplicationController
  def index
    @total_events = AuditEvent.count
    @events_today = AuditEvent.where("event_timestamp >= ?", Time.current.beginning_of_day).count
    @events_this_week = AuditEvent.where("event_timestamp >= ?", 7.days.ago).count
    @recent_warnings = AuditEvent.where(severity: %w[warning error critical]).recent.limit(10)
    @by_category = AuditEvent.where("event_timestamp >= ?", 7.days.ago).group(:event_category).count.sort_by { |_, v| -v }
    @by_user = AuditEvent.where("event_timestamp >= ?", 7.days.ago).group(:username).count.sort_by { |_, v| -v }
    @recent_events = AuditEvent.recent.limit(20)
  end
end
