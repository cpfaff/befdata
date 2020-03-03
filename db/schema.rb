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

ActiveRecord::Schema.define(version: 20200303135004) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "author_paperproposals", force: :cascade do |t|
    t.integer  "paperproposal_id"
    t.integer  "user_id"
    t.string   "kind"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["paperproposal_id", "user_id"], name: "index_author_paperproposals_on_paperproposal_id_and_user_id", using: :btree
    t.index ["paperproposal_id"], name: "index_author_paperproposals_on_paperproposal_id", using: :btree
    t.index ["user_id", "paperproposal_id"], name: "index_author_paperproposals_on_user_id_and_paperproposal_id", using: :btree
    t.index ["user_id"], name: "index_author_paperproposals_on_user_id", using: :btree
  end

  create_table "cart_datasets", force: :cascade do |t|
    t.integer  "cart_id"
    t.integer  "dataset_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["cart_id"], name: "index_cart_datasets_on_cart_id", using: :btree
    t.index ["dataset_id"], name: "index_cart_datasets_on_dataset_id", using: :btree
  end

  create_table "carts", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "categories", force: :cascade do |t|
    t.string   "short"
    t.string   "long"
    t.text     "description"
    t.text     "comment"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "datagroup_id"
    t.index ["datagroup_id"], name: "index_categories_on_datagroup_id", using: :btree
    t.index ["long"], name: "index_categories_on_long", using: :btree
    t.index ["short"], name: "index_categoricvalues_on_short", using: :btree
  end

  create_table "datacolumns", force: :cascade do |t|
    t.integer  "datagroup_id"
    t.integer  "dataset_id"
    t.string   "columnheader"
    t.integer  "columnnr"
    t.text     "definition"
    t.string   "unit"
    t.text     "comment"
    t.string   "import_data_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "datagroup_approved",  default: false
    t.boolean  "finished",            default: false
    t.boolean  "datatype_approved",   default: false
    t.text     "informationsource"
    t.text     "instrumentation"
    t.string   "acknowledge_unknown"
    t.index ["datagroup_id"], name: "index_datacolumns_on_datagroup_id", using: :btree
    t.index ["dataset_id"], name: "index_datacolumns_on_dataset_id", using: :btree
  end

  create_table "datafiles", force: :cascade do |t|
    t.string   "file_file_name"
    t.string   "file_content_type"
    t.integer  "file_file_size"
    t.datetime "file_updated_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "dataset_id"
    t.index ["dataset_id"], name: "index_datafiles_on_dataset_id", using: :btree
  end

  create_table "datagroups", force: :cascade do |t|
    t.string   "title"
    t.text     "description"
    t.text     "comment"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "type_id",           default: 1
    t.integer  "datacolumns_count", default: 0
    t.index ["title"], name: "index_datagroups_on_title", using: :btree
    t.index ["type_id"], name: "index_datagroups_on_type_id", using: :btree
  end

  create_table "dataset_downloads", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "dataset_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["dataset_id", "user_id"], name: "index_dataset_downloads_on_dataset_id_and_user_id", using: :btree
    t.index ["dataset_id"], name: "index_dataset_downloads_on_dataset_id", using: :btree
    t.index ["user_id", "dataset_id"], name: "index_dataset_downloads_on_user_id_and_dataset_id", using: :btree
    t.index ["user_id"], name: "index_dataset_downloads_on_user_id", using: :btree
  end

  create_table "dataset_edits", force: :cascade do |t|
    t.integer  "dataset_id"
    t.text     "description"
    t.boolean  "submitted",   default: false
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.index ["dataset_id"], name: "index_dataset_edits_on_dataset_id", using: :btree
  end

  create_table "dataset_paperproposals", force: :cascade do |t|
    t.string   "aspect"
    t.integer  "paperproposal_id"
    t.integer  "dataset_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["dataset_id", "paperproposal_id"], name: "index_dataset_paperproposals_on_dataset_id_and_paperproposal_id", using: :btree
    t.index ["dataset_id"], name: "index_dataset_paperproposals_on_dataset_id", using: :btree
    t.index ["paperproposal_id"], name: "index_dataset_paperproposals_on_paperproposal_id", using: :btree
  end

  create_table "datasets", force: :cascade do |t|
    t.string   "title"
    t.text     "abstract"
    t.text     "usagerights"
    t.text     "spatialextent"
    t.text     "temporalextent"
    t.text     "taxonomicextent"
    t.text     "design"
    t.text     "circumstances"
    t.datetime "submission_at"
    t.string   "filename"
    t.text     "comment"
    t.text     "dataanalysis"
    t.integer  "dataset_downloads_count", default: 0
    t.datetime "datemin"
    t.datetime "datemax"
    t.text     "published"
    t.boolean  "visible_for_public",      default: true
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "import_status"
    t.integer  "access_code",             default: 0
    t.boolean  "include_license",         default: false
    t.integer  "datafiles_count",         default: 0
    t.integer  "freeformats_count",       default: 0
    t.integer  "project_phase"
  end

  create_table "datasets_projects", id: false, force: :cascade do |t|
    t.integer  "dataset_id"
    t.integer  "project_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["dataset_id", "project_id"], name: "index_dataset_projects_on_dataset_id_and_project_id", using: :btree
    t.index ["dataset_id"], name: "index_datasets_projects_on_dataset_id", using: :btree
  end

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer  "priority",   default: 0
    t.integer  "attempts",   default: 0
    t.text     "handler"
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "queue"
    t.index ["priority", "run_at"], name: "delayed_jobs_priority", using: :btree
  end

  create_table "exported_files", force: :cascade do |t|
    t.integer  "dataset_id"
    t.string   "status",         default: "new",                 null: false
    t.datetime "generated_at"
    t.datetime "invalidated_at", default: '1970-01-01 00:00:00'
    t.string   "file_file_name"
    t.integer  "file_file_size"
    t.string   "type"
    t.index ["dataset_id"], name: "index_exported_files_on_dataset_id", using: :btree
    t.index ["id", "type"], name: "index_exported_files_on_id_and_type", using: :btree
  end

  create_table "freeformats", force: :cascade do |t|
    t.string   "file_file_name"
    t.string   "file_content_type"
    t.integer  "file_file_size"
    t.datetime "file_updated_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "description"
    t.integer  "freeformattable_id"
    t.string   "freeformattable_type"
    t.boolean  "is_essential",         default: false
    t.string   "uri"
    t.index ["freeformattable_id", "freeformattable_type"], name: "freeformattable_index", using: :btree
    t.index ["freeformattable_type", "freeformattable_id"], name: "idx_freeformats_type_id", using: :btree
  end

  create_table "import_categories", force: :cascade do |t|
    t.integer  "datacolumn_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "short"
    t.string   "long"
    t.text     "description"
    t.index ["datacolumn_id"], name: "index_import_categories_on_datacolumn_id", using: :btree
    t.index ["long"], name: "index_import_categories_on_long", using: :btree
    t.index ["short"], name: "index_import_categories_on_short", using: :btree
  end

  create_table "notifications", force: :cascade do |t|
    t.integer  "user_id"
    t.text     "subject"
    t.text     "message"
    t.boolean  "read",       default: false
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.index ["user_id"], name: "index_notifications_on_user_id", using: :btree
  end

  create_table "paperproposal_votes", force: :cascade do |t|
    t.integer  "paperproposal_id"
    t.integer  "user_id"
    t.string   "comment"
    t.string   "vote",               default: "none"
    t.boolean  "project_board_vote"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["paperproposal_id"], name: "index_paperproposal_votes_on_paperproposal_id", using: :btree
    t.index ["user_id"], name: "index_paperproposal_votes_on_user_id", using: :btree
  end

  create_table "paperproposals", force: :cascade do |t|
    t.integer  "author_id"
    t.text     "envisaged_journal"
    t.string   "title"
    t.text     "rationale"
    t.date     "envisaged_date"
    t.string   "state"
    t.date     "expiry_date"
    t.string   "board_state",       default: "prep"
    t.string   "external_data"
    t.boolean  "lock",              default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "initial_title"
    t.text     "comment"
    t.integer  "project_id"
    t.integer  "freeformats_count", default: 0
    t.index ["author_id"], name: "index_paperproposals_on_author_id", using: :btree
    t.index ["project_id"], name: "index_paperproposals_on_project_id", using: :btree
  end

  create_table "projectphases", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "projects", force: :cascade do |t|
    t.string   "shortname"
    t.string   "name"
    t.text     "description"
    t.text     "comment"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "roles", force: :cascade do |t|
    t.string   "name",              limit: 40
    t.string   "authorizable_type", limit: 25
    t.integer  "authorizable_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["authorizable_id", "authorizable_type"], name: "index_roles_on_authorizable_id_and_authorizable_type", using: :btree
    t.index ["authorizable_type", "authorizable_id"], name: "index_roles_on_authorizable_type_and_authorizable_id", using: :btree
  end

  create_table "roles_users", id: false, force: :cascade do |t|
    t.integer "user_id"
    t.integer "role_id"
    t.index ["role_id", "user_id"], name: "index_roles_users_on_role_id_and_user_id", using: :btree
    t.index ["role_id"], name: "index_roles_users_on_role_id", using: :btree
    t.index ["user_id", "role_id"], name: "index_roles_users_on_user_id_and_role_id", using: :btree
    t.index ["user_id"], name: "index_roles_users_on_user_id", using: :btree
  end

  create_table "sheetcells", force: :cascade do |t|
    t.integer  "datacolumn_id"
    t.string   "import_value"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "category_id"
    t.string   "accepted_value"
    t.integer  "datatype_id"
    t.integer  "status_id",      default: 1
    t.integer  "row_number"
    t.index ["category_id"], name: "index_sheetcells_on_category_id", using: :btree
    t.index ["datacolumn_id"], name: "index_sheetcells_on_datacolumn_id", using: :btree
    t.index ["row_number"], name: "index_sheetcells_on_row_number", using: :btree
    t.index ["status_id", "datacolumn_id"], name: "index_sheetcells_on_status_id_and_datacolumn_id", using: :btree
  end

  create_table "taggings", force: :cascade do |t|
    t.integer  "tag_id"
    t.integer  "taggable_id"
    t.string   "taggable_type"
    t.integer  "tagger_id"
    t.string   "tagger_type"
    t.string   "context",       limit: 128
    t.datetime "created_at"
    t.index ["context"], name: "index_taggings_on_context", using: :btree
    t.index ["tag_id", "taggable_id", "taggable_type", "context", "tagger_id", "tagger_type"], name: "taggings_idx", unique: true, using: :btree
    t.index ["tag_id"], name: "index_taggings_on_tag_id", using: :btree
    t.index ["taggable_id", "taggable_type", "context"], name: "index_taggings_on_taggable_id_and_taggable_type_and_context", using: :btree
    t.index ["taggable_id", "taggable_type", "tagger_id", "context"], name: "taggings_idy", using: :btree
    t.index ["taggable_id"], name: "index_taggings_on_taggable_id", using: :btree
    t.index ["taggable_type"], name: "index_taggings_on_taggable_type", using: :btree
    t.index ["tagger_id", "tagger_type"], name: "index_taggings_on_tagger_id_and_tagger_type", using: :btree
    t.index ["tagger_id"], name: "index_taggings_on_tagger_id", using: :btree
  end

  create_table "tags", force: :cascade do |t|
    t.string  "name"
    t.integer "taggings_count", default: 0
    t.index ["name"], name: "index_tags_on_name", unique: true, using: :btree
  end

  create_table "users", force: :cascade do |t|
    t.string   "login",                               null: false
    t.string   "email",                               null: false
    t.string   "crypted_password",                    null: false
    t.string   "password_salt",                       null: false
    t.string   "persistence_token",                   null: false
    t.string   "single_access_token",                 null: false
    t.string   "perishable_token",                    null: false
    t.integer  "login_count",         default: 0,     null: false
    t.integer  "failed_login_count",  default: 0,     null: false
    t.datetime "last_request_at"
    t.datetime "current_login_at"
    t.datetime "last_login_at"
    t.string   "current_login_ip"
    t.string   "last_login_ip"
    t.string   "firstname"
    t.string   "middlenames"
    t.string   "lastname"
    t.string   "salutation"
    t.text     "comment"
    t.string   "url"
    t.string   "institution_name"
    t.text     "affiliation"
    t.string   "institution_url"
    t.string   "institution_phone"
    t.string   "institution_fax"
    t.string   "street"
    t.string   "city"
    t.string   "country"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "avatar_file_name"
    t.string   "avatar_content_type"
    t.integer  "avatar_file_size"
    t.boolean  "receive_emails",      default: false
    t.boolean  "alumni",              default: false
  end

end
