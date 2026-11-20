class SessionsController < ApplicationController
  skip_before_action :authenticate, only: %i[new create]
  layout "login"

  def new
    redirect_to root_path if logged_in?
  end

  def create
    if valid_credentials?(params[:username], params[:password])
      session[:authenticated] = true
      session[:username] = params[:username]
      redirect_to root_path
    else
      flash.now[:alert] = "Invalid username or password."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    reset_session
    redirect_to login_path, notice: "Logged out."
  end

  private

  def valid_credentials?(username, password)
    return false if username.blank? || password.blank?
    ActiveSupport::SecurityUtils.secure_compare(username, ENV.fetch("AUTH_USERNAME", "")) &
      ActiveSupport::SecurityUtils.secure_compare(password, ENV.fetch("AUTH_PASSWORD", ""))
  end
end
