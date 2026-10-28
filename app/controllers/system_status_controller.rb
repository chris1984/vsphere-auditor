class SystemStatusController < ApplicationController
  def index
    @services = check_services
    @collection_stats = collection_stats
    @database_stats = database_stats
  end

  private

  def check_services
    checks = {}

    checks[:rails] = { status: :ok, detail: "Running (#{Rails.env})" }

    checks[:postgresql] = begin
      ActiveRecord::Base.connection.execute("SELECT 1")
      version = ActiveRecord::Base.connection.select_value("SELECT version()")
      { status: :ok, detail: version.split(" on ").first }
    rescue => e
      { status: :error, detail: e.message.truncate(100) }
    end

    checks[:solid_queue] = check_solid_queue

    checks[:vcenter] = check_vcenter

    checks
  end

  def check_solid_queue
    return { status: :warning, detail: "Not loaded" } unless defined?(SolidQueue)

    recent = ActiveRecord::Base.connection_pool.with_connection do |conn|
      conn.transaction(requires_new: true) do
        SolidQueue::Process.where("last_heartbeat_at > ?", 5.minutes.ago).count
      end
    end

    if recent > 0
      { status: :ok, detail: "#{recent} active process(es)" }
    else
      { status: :warning, detail: "No active processes detected" }
    end
  rescue => e
    { status: :warning, detail: e.message.truncate(100) }
  end

  def check_vcenter
    require "rbvmomi"
    vim = RbVmomi::VIM.connect(
      host: ENV["VCENTER_HOST"],
      user: ENV["VCENTER_USER"],
      password: ENV["VCENTER_PASSWORD"],
      insecure: ENV.fetch("VCENTER_INSECURE", "true") == "true"
    )
    about = vim.serviceContent.about
    detail = about.fullName.to_s
    vim.close
    { status: :ok, detail: detail }
  rescue => e
    { status: :error, detail: e.message.truncate(100) }
  end

  def collection_stats
    last_event = AuditEvent.order(created_at: :desc).first
    last_24h = AuditEvent.where("created_at > ?", 24.hours.ago).count

    failed_jobs = begin
      if defined?(SolidQueue)
        ActiveRecord::Base.connection_pool.with_connection do |conn|
          conn.transaction(requires_new: true) do
            SolidQueue::FailedExecution.joins(:job)
              .where(solid_queue_jobs: { class_name: "CollectEventsJob" })
              .count
          end
        end
      else
        0
      end
    rescue
      0
    end

    {
      last_collection: last_event&.created_at,
      events_24h: last_24h,
      failed_jobs: failed_jobs
    }
  end

  def database_stats
    total = AuditEvent.count
    oldest = AuditEvent.order(event_timestamp: :asc).pick(:event_timestamp)
    newest = AuditEvent.order(event_timestamp: :desc).pick(:event_timestamp)

    db_size = begin
      ActiveRecord::Base.connection.select_value(
        "SELECT pg_size_pretty(pg_database_size(current_database()))"
      )
    rescue
      "Unknown"
    end

    {
      total_events: total,
      oldest_event: oldest,
      newest_event: newest,
      database_size: db_size
    }
  end
end
