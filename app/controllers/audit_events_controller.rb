class AuditEventsController < ApplicationController
  include Pagy::Backend

  def index
    events = AuditEvent
      .by_category(params[:category])
      .by_username(params[:username])
      .by_object_type(params[:object_type])
      .by_severity(params[:severity])
      .in_range(params[:from], params[:to])
      .recent

    @pagy, @events = pagy(events, limit: 50)

    @filter_options = {
      categories: AuditEvent.distinct.pluck(:event_category).compact.sort,
      usernames: AuditEvent.distinct.pluck(:username).compact.sort,
      object_types: AuditEvent.distinct.pluck(:object_type).compact.sort,
      severities: AuditEvent::SEVERITIES
    }
  end

  def show
    @event = AuditEvent.find(params[:id])
  end
end
