# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20140716002152) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "authentications", force: true do |t|
    t.integer  "user_id",    null: false
    t.string   "provider",   null: false
    t.string   "uid",        null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "conference_admins", force: true do |t|
    t.integer  "conference_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "conference_host_organizations", force: true do |t|
    t.integer  "conference_id"
    t.integer  "organization_id"
    t.integer  "order"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "conference_registration_form_fields", force: true do |t|
    t.integer  "conference_id"
    t.integer  "registration_form_field_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "position"
  end

  create_table "conference_registration_responses", force: true do |t|
    t.integer  "conference_registration_id"
    t.integer  "registration_form_field_id"
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "conference_registrations", force: true do |t|
    t.integer  "conference_id"
    t.integer  "user_id"
    t.string   "is_attending"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_confirmed"
    t.boolean  "is_participant"
    t.boolean  "is_volunteer"
    t.string   "confirmation_token"
    t.binary   "data"
  end

  create_table "conference_types", force: true do |t|
    t.string   "title"
    t.string   "info"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "slug"
  end

  create_table "conferences", force: true do |t|
    t.string   "title"
    t.string   "slug"
    t.datetime "start_date"
    t.datetime "end_date"
    t.text     "info"
    t.string   "poster"
    t.string   "cover"
    t.boolean  "workshop_schedule_published"
    t.boolean  "registration_open"
    t.boolean  "meals_provided"
    t.text     "meal_info"
    t.text     "travel_info"
    t.integer  "conference_type_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "preregistration_info"
    t.text     "registration_info"
    t.text     "postregistration_info"
    t.integer  "cover_attribution_id"
    t.string   "cover_attribution_name"
    t.string   "cover_attribution_src"
    t.integer  "cover_attribution_user_id"
  end

  create_table "event_types", force: true do |t|
    t.string   "slug"
    t.text     "info"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "events", force: true do |t|
    t.string   "title"
    t.string   "slug"
    t.integer  "event_type_id"
    t.integer  "conference_id"
    t.text     "info"
    t.integer  "location_id"
    t.datetime "start_time"
    t.datetime "end_time"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "locations", force: true do |t|
    t.string   "title"
    t.float    "latitude"
    t.float    "longitude"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "country"
    t.string   "territory"
    t.string   "city"
    t.string   "street"
    t.string   "postal_code"
  end

  add_index "locations", ["latitude", "longitude"], name: "index_locations_on_latitude_and_longitude", using: :btree

  create_table "locations_organizations", id: false, force: true do |t|
    t.integer "organization_id"
    t.integer "location_id"
  end

  add_index "locations_organizations", ["organization_id", "location_id"], name: "loc_org_index", using: :btree

  create_table "organization_statuses", force: true do |t|
    t.string   "name"
    t.string   "slug"
    t.string   "info"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "organizations", force: true do |t|
    t.string   "name"
    t.string   "slug"
    t.string   "email_address"
    t.string   "url"
    t.integer  "year_founded"
    t.text     "info"
    t.string   "logo"
    t.string   "avatar"
    t.boolean  "requires_approval"
    t.string   "secret_question"
    t.string   "secret_answer"
    t.integer  "user_organization_replationship_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "cover"
    t.integer  "cover_attribution_id"
    t.string   "cover_attribution_name"
    t.string   "cover_attribution_src"
    t.string   "phone"
    t.integer  "organization_status_id"
    t.integer  "cover_attribution_user_id"
  end

  create_table "registration_form_fields", force: true do |t|
    t.string   "title"
    t.text     "help"
    t.boolean  "required"
    t.string   "field_type"
    t.string   "options"
    t.boolean  "is_retired"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "sessions", force: true do |t|
    t.string   "session_id", null: false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], name: "index_sessions_on_session_id", unique: true, using: :btree
  add_index "sessions", ["updated_at"], name: "index_sessions_on_updated_at", using: :btree

  create_table "translations", force: true do |t|
    t.string   "locale"
    t.string   "key"
    t.text     "value"
    t.text     "interpolations"
    t.boolean  "is_proc",        default: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "user_organization_relationships", force: true do |t|
    t.integer  "user_id",         null: false
    t.integer  "organization_id", null: false
    t.string   "relationship"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", force: true do |t|
    t.string   "username",                                    null: false
    t.string   "email"
    t.string   "crypted_password"
    t.string   "salt"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "remember_me_token"
    t.datetime "remember_me_token_expires_at"
    t.string   "reset_password_token"
    t.datetime "reset_password_token_expires_at"
    t.datetime "reset_password_email_sent_at"
    t.string   "activation_state"
    t.string   "activation_token"
    t.datetime "activation_token_expires_at"
    t.integer  "failed_logins_count",             default: 0
    t.datetime "lock_expires_at"
    t.string   "unlock_token"
    t.string   "avatar"
    t.text     "about_me"
    t.string   "role"
    t.string   "firstname"
    t.string   "lastname"
  end

  add_index "users", ["activation_token"], name: "index_users_on_activation_token", using: :btree
  add_index "users", ["remember_me_token"], name: "index_users_on_remember_me_token", using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", using: :btree

  create_table "versions", force: true do |t|
    t.string   "item_type"
    t.integer  "item_id"
    t.string   "event"
    t.string   "whodunnit"
    t.text     "object"
    t.datetime "created_at"
    t.text     "value"
  end

  create_table "workshop_facilitators", force: true do |t|
    t.integer  "user_id"
    t.integer  "workshop_id"
    t.string   "role"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "workshop_presentation_styles", force: true do |t|
    t.string   "name"
    t.string   "slug"
    t.string   "info"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "workshop_requested_resources", force: true do |t|
    t.integer  "workshop_id"
    t.integer  "workshop_resource_id"
    t.string   "status"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "workshop_resources", force: true do |t|
    t.string   "name"
    t.string   "slug"
    t.string   "info"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "workshop_streams", force: true do |t|
    t.string   "name"
    t.string   "slug"
    t.string   "info"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "workshops", force: true do |t|
    t.string   "title"
    t.string   "slug"
    t.text     "info"
    t.integer  "conference_id"
    t.integer  "workshop_stream_id"
    t.integer  "workshop_presentation_style"
    t.integer  "min_facilitators"
    t.integer  "location_id"
    t.datetime "start_time"
    t.datetime "end_time"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
