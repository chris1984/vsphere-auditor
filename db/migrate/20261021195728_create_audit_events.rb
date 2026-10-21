class CreateAuditEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :audit_events do |t|
      t.string :event_type
      t.string :event_category
      t.string :object_type
      t.string :object_name
      t.string :object_ref
      t.string :username
      t.text :message
      t.text :old_value
      t.text :new_value
      t.string :severity
      t.integer :vcenter_event_key
      t.integer :vcenter_chain_id
      t.datetime :event_timestamp

      t.timestamps
    end

    add_index :audit_events, :event_timestamp
    add_index :audit_events, :event_type
    add_index :audit_events, :event_category
    add_index :audit_events, :object_type
    add_index :audit_events, :username
    add_index :audit_events, :severity
    add_index :audit_events, :vcenter_event_key, unique: true
  end
end
