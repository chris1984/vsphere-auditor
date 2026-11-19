require "test_helper"

class VcenterConnectionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @connection = VcenterConnection.create!(
      name: "Test vCenter",
      host: "vcenter.test.local",
      username: "admin@vsphere.local",
      password: "secret",
      insecure: true,
      enabled: true
    )
  end

  test "index renders successfully" do
    get vcenter_connections_path
    assert_response :success
  end

  test "new renders form" do
    get new_vcenter_connection_path
    assert_response :success
  end

  test "create saves a new connection" do
    assert_difference "VcenterConnection.count", 1 do
      post vcenter_connections_path, params: {
        vcenter_connection: {
          name: "New vCenter",
          host: "vcenter-new.example.com",
          username: "admin@vsphere.local",
          password: "secret",
          insecure: true
        }
      }
    end
    assert_redirected_to vcenter_connections_path
  end

  test "edit renders form" do
    get edit_vcenter_connection_path(@connection)
    assert_response :success
  end

  test "update modifies the connection" do
    patch vcenter_connection_path(@connection), params: {
      vcenter_connection: { name: "Updated Name" }
    }
    assert_redirected_to vcenter_connections_path
    assert_equal "Updated Name", @connection.reload.name
  end

  test "update with blank password keeps existing password" do
    patch vcenter_connection_path(@connection), params: {
      vcenter_connection: { name: "Same Pass", password: "" }
    }
    assert_redirected_to vcenter_connections_path
    assert_equal "secret", @connection.reload.password
  end

  test "destroy deletes the connection" do
    assert_difference "VcenterConnection.count", -1 do
      delete vcenter_connection_path(@connection)
    end
    assert_redirected_to vcenter_connections_path
  end

  test "test_connection reports failure for unreachable host" do
    RbVmomi::VIM.stubs(:connect).raises(Errno::ECONNREFUSED, "Connection refused")
    post test_connection_vcenter_connection_path(@connection)
    assert_redirected_to vcenter_connections_path
    assert_match(/failed/i, flash[:alert])
  end
end
