require "test_helper"

class SystemStatusControllerTest < ActionDispatch::IntegrationTest
  test "index renders successfully" do
    RbVmomi::VIM.stubs(:connect).raises(Errno::ECONNREFUSED, "Connection refused")

    get system_status_path
    assert_response :success
    assert_select ".status-item", minimum: 3
  end

  test "shows database stats" do
    create_event(event_timestamp: 2.days.ago)
    create_event(event_timestamp: 1.hour.ago)

    RbVmomi::VIM.stubs(:connect).raises(Errno::ECONNREFUSED, "Connection refused")

    get system_status_path
    assert_response :success
  end
end
