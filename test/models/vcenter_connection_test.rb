require "test_helper"

class VcenterConnectionTest < ActiveSupport::TestCase
  def create_connection(overrides = {})
    VcenterConnection.create!({
      name: "Test vCenter",
      host: "vcenter-#{SecureRandom.hex(4)}.example.com",
      username: "admin@vsphere.local",
      password: "secret",
      insecure: true,
      enabled: true
    }.merge(overrides))
  end

  test "validates presence of name, host, and username" do
    conn = VcenterConnection.new
    assert_not conn.valid?
    assert_includes conn.errors[:name], "can't be blank"
    assert_includes conn.errors[:host], "can't be blank"
    assert_includes conn.errors[:username], "can't be blank"
  end

  test "validates uniqueness of host" do
    create_connection(host: "vcenter.example.com")
    conn = VcenterConnection.new(name: "Dupe", host: "vcenter.example.com", username: "admin")
    assert_not conn.valid?
    assert_includes conn.errors[:host], "has already been taken"
  end

  test "encrypts password" do
    conn = create_connection(password: "my-secret-pass")
    conn.reload
    assert_equal "my-secret-pass", conn.password
  end

  test "display_name combines name and host" do
    conn = create_connection(name: "Prod", host: "vc.example.com")
    assert_equal "Prod (vc.example.com)", conn.display_name
  end

  test "status returns disabled when not enabled" do
    conn = create_connection(enabled: false)
    assert_equal :disabled, conn.status
  end

  test "status returns error when last_error present" do
    conn = create_connection
    conn.record_failure!("Connection refused")
    assert_equal :error, conn.status
  end

  test "status returns ok after successful collection" do
    conn = create_connection
    conn.record_success!
    assert_equal :ok, conn.status
  end

  test "status returns pending when never collected" do
    conn = create_connection
    assert_equal :pending, conn.status
  end

  test "record_success clears last_error" do
    conn = create_connection
    conn.record_failure!("some error")
    conn.record_success!
    assert_nil conn.last_error
    assert_not_nil conn.last_collection_at
  end

  test "active scope returns only enabled connections" do
    active = create_connection(enabled: true)
    inactive = create_connection(enabled: false)
    assert_includes VcenterConnection.active, active
    assert_not_includes VcenterConnection.active, inactive
  end
end
