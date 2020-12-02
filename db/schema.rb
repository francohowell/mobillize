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

ActiveRecord::Schema.define(version: 2020_11_23_200522) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "admins", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_admins_on_email", unique: true
    t.index ["reset_password_token"], name: "index_admins_on_reset_password_token", unique: true
  end

  create_table "api_authorizations", force: :cascade do |t|
    t.string "key", null: false
    t.bigint "organization_id", null: false
    t.text "note"
    t.string "auth_environment", default: "testing", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_api_authorizations_on_organization_id"
  end

  create_table "api_logs", force: :cascade do |t|
    t.string "api_method"
    t.string "request"
    t.text "header"
    t.text "params"
    t.string "error_source"
    t.text "error"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "blast_attachments", force: :cascade do |t|
    t.string "attachment", null: false
    t.bigint "blast_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["blast_id"], name: "index_blast_attachments_on_blast_id"
  end

  create_table "blast_contact_relationships", force: :cascade do |t|
    t.string "status", default: "Pending", null: false
    t.integer "contact_id", null: false
    t.bigint "blast_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "message_id"
    t.string "mgage_status"
    t.string "mgage_status_code"
    t.string "contact_number", default: "15555555555", null: false
    t.index ["blast_id"], name: "index_blast_contact_relationships_on_blast_id"
  end

  create_table "blast_group_relationships", force: :cascade do |t|
    t.bigint "blast_id", null: false
    t.bigint "group_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["blast_id"], name: "index_blast_group_relationships_on_blast_id"
    t.index ["group_id"], name: "index_blast_group_relationships_on_group_id"
  end

  create_table "blasts", force: :cascade do |t|
    t.text "message", null: false
    t.boolean "active", default: true, null: false
    t.string "repeat"
    t.date "repeat_end_date"
    t.datetime "send_date_time", null: false
    t.boolean "sms", default: false, null: false
    t.integer "keyword_id", null: false
    t.string "keyword_name", null: false
    t.bigint "organization_id", null: false
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "stripe_id"
    t.string "job_id"
    t.integer "contact_count", default: 0
    t.float "cost", default: 0.0
    t.integer "rate", default: 1, null: false
    t.index ["organization_id"], name: "index_blasts_on_organization_id"
  end

  create_table "chat_media", force: :cascade do |t|
    t.integer "media_number", null: false
    t.string "media_url", null: false
    t.bigint "chat_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["chat_id"], name: "index_chat_media_on_chat_id"
  end

  create_table "contact_uploads", force: :cascade do |t|
    t.string "file", null: false
    t.bigint "user_id"
    t.bigint "organization_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "headers"
    t.boolean "permission_to_text", default: false
    t.index ["organization_id"], name: "index_contact_uploads_on_organization_id"
    t.index ["user_id"], name: "index_contact_uploads_on_user_id"
  end

  create_table "contacts", force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.string "primary_email"
    t.string "secondary_email"
    t.string "cell_phone", null: false
    t.boolean "active"
    t.string "company_name"
    t.bigint "organization_id", null: false
    t.integer "user_id", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "old_key"
    t.string "carrier"
    t.jsonb "dynamics", default: "{}", null: false
    t.index ["dynamics"], name: "index_contacts_on_dynamics", using: :gin
    t.index ["organization_id", "cell_phone"], name: "index_contacts_on_organization_id_and_cell_phone", unique: true
    t.index ["organization_id"], name: "index_contacts_on_organization_id"
  end

  create_table "custom_queues", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.date "start_date"
    t.time "start_time"
    t.date "end_date"
    t.time "end_time"
    t.integer "capacity"
    t.boolean "adjust_capacity_on_completion"
    t.bigint "organization_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_custom_queues_on_organization_id"
  end

  create_table "direct_message_media", force: :cascade do |t|
    t.integer "media_number", null: false
    t.string "media_url", null: false
    t.bigint "direct_message_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["direct_message_id"], name: "index_direct_message_media_on_direct_message_id"
  end

  create_table "direct_messages", force: :cascade do |t|
    t.boolean "media", default: false, null: false
    t.text "message", null: false
    t.string "to", null: false
    t.string "from", null: false
    t.string "message_id", null: false
    t.bigint "organization_contact_relationship_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_contact_relationship_id"], name: "index_direct_messages_on_organization_contact_relationship_id"
  end

  create_table "group_contact_relationships", force: :cascade do |t|
    t.bigint "group_id", null: false
    t.bigint "contact_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["contact_id"], name: "index_group_contact_relationships_on_contact_id"
    t.index ["group_id", "contact_id"], name: "index_group_contact_relationships_on_group_id_and_contact_id", unique: true
    t.index ["group_id"], name: "index_group_contact_relationships_on_group_id"
  end

  create_table "groups", force: :cascade do |t|
    t.string "name", null: false
    t.string "description"
    t.bigint "organization_id", null: false
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "old_key"
    t.index ["organization_id"], name: "index_groups_on_organization_id"
    t.index ["user_id"], name: "index_groups_on_user_id"
  end

  create_table "keyword_group_relationships", force: :cascade do |t|
    t.bigint "keyword_id", null: false
    t.bigint "group_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["group_id"], name: "index_keyword_group_relationships_on_group_id"
    t.index ["keyword_id", "group_id"], name: "index_keyword_group_relationships_on_keyword_id_and_group_id", unique: true
    t.index ["keyword_id"], name: "index_keyword_group_relationships_on_keyword_id"
  end

  create_table "keyword_survey_relationships", force: :cascade do |t|
    t.bigint "survey_id"
    t.bigint "keyword_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["keyword_id"], name: "index_keyword_survey_relationships_on_keyword_id"
    t.index ["survey_id"], name: "index_keyword_survey_relationships_on_survey_id"
  end

  create_table "keywords", force: :cascade do |t|
    t.string "name", null: false
    t.string "help_text"
    t.string "invitation_text"
    t.string "description"
    t.string "opt_in_text"
    t.string "opt_out_text"
    t.boolean "active", default: true, null: false
    t.bigint "organization_id", null: false
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "stripe_id"
    t.datetime "purchase_date"
    t.string "old_key"
    t.string "opt_in_media"
    t.boolean "survey_reserved", default: false, null: false
    t.index ["name"], name: "index_keywords_on_name", unique: true
    t.index ["organization_id"], name: "index_keywords_on_organization_id"
    t.index ["user_id"], name: "index_keywords_on_user_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.string "title", null: false
    t.text "description", null: false
    t.datetime "start_date", null: false
    t.datetime "end_date", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "organization_contact_relationships", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.bigint "contact_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["contact_id"], name: "index_organization_contact_relationships_on_contact_id"
    t.index ["organization_id"], name: "index_organization_contact_relationships_on_organization_id"
  end

  create_table "organization_phone_relationships", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.bigint "phone_number_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "mass_outgoing", default: false, null: false
    t.index ["organization_id", "phone_number_id"], name: "opr_on_organization_id_and_phone_number_id", unique: true
    t.index ["organization_id"], name: "index_organization_phone_relationships_on_organization_id"
    t.index ["phone_number_id"], name: "index_organization_phone_relationships_on_phone_number_id"
  end

  create_table "organizations", force: :cascade do |t|
    t.string "name", null: false
    t.string "street"
    t.string "street2"
    t.string "city"
    t.string "state_providence"
    t.string "country"
    t.string "postal_code"
    t.string "logo"
    t.string "industry", null: false
    t.string "size", null: false
    t.integer "additional_messages", default: 0, null: false
    t.integer "additional_keywords", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "timezone", null: false
    t.boolean "active", default: true, null: false
    t.datetime "inactive_date"
    t.datetime "downgrade_date"
    t.text "notes"
    t.boolean "outside_sale", default: false, null: false
    t.string "downgrade_job_id"
    t.datetime "start_date", null: false
    t.integer "annual_credits", default: 0, null: false
  end

  create_table "payment_sources", force: :cascade do |t|
    t.string "card_id", null: false
    t.string "brand", null: false
    t.string "exp_month", null: false
    t.string "exp_year", null: false
    t.string "last4", null: false
    t.datetime "stripe_creation", null: false
    t.bigint "stripe_account_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["stripe_account_id"], name: "index_payment_sources_on_stripe_account_id"
  end

  create_table "phone_numbers", force: :cascade do |t|
    t.string "pretty", null: false
    t.string "real", null: false
    t.string "service_id", null: false
    t.boolean "global", default: false, null: false
    t.boolean "demo", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "long_code", default: true, null: false
  end

  create_table "responses", force: :cascade do |t|
    t.string "cell_phone", null: false
    t.bigint "contact_id", default: 0, null: false
    t.string "keyword"
    t.boolean "opt_out", default: false, null: false
    t.string "message_type", null: false
    t.text "message", null: false
    t.string "message_id", null: false
    t.string "sub_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "possible_opt_out", default: false, null: false
  end

  create_table "sales_reps", force: :cascade do |t|
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "email", null: false
    t.string "phone", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "stripe_accounts", force: :cascade do |t|
    t.string "stripe_id", null: false
    t.datetime "stripe_creation", null: false
    t.string "payment_source_id", null: false
    t.integer "payment_source_exp_month", null: false
    t.integer "payment_source_exp_year", null: false
    t.string "payment_source_type", null: false
    t.string "payment_source_last4", null: false
    t.string "payment_source_name", null: false
    t.bigint "organization_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "active", default: true
    t.index ["organization_id"], name: "index_stripe_accounts_on_organization_id"
  end

  create_table "survey_answer_uploads", force: :cascade do |t|
    t.string "file"
    t.bigint "user_id"
    t.bigint "organization_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_survey_answer_uploads_on_organization_id"
    t.index ["user_id"], name: "index_survey_answer_uploads_on_user_id"
  end

  create_table "survey_answers", force: :cascade do |t|
    t.string "answer"
    t.bigint "survey_response_id"
    t.bigint "survey_question_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["survey_question_id"], name: "index_survey_answers_on_survey_question_id"
    t.index ["survey_response_id"], name: "index_survey_answers_on_survey_response_id"
  end

  create_table "survey_multiple_choices", force: :cascade do |t|
    t.string "choice_item", null: false
    t.bigint "survey_question_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["survey_question_id"], name: "index_survey_multiple_choices_on_survey_question_id"
  end

  create_table "survey_questions", force: :cascade do |t|
    t.string "question", null: false
    t.integer "question_type", default: 0, null: false
    t.bigint "survey_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "required", default: true, null: false
    t.text "detail"
    t.integer "order"
    t.boolean "allow_other", default: false, null: false
    t.string "max_range"
    t.string "min_range"
    t.boolean "confirm_answer", default: false
    t.boolean "archive", default: false
    t.jsonb "advanced_validation"
    t.text "validation_array", default: [], array: true
    t.index ["survey_id"], name: "index_survey_questions_on_survey_id"
  end

  create_table "survey_queue_relationships", force: :cascade do |t|
    t.bigint "survey_id"
    t.bigint "custom_queue_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["custom_queue_id"], name: "index_survey_queue_relationships_on_custom_queue_id"
    t.index ["survey_id"], name: "index_survey_queue_relationships_on_survey_id"
  end

  create_table "survey_response_queue_relationships", force: :cascade do |t|
    t.bigint "survey_response_id"
    t.bigint "custom_queue_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "completed", default: false
    t.index ["custom_queue_id"], name: "index_survey_response_queue_relationships_on_custom_queue_id"
    t.index ["survey_response_id"], name: "index_survey_response_queue_relationships_on_survey_response_id"
  end

  create_table "survey_responses", force: :cascade do |t|
    t.bigint "survey_id"
    t.bigint "contact_id", null: false
    t.string "contact_number", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["survey_id"], name: "index_survey_responses_on_survey_id"
  end

  create_table "surveys", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.datetime "start_date_time", null: false
    t.datetime "end_date_time", null: false
    t.string "stripe_id"
    t.string "start_message", null: false
    t.string "completion_message", null: false
    t.bigint "organization_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "multiple_responses_allowed", default: false, null: false
    t.string "submit_button_text"
    t.text "submit_text"
    t.boolean "ordered_questions", default: false, null: false
    t.text "confirmation_text"
    t.boolean "preload", default: false
    t.boolean "show_take_again", default: false, null: false
    t.index ["organization_id"], name: "index_surveys_on_organization_id"
  end

  create_table "system_values", force: :cascade do |t|
    t.string "key", null: false
    t.string "value", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "terms", force: :cascade do |t|
    t.string "title", null: false
    t.string "sub_title", null: false
    t.text "content", null: false
    t.datetime "publication_date", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "user_notification_relationships", force: :cascade do |t|
    t.boolean "acceptance", default: false, null: false
    t.bigint "user_id", null: false
    t.bigint "notification_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["notification_id"], name: "index_user_notification_relationships_on_notification_id"
    t.index ["user_id"], name: "index_user_notification_relationships_on_user_id"
  end

  create_table "user_term_relationships", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "term_id", null: false
    t.datetime "acceptance_date", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["term_id"], name: "index_user_term_relationships_on_term_id"
    t.index ["user_id"], name: "index_user_term_relationships_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "cell_phone", null: false
    t.boolean "active", default: true, null: false
    t.bigint "organization_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "old_key"
    t.string "session_token"
    t.boolean "can_send_blasts", default: false, null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["organization_id"], name: "index_users_on_organization_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "custom_queues", "organizations"
  add_foreign_key "keyword_survey_relationships", "keywords"
  add_foreign_key "keyword_survey_relationships", "surveys"
  add_foreign_key "survey_queue_relationships", "custom_queues"
  add_foreign_key "survey_queue_relationships", "surveys"
  add_foreign_key "survey_response_queue_relationships", "custom_queues"
  add_foreign_key "survey_response_queue_relationships", "survey_responses"
  add_foreign_key "survey_responses", "surveys"
end
