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

ActiveRecord::Schema[8.0].define(version: 2026_06_23_122808) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "leads", force: :cascade do |t|
    t.string "source"
    t.string "group_name"
    t.string "post_url"
    t.text "post_text", null: false
    t.datetime "posted_at"
    t.boolean "is_lead", default: false, null: false
    t.date "date_from"
    t.date "date_to"
    t.integer "adults"
    t.integer "children"
    t.integer "guests_total"
    t.string "location"
    t.decimal "confidence", precision: 5, scale: 4
    t.string "availability_status", default: "unknown", null: false
    t.datetime "notification_sent_at"
    t.jsonb "raw_extraction", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["post_url"], name: "index_leads_on_post_url", unique: true, where: "((post_url IS NOT NULL) AND ((post_url)::text <> ''::text))"
    t.index ["posted_at"], name: "index_leads_on_posted_at"
  end
end
