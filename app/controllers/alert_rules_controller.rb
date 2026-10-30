class AlertRulesController < ApplicationController
  before_action :set_alert_rule, only: %i[edit update destroy]

  def index
    @alert_rules = AlertRule.order(created_at: :desc)
  end

  def new
    @alert_rule = AlertRule.new(enabled: true)
  end

  def create
    @alert_rule = AlertRule.new(alert_rule_params)
    if @alert_rule.save
      redirect_to alert_rules_path, notice: "Alert rule created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @alert_rule.update(alert_rule_params)
      redirect_to alert_rules_path, notice: "Alert rule updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @alert_rule.destroy
    redirect_to alert_rules_path, notice: "Alert rule deleted."
  end

  private

  def set_alert_rule
    @alert_rule = AlertRule.find(params[:id])
  end

  def alert_rule_params
    params.require(:alert_rule).permit(:name, :event_category, :severity, :username_match, :recipients, :enabled)
  end
end
