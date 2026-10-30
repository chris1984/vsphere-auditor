require "csv"

class AuditEventsController < ApplicationController
  include Pagy::Backend

  def index
    events = AuditEvent
      .search(params[:q])
      .by_category(params[:category])
      .by_username(params[:username])
      .by_object_type(params[:object_type])
      .by_severity(params[:severity])
      .in_range(params[:from], params[:to])
      .recent

    respond_to do |format|
      format.html do
        @pagy, @events = pagy(events, limit: 50)
        @filter_options = {
          categories: AuditEvent.distinct.pluck(:event_category).compact.sort,
          usernames: AuditEvent.distinct.pluck(:username).compact.sort,
          object_types: AuditEvent.distinct.pluck(:object_type).compact.sort,
          severities: AuditEvent::SEVERITIES
        }
      end
      format.csv do
        filename = "audit_events_#{Date.current.iso8601}.csv"
        send_data generate_csv(events.limit(10_000)), filename: filename, type: "text/csv"
      end
    end
  end

  def show
    @event = AuditEvent.find(params[:id])
  end

  private

  def generate_csv(events)
    CSV.generate(headers: true) do |csv|
      csv << ["Timestamp", "Severity", "Event Type", "Category", "Object Type",
              "Object Name", "User", "Message", "Old Value", "New Value"]
      events.find_each do |event|
        csv << [
          event.event_timestamp&.iso8601,
          event.severity,
          event.event_type,
          event.event_category,
          event.object_type,
          event.object_name,
          event.username,
          event.message,
          event.old_value,
          event.new_value
        ]
      end
    end
  end
end
