require "rbvmomi"

class VcenterEventCollector
  BATCH_SIZE = 100

  def initialize
    @host = ENV.fetch("VCENTER_HOST")
    @user = ENV.fetch("VCENTER_USER")
    @password = ENV.fetch("VCENTER_PASSWORD")
    @insecure = ENV.fetch("VCENTER_INSECURE", "true") == "true"
  end

  def collect
    connect do |vim|
      event_manager = vim.serviceContent.eventManager
      last_key = AuditEvent.maximum(:vcenter_event_key) || 0
      events = fetch_events(event_manager, last_key)
      imported = import_events(events)
      Rails.logger.info "VcenterEventCollector: imported #{imported} events"
      imported
    end
  end

  private

  def connect
    vim = RbVmomi::VIM.connect(
      host: @host,
      user: @user,
      password: @password,
      insecure: @insecure
    )
    yield vim
  ensure
    vim&.close
  end

  def fetch_events(event_manager, after_key)
    filter_spec = RbVmomi::VIM.EventFilterSpec(
      time: RbVmomi::VIM.EventFilterSpecByTime(
        beginTime: 1.day.ago
      )
    )

    collector = event_manager.CreateCollectorForEvents(filter: filter_spec)
    collector.SetCollectorPageSize(page: BATCH_SIZE)

    events = []
    loop do
      page = collector.ReadNextEvents(maxCount: BATCH_SIZE)
      break if page.empty?
      events.concat(page.reject { |e| e.key <= after_key })
    end

    collector.DestroyCollector
    events
  end

  def import_events(events)
    count = 0
    events.each do |event|
      next if AuditEvent.exists?(vcenter_event_key: event.key)

      AuditEvent.create!(
        event_type: event.class.wsdl_name,
        event_category: AuditEvent.category_for(event.class.wsdl_name),
        object_type: extract_object_type(event),
        object_name: extract_object_name(event),
        object_ref: extract_object_ref(event),
        username: event.userName,
        message: event.fullFormattedMessage,
        old_value: extract_change_value(event, :old),
        new_value: extract_change_value(event, :new),
        severity: AuditEvent.severity_for(event.class.wsdl_name),
        vcenter_event_key: event.key,
        vcenter_chain_id: event.chainId,
        event_timestamp: event.createdTime
      )
      count += 1
    end
    count
  end

  def extract_object_type(event)
    if event.respond_to?(:vm) && event.vm
      "VirtualMachine"
    elsif event.respond_to?(:host) && event.host
      "HostSystem"
    elsif event.respond_to?(:ds) && event.ds
      "Datastore"
    elsif event.respond_to?(:net) && event.net
      "Network"
    else
      "Unknown"
    end
  end

  def extract_object_name(event)
    if event.respond_to?(:vm) && event.vm
      event.vm.name
    elsif event.respond_to?(:host) && event.host
      event.host.name
    elsif event.respond_to?(:ds) && event.ds
      event.ds.name
    elsif event.respond_to?(:net) && event.net
      event.net.name
    else
      nil
    end
  end

  def extract_object_ref(event)
    if event.respond_to?(:vm) && event.vm
      event.vm.vm&._ref
    elsif event.respond_to?(:host) && event.host
      event.host.host&._ref
    else
      nil
    end
  end

  def extract_change_value(event, direction)
    return nil unless event.respond_to?(:configSpec)

    spec = event.configSpec rescue nil
    return nil unless spec

    changes = []
    spec.props.each do |prop, val|
      next if val.nil?
      changes << "#{prop}: #{val}"
    end
    direction == :new ? changes.join("\n") : nil
  end
end
