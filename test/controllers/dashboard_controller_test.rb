require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  test "index renders successfully with no events" do
    get root_path
    assert_response :success
    assert_select ".stat-card", minimum: 4
  end

  test "index renders with events" do
    create_event(event_timestamp: 1.hour.ago)
    create_event(event_timestamp: 2.hours.ago, severity: "warning", event_category: "vm_snapshot")

    get root_path
    assert_response :success
  end

  test "index redirects to login when auth configured" do
    ENV["AUTH_USERNAME"] = "admin"
    ENV["AUTH_PASSWORD"] = "secret"

    get root_path
    assert_redirected_to login_path
  ensure
    ENV.delete("AUTH_USERNAME")
    ENV.delete("AUTH_PASSWORD")
  end
end
