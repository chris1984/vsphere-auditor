require "test_helper"

class AlertRulesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @rule = AlertRule.create!(name: "Test Rule", recipients: "admin@example.com", enabled: true)
  end

  test "index renders successfully" do
    get alert_rules_path
    assert_response :success
  end

  test "new renders form" do
    get new_alert_rule_path
    assert_response :success
  end

  test "create saves a new rule" do
    assert_difference "AlertRule.count", 1 do
      post alert_rules_path, params: {
        alert_rule: { name: "Permission Alert", event_category: "permission", recipients: "team@example.com" }
      }
    end
    assert_redirected_to alert_rules_path
  end

  test "edit renders form" do
    get edit_alert_rule_path(@rule)
    assert_response :success
  end

  test "update modifies the rule" do
    patch alert_rule_path(@rule), params: {
      alert_rule: { name: "Updated Rule" }
    }
    assert_redirected_to alert_rules_path
    assert_equal "Updated Rule", @rule.reload.name
  end

  test "destroy deletes the rule" do
    assert_difference "AlertRule.count", -1 do
      delete alert_rule_path(@rule)
    end
    assert_redirected_to alert_rules_path
  end
end
