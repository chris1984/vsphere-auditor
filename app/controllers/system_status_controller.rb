class SystemStatusController < ApplicationController
  def index
    @services = check_services
    @collection_stats = collection_stats
    @database_stats = database_stats
    @alert_stats = alert_stats
    @scheduled_jobs = scheduled_jobs
    @app_stats = app_stats
    @retention_stats = retention_stats
    @event_sparkline = event_sparkline
  end

  private

  def check_services
    checks = {}

    uptime = Time.current - Rails.application.config.app_boot_time
    checks[:rails] = { status: :ok, detail: "Running (#{Rails.env}) — up #{format_duration(uptime)}" }

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
    last_collection_job = find_last_completed_job("CollectEventsJob")
    last_event = AuditEvent.order(created_at: :desc).first
    last_24h = AuditEvent.where("created_at > ?", 24.hours.ago).count

    events_last_run = if last_collection_job
      AuditEvent.where("created_at >= ?", last_collection_job[:completed_at] - 1.minute)
        .where("created_at <= ?", last_collection_job[:completed_at] + 1.minute).count
    end

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
      last_collection: last_collection_job,
      last_event_at: last_event&.created_at,
      events_24h: last_24h,
      events_last_run: events_last_run,
      failed_jobs: failed_jobs
    }
  end

  def database_stats
    total = AuditEvent.count
    alert_rules_count = AlertRule.count
    oldest = AuditEvent.order(event_timestamp: :asc).pick(:event_timestamp)
    newest = AuditEvent.order(event_timestamp: :desc).pick(:event_timestamp)

    db_size = begin
      ActiveRecord::Base.connection.select_value(
        "SELECT pg_size_pretty(pg_database_size(current_database()))"
      )
    rescue
      "Unknown"
    end

    table_sizes = begin
      ActiveRecord::Base.connection.select_all(<<~SQL).to_a
        SELECT relname AS name,
               pg_size_pretty(pg_total_relation_size(c.oid)) AS size,
               n_live_tup AS row_count
        FROM pg_class c
        JOIN pg_stat_user_tables s ON s.relname = c.relname
        WHERE c.relkind = 'r'
        ORDER BY pg_total_relation_size(c.oid) DESC
        LIMIT 10
      SQL
    rescue
      []
    end

    {
      total_events: total,
      alert_rules_count: alert_rules_count,
      oldest_event: oldest,
      newest_event: newest,
      database_size: db_size,
      table_sizes: table_sizes
    }
  end

  def alert_stats
    active_rules = begin
      ActiveRecord::Base.connection_pool.with_connection do |conn|
        conn.transaction(requires_new: true) { AlertRule.active.count }
      end
    rescue
      0
    end

    total_rules = begin
      ActiveRecord::Base.connection_pool.with_connection do |conn|
        conn.transaction(requires_new: true) { AlertRule.count }
      end
    rescue
      0
    end

    alerts_today = begin
      if defined?(SolidQueue)
        ActiveRecord::Base.connection_pool.with_connection do |conn|
          conn.transaction(requires_new: true) do
            SolidQueue::Job
              .where(class_name: "ActionMailer::MailDeliveryJob")
              .where("arguments LIKE ?", "%AlertMailer%")
              .where("created_at > ?", Time.current.beginning_of_day)
              .count
          end
        end
      else
        0
      end
    rescue
      0
    end

    { active_rules: active_rules, total_rules: total_rules, alerts_today: alerts_today }
  end

  def scheduled_jobs
    tasks = begin
      if defined?(SolidQueue)
        ActiveRecord::Base.connection_pool.with_connection do |conn|
          conn.transaction(requires_new: true) do
            SolidQueue::RecurringTask.all.map do |task|
              next_at = task.next_time rescue nil
              {
                key: task.key,
                class_name: task.class_name || task.command&.truncate(40),
                schedule: task.schedule,
                next_run: next_at
              }
            end
          end
        end
      else
        []
      end
    rescue
      []
    end

    tasks.compact.sort_by { |t| t[:next_run] || Time.current + 100.years }
  end

  def find_last_completed_job(class_name)
    return nil unless defined?(SolidQueue)

    job = ActiveRecord::Base.connection_pool.with_connection do |conn|
      conn.transaction(requires_new: true) do
        SolidQueue::Job
          .where(class_name: class_name)
          .where.not(finished_at: nil)
          .order(finished_at: :desc)
          .first
      end
    end

    return nil unless job

    { completed_at: job.finished_at, created_at: job.created_at }
  rescue
    nil
  end

  def app_stats
    avg_response = begin
      if defined?(ActiveSupport::Notifications)
        times = Rails.cache.read("response_times") || []
        times.any? ? (times.sum / times.size).round(1) : nil
      end
    rescue
      nil
    end

    collection_durations = begin
      if defined?(SolidQueue)
        ActiveRecord::Base.connection_pool.with_connection do |conn|
          conn.transaction(requires_new: true) do
            jobs = SolidQueue::Job
              .where(class_name: "CollectEventsJob")
              .where.not(finished_at: nil)
              .order(finished_at: :desc)
              .limit(10)
              .pluck(:created_at, :finished_at)

            if jobs.any?
              durations = jobs.map { |c, f| f - c }
              { avg: durations.sum / durations.size, last: durations.first }
            end
          end
        end
      end
    rescue
      nil
    end

    { avg_response: avg_response, collection_durations: collection_durations }
  end

  def retention_stats
    months = ENV.fetch("RETENTION_MONTHS", "12").to_i
    cutoff = months.months.ago
    eligible = begin
      ActiveRecord::Base.connection_pool.with_connection do |conn|
        conn.transaction(requires_new: true) do
          AuditEvent.where("event_timestamp < ?", cutoff).count
        end
      end
    rescue
      0
    end

    next_purge = begin
      if defined?(SolidQueue)
        ActiveRecord::Base.connection_pool.with_connection do |conn|
          conn.transaction(requires_new: true) do
            task = SolidQueue::RecurringTask.find_by(key: "purge_old_events")
            task&.next_time
          end
        end
      end
    rescue
      nil
    end

    { months: months, eligible_count: eligible, next_purge: next_purge }
  end

  def event_sparkline
    7.downto(0).map do |days_ago|
      date = days_ago.days.ago.to_date
      count = begin
        ActiveRecord::Base.connection_pool.with_connection do |conn|
          conn.transaction(requires_new: true) do
            AuditEvent.where(event_timestamp: date.beginning_of_day..date.end_of_day).count
          end
        end
      rescue
        0
      end
      { date: date, count: count }
    end
  end

  def format_duration(seconds)
    days = (seconds / 86400).to_i
    hours = ((seconds % 86400) / 3600).to_i
    minutes = ((seconds % 3600) / 60).to_i

    parts = []
    parts << "#{days}d" if days > 0
    parts << "#{hours}h" if hours > 0
    parts << "#{minutes}m" if minutes > 0
    parts.empty? ? "< 1m" : parts.join(" ")
  end
end
