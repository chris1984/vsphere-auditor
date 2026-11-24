class AddPinnedToAuditEvents < ActiveRecord::Migration[8.1]
  def change
    add_column :audit_events, :pinned, :boolean, default: false, null: false
    add_index :audit_events, :pinned, where: "pinned = true"
  end
end
