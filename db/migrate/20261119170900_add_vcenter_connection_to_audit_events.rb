class AddVcenterConnectionToAuditEvents < ActiveRecord::Migration[8.1]
  def change
    add_reference :audit_events, :vcenter_connection, null: true, foreign_key: true
  end
end
