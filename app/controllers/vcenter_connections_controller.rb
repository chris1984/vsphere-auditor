class VcenterConnectionsController < ApplicationController
  before_action :set_connection, only: %i[edit update destroy test_connection]

  def index
    @connections = VcenterConnection.order(:name)
  end

  def new
    @connection = VcenterConnection.new(insecure: true, enabled: true)
  end

  def create
    @connection = VcenterConnection.new(connection_params)
    if @connection.save
      redirect_to vcenter_connections_path, notice: "vCenter connection added."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    params_to_use = connection_params
    params_to_use.delete(:password) if params_to_use[:password].blank?
    if @connection.update(params_to_use)
      redirect_to vcenter_connections_path, notice: "vCenter connection updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @connection.destroy
    redirect_to vcenter_connections_path, notice: "vCenter connection removed."
  end

  def test_connection
    require "rbvmomi"
    vim = RbVmomi::VIM.connect(
      host: @connection.host,
      user: @connection.username,
      password: @connection.password,
      insecure: @connection.insecure?
    )
    about = vim.serviceContent.about
    vim.close
    redirect_to vcenter_connections_path, notice: "Connection successful: #{about.fullName}"
  rescue => e
    redirect_to vcenter_connections_path, alert: "Connection failed: #{e.message.truncate(200)}"
  end

  private

  def set_connection
    @connection = VcenterConnection.find(params[:id])
  end

  def connection_params
    params.require(:vcenter_connection).permit(:name, :host, :username, :password, :insecure, :enabled)
  end
end
