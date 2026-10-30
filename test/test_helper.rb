ENV["RAILS_ENV"] ||= "test"
ENV["VCENTER_HOST"] ||= "vcenter.test.local"
ENV["VCENTER_USER"] ||= "testuser"
ENV["VCENTER_PASSWORD"] ||= "testpass"

require_relative "../config/environment"
require "rails/test_help"
require "mocha/minitest"

ENV.delete("AUTH_USERNAME")
ENV.delete("AUTH_PASSWORD")

class ActiveSupport::TestCase
  parallelize(workers: :number_of_processors)

  def create_event(overrides = {})
    AuditEvent.create!({
      event_type: "VmCreatedEvent",
      event_category: "vm_lifecycle",
      object_type: "VirtualMachine",
      object_name: "test-vm-01",
      username: "admin@vsphere.local",
      message: "Created virtual machine test-vm-01",
      severity: "info",
      vcenter_event_key: rand(100_000),
      vcenter_chain_id: rand(100_000),
      event_timestamp: Time.current
    }.merge(overrides))
  end
end
