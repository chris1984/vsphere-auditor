require "test_helper"

class VcenterEventCollectorTest < ActiveSupport::TestCase
  def setup
    @collector = VcenterEventCollector.new
  end

  def mock_vcenter_event(attrs = {})
    event = mock("vcenter_event")
    event.stubs(:key).returns(attrs[:key] || rand(100_000))
    event.stubs(:chainId).returns(attrs[:chain_id] || rand(100_000))
    event.stubs(:createdTime).returns(attrs[:created_time] || Time.current)
    event.stubs(:userName).returns(attrs[:username] || "admin@vsphere.local")
    event.stubs(:fullFormattedMessage).returns(attrs[:message] || "Test event message")

    klass = mock("event_class")
    klass.stubs(:wsdl_name).returns(attrs[:event_type] || "VmCreatedEvent")
    event.stubs(:class).returns(klass)

    vm_ref = mock("vm_ref")
    vm_ref.stubs(:name).returns(attrs[:vm_name] || "test-vm")
    managed_obj = stub("managed_object", _ref: "vm-123")
    vm_ref.stubs(:vm).returns(managed_obj)
    event.stubs(:respond_to?).with(:vm).returns(true)
    event.stubs(:respond_to?).with(:host).returns(false)
    event.stubs(:respond_to?).with(:ds).returns(false)
    event.stubs(:respond_to?).with(:net).returns(false)
    event.stubs(:respond_to?).with(:folder).returns(false)
    event.stubs(:respond_to?).with(:configSpec).returns(false)
    event.stubs(:vm).returns(vm_ref)

    event
  end

  test "collect imports new events from vCenter" do
    event1 = mock_vcenter_event(key: 1001, event_type: "VmCreatedEvent", message: "Created VM test-vm")
    event2 = mock_vcenter_event(key: 1002, event_type: "VmPoweredOnEvent", message: "Powered on VM test-vm")

    mock_collector = mock("event_collector")
    mock_collector.stubs(:ReadNextEvents).returns([ event1, event2 ], [])
    mock_collector.stubs(:DestroyCollector)

    mock_event_manager = mock("event_manager")
    mock_event_manager.stubs(:CreateCollectorForEvents).returns(mock_collector)

    mock_service_content = mock("service_content")
    mock_service_content.stubs(:eventManager).returns(mock_event_manager)

    mock_vim = mock("vim_connection")
    mock_vim.stubs(:serviceContent).returns(mock_service_content)
    mock_vim.stubs(:close)

    RbVmomi::VIM.stubs(:connect).returns(mock_vim)

    assert_difference "AuditEvent.count", 2 do
      @collector.collect
    end

    imported = AuditEvent.order(:vcenter_event_key).last(2)
    assert_equal "VmCreatedEvent", imported.first.event_type
    assert_equal "vm_lifecycle", imported.first.event_category
    assert_equal "VmPoweredOnEvent", imported.last.event_type
    assert_equal "vm_power", imported.last.event_category
  end

  test "collect skips duplicate events" do
    create_event(vcenter_event_key: 2001)
    event = mock_vcenter_event(key: 2001)

    mock_collector = mock("event_collector")
    mock_collector.stubs(:ReadNextEvents).returns([ event ], [])
    mock_collector.stubs(:DestroyCollector)

    mock_event_manager = mock("event_manager")
    mock_event_manager.stubs(:CreateCollectorForEvents).returns(mock_collector)

    mock_service_content = mock("service_content")
    mock_service_content.stubs(:eventManager).returns(mock_event_manager)

    mock_vim = mock("vim_connection")
    mock_vim.stubs(:serviceContent).returns(mock_service_content)
    mock_vim.stubs(:close)

    RbVmomi::VIM.stubs(:connect).returns(mock_vim)

    assert_no_difference "AuditEvent.count" do
      @collector.collect
    end
  end

  test "collect skips events with keys at or below last imported key" do
    create_event(vcenter_event_key: 5000)
    old_event = mock_vcenter_event(key: 4999)

    mock_collector = mock("event_collector")
    mock_collector.stubs(:ReadNextEvents).returns([ old_event ], [])
    mock_collector.stubs(:DestroyCollector)

    mock_event_manager = mock("event_manager")
    mock_event_manager.stubs(:CreateCollectorForEvents).returns(mock_collector)

    mock_service_content = mock("service_content")
    mock_service_content.stubs(:eventManager).returns(mock_event_manager)

    mock_vim = mock("vim_connection")
    mock_vim.stubs(:serviceContent).returns(mock_service_content)
    mock_vim.stubs(:close)

    RbVmomi::VIM.stubs(:connect).returns(mock_vim)

    assert_no_difference "AuditEvent.count" do
      @collector.collect
    end
  end
end
