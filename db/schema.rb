# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_10_21_195728) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "audit_events", force: :cascade do |t|
    t.string "event_type"
    t.string "event_category"
    t.string "object_type"
    t.string "object_name"
    t.string "object_ref"
    t.string "username"
    t.text "message"
    t.text "old_value"
    t.text "new_value"
    t.string "severity"
    t.integer "vcenter_event_key"
    t.integer "vcenter_chain_id"
    t.datetime "event_timestamp"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_category"], name: "index_audit_events_on_event_category"
    t.index ["event_timestamp"], name: "index_audit_events_on_event_timestamp"
    t.index ["event_type"], name: "index_audit_events_on_event_type"
    t.index ["object_type"], name: "index_audit_events_on_object_type"
    t.index ["severity"], name: "index_audit_events_on_severity"
    t.index ["username"], name: "index_audit_events_on_username"
    t.index ["vcenter_event_key"], name: "index_audit_events_on_vcenter_event_key", unique: true
  end
end
