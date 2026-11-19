class CreateVcenterConnections < ActiveRecord::Migration[8.1]
  def change
    create_table :vcenter_connections do |t|
      t.string :name
      t.string :host
      t.string :username
      t.text :encrypted_password
      t.boolean :insecure
      t.boolean :enabled, default: true
      t.datetime :last_collection_at
      t.text :last_error

      t.timestamps
    end

    add_index :vcenter_connections, :host, unique: true
  end
end
