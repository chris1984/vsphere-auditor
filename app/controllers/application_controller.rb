class ApplicationController < ActionController::Base
  allow_browser versions: :modern
  stale_when_importmap_changes

  before_action :authenticate
  helper_method :logged_in?, :current_username

  private

  def authenticate
    return unless auth_configured?
    return if logged_in?

    redirect_to login_path
  end

  def logged_in?
    session[:authenticated] == true
  end

  def current_username
    session[:username]
  end

  def auth_configured?
    ENV["AUTH_USERNAME"].present? && ENV["AUTH_PASSWORD"].present?
  end
end
