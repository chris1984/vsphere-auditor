require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    ENV["AUTH_USERNAME"] = "admin"
    ENV["AUTH_PASSWORD"] = "secret"
  end

  teardown do
    ENV.delete("AUTH_USERNAME")
    ENV.delete("AUTH_PASSWORD")
  end

  test "login page renders" do
    get login_path
    assert_response :success
    assert_select ".login-card"
  end

  test "redirects to dashboard after successful login" do
    post login_path, params: { username: "admin", password: "secret" }
    assert_redirected_to root_path
    follow_redirect!
    assert_response :success
  end

  test "shows error on invalid credentials" do
    post login_path, params: { username: "admin", password: "wrong" }
    assert_response :unprocessable_entity
    assert_select ".login-alert"
  end

  test "unauthenticated users are redirected to login" do
    get root_path
    assert_redirected_to login_path
  end

  test "logout clears session and redirects to login" do
    post login_path, params: { username: "admin", password: "secret" }
    delete logout_path
    assert_redirected_to login_path

    get root_path
    assert_redirected_to login_path
  end

  test "redirects to dashboard if already logged in" do
    post login_path, params: { username: "admin", password: "secret" }
    get login_path
    assert_redirected_to root_path
  end
end
