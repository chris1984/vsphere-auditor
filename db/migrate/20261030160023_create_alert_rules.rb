class CreateAlertRules < ActiveRecord::Migration[8.1]
  def change
    create_table :alert_rules do |t|
      t.string :name
      t.string :event_category
      t.string :severity
      t.string :username_match
      t.string :recipients
      t.boolean :enabled, default: true

      t.timestamps
    end
  end
end
