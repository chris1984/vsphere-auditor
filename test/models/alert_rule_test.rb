require "test_helper"

class AlertRuleTest < ActiveSupport::TestCase
  def create_rule(overrides = {})
    AlertRule.create!({
      name: "Test Rule",
      recipients: "admin@example.com",
      enabled: true
    }.merge(overrides))
  end

  test "matches event by category" do
    rule = create_rule(event_category: "permission")
    event = create_event(event_category: "permission")
    other = create_event(event_category: "vm_lifecycle")

    assert rule.matches?(event)
    assert_not rule.matches?(other)
  end

  test "matches event by severity" do
    rule = create_rule(severity: "warning")
    event = create_event(severity: "warning")
    other = create_event(severity: "info")

    assert rule.matches?(event)
    assert_not rule.matches?(other)
  end

  test "matches event by username" do
    rule = create_rule(username_match: "admin")
    event = create_event(username: "admin@vsphere.local")
    other = create_event(username: "ci-runner@vsphere.local")

    assert rule.matches?(event)
    assert_not rule.matches?(other)
  end

  test "matches any event when no filters set" do
    rule = create_rule
    event = create_event

    assert rule.matches?(event)
  end

  test "does not match when disabled" do
    rule = create_rule(enabled: false)
    event = create_event

    assert_not rule.matches?(event)
  end

  test "recipient_list splits by comma" do
    rule = create_rule(recipients: "a@b.com, c@d.com, e@f.com")
    assert_equal %w[a@b.com c@d.com e@f.com], rule.recipient_list
  end

  test "validates presence of name and recipients" do
    rule = AlertRule.new
    assert_not rule.valid?
    assert_includes rule.errors[:name], "can't be blank"
    assert_includes rule.errors[:recipients], "can't be blank"
  end
end
