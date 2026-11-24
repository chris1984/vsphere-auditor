require "csv"

class AuditEventsController < ApplicationController
  include Pagy::Backend

  def index
    events = AuditEvent
      .search(params[:q])
      .by_pinned(params[:pinned])
      .by_vcenter(params[:vcenter])
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
          vcenters: VcenterConnection.order(:name).pluck(:name, :id),
          categories: AuditEvent.distinct.pluck(:event_category).compact.sort,
          usernames: AuditEvent.distinct.pluck(:username).compact.sort,
          object_types: AuditEvent.distinct.pluck(:object_type).compact.sort,
          severities: AuditEvent::SEVERITIES
        }
        @pinned_count = AuditEvent.pinned.count
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

  def toggle_pin
    @event = AuditEvent.find(params[:id])
    @event.update!(pinned: !@event.pinned?)
    redirect_back fallback_location: audit_event_path(@event),
                  notice: @event.pinned? ? "Event pinned." : "Event unpinned."
  end

  private

  def generate_csv(events)
    CSV.generate(headers: true) do |csv|
      csv << [ "Timestamp", "Pinned", "vCenter", "Severity", "Event Type", "Category", "Object Type",
              "Object Name", "User", "Message", "Old Value", "New Value" ]
      events.includes(:vcenter_connection).find_each do |event|
        csv << [
          event.event_timestamp&.iso8601,
          event.pinned? ? "Yes" : "No",
          event.vcenter_connection&.name,
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
