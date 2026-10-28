class ApplicationController < ActionController::Base
  allow_browser versions: :modern
  stale_when_importmap_changes

  before_action :authenticate

  private

  def authenticate
    return unless auth_configured?

    authenticate_or_request_with_http_basic("vSphere Auditor") do |username, password|
      ActiveSupport::SecurityUtils.secure_compare(username, ENV["AUTH_USERNAME"]) &
        ActiveSupport::SecurityUtils.secure_compare(password, ENV["AUTH_PASSWORD"])
    end
  end

  def auth_configured?
    ENV["AUTH_USERNAME"].present? && ENV["AUTH_PASSWORD"].present?
  end
end
