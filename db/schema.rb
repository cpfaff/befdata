# frozen_string_literal: true

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

ActiveRecord::Schema.define(version: 20_191_107_172_743) do
  # These are extensions that must be enabled in order to support this database
  enable_extension 'plpgsql'

  create_table 'author_paperproposals', force: :cascade do |t|
    t.integer  'paperproposal_id'
    t.integer  'user_id'
    t.string   'kind'
    t.datetime 'created_at'
    t.datetime 'updated_at'
  end

  add_index 'author_paperproposals', ['paperproposal_id'], name: 'index_author_paperproposals_on_paperproposal_id', using: :btree
  add_index 'author_paperproposals', %w[user_id paperproposal_id], name: 'index_author_paperproposals_on_user_id_and_paperproposal_id', using: :btree

  create_table 'cart_datasets', force: :cascade do |t|
    t.integer  'cart_id'
    t.integer  'dataset_id'
    t.datetime 'created_at'
    t.datetime 'updated_at'
  end

  add_index 'cart_datasets', ['cart_id'], name: 'index_cart_datasets_on_cart_id', using: :btree
  add_index 'cart_datasets', ['dataset_id'], name: 'index_cart_datasets_on_dataset_id', using: :btree

  create_table 'carts', force: :cascade do |t|
    t.datetime 'created_at'
    t.datetime 'updated_at'
  end

  create_table 'categories', force: :cascade do |t|
    t.string   'short'
    t.string   'long'
    t.text     'description'
    t.text     'comment'
    t.datetime 'created_at'
    t.datetime 'updated_at'
    t.integer  'datagroup_id'
  end

  add_index 'categories', ['datagroup_id'], name: 'index_categories_on_datagroup_id', using: :btree
  add_index 'categories', ['long'], name: 'index_categories_on_long', using: :btree
  add_index 'categories', ['short'], name: 'index_categoricvalues_on_short', using: :btree

  create_table 'datacolumns', force: :cascade do |t|
    t.integer  'datagroup_id'
    t.integer  'dataset_id'
    t.string   'columnheader'
    t.integer  'columnnr'
    t.text     'definition'
    t.string   'unit'
    t.text     'comment'
    t.string   'import_data_type'
    t.datetime 'created_at'
    t.datetime 'updated_at'
    t.boolean  'datagroup_approved',  default: false
    t.boolean  'finished',            default: false
    t.boolean  'datatype_approved',   default: false
    t.text     'informationsource'
    t.text     'instrumentation'
    t.string   'acknowledge_unknown'
    t.integer  'term_id'
  end

  add_index 'datacolumns', ['datagroup_id'], name: 'index_datacolumns_on_datagroup_id', using: :btree
  add_index 'datacolumns', ['dataset_id'], name: 'index_datacolumns_on_dataset_id', using: :btree

  create_table 'datafiles', force: :cascade do |t|
    t.string   'file_file_name'
    t.string   'file_content_type'
    t.integer  'file_file_size'
    t.datetime 'file_updated_at'
    t.datetime 'created_at'
    t.datetime 'updated_at'
    t.integer  'dataset_id'
  end

  add_index 'datafiles', ['dataset_id'], name: 'index_datafiles_on_dataset_id', using: :btree

  create_table 'datagroups', force: :cascade do |t|
    t.string   'title'
    t.text     'description'
    t.text     'comment'
    t.datetime 'created_at'
    t.datetime 'updated_at'
    t.integer  'type_id',           default: 1
    t.integer  'datacolumns_count', default: 0
  end

  add_index 'datagroups', ['title'], name: 'index_datagroups_on_title', using: :btree
  add_index 'datagroups', ['type_id'], name: 'index_datagroups_on_type_id', using: :btree

  create_table 'dataset_downloads', force: :cascade do |t|
    t.integer  'user_id'
    t.integer  'dataset_id'
    t.datetime 'created_at'
    t.datetime 'updated_at'
  end

  add_index 'dataset_downloads', %w[user_id dataset_id], name: 'index_dataset_downloads_on_user_id_and_dataset_id', using: :btree

  create_table 'dataset_edits', force: :cascade do |t|
    t.integer  'dataset_id'
    t.text     'description'
    t.boolean  'submitted', default: false
    t.datetime 'created_at',                  null: false
    t.datetime 'updated_at',                  null: false
  end

  add_index 'dataset_edits', ['dataset_id'], name: 'index_dataset_edits_on_dataset_id', using: :btree

  create_table 'dataset_paperproposals', force: :cascade do |t|
    t.string   'aspect'
    t.integer  'paperproposal_id'
    t.integer  'dataset_id'
    t.datetime 'created_at'
    t.datetime 'updated_at'
  end

  add_index 'dataset_paperproposals', %w[dataset_id paperproposal_id], name: 'index_dataset_paperproposals_on_dataset_id_and_paperproposal_id', using: :btree

  create_table 'datasets', force: :cascade do |t|
    t.string   'title'
    t.text     'abstract'
    t.text     'usagerights'
    t.text     'spatialextent'
    t.text     'temporalextent'
    t.text     'taxonomicextent'
    t.text     'design'
    t.text     'circumstances'
    t.datetime 'submission_at'
    t.string   'filename'
    t.text     'comment'
    t.text     'dataanalysis'
    t.integer  'dataset_downloads_count', default: 0
    t.datetime 'datemin'
    t.datetime 'datemax'
    t.text     'published'
    t.boolean  'visible_for_public', default: true
    t.datetime 'created_at'
    t.datetime 'updated_at'
    t.string   'import_status'
    t.integer  'access_code',             default: 0
    t.boolean  'include_license',         default: false
    t.integer  'datafiles_count',         default: 0
    t.integer  'freeformats_count',       default: 0
  end

  create_table 'datasets_projects', id: false, force: :cascade do |t|
    t.integer  'dataset_id'
    t.integer  'project_id'
    t.datetime 'created_at'
    t.datetime 'updated_at'
  end

  add_index 'datasets_projects', %w[dataset_id project_id], name: 'index_dataset_projects_on_dataset_id_and_project_id', using: :btree

  create_table 'delayed_jobs', force: :cascade do |t|
    t.integer  'priority',   default: 0
    t.integer  'attempts',   default: 0
    t.text     'handler'
    t.text     'last_error'
    t.datetime 'run_at'
    t.datetime 'locked_at'
    t.datetime 'failed_at'
    t.string   'locked_by'
    t.datetime 'created_at'
    t.datetime 'updated_at'
    t.string   'queue'
  end

  add_index 'delayed_jobs', %w[priority run_at], name: 'delayed_jobs_priority', using: :btree

  create_table 'exported_files', force: :cascade do |t|
    t.integer  'dataset_id'
    t.string   'status', default: 'new', null: false
    t.datetime 'generated_at'
    t.datetime 'invalidated_at', default: '1970-01-01 00:00:00'
    t.string   'file_file_name'
    t.integer  'file_file_size'
    t.string   'type'
  end

  add_index 'exported_files', ['dataset_id'], name: 'index_exported_files_on_dataset_id', using: :btree

  create_table 'freeformats', force: :cascade do |t|
    t.string   'file_file_name'
    t.string   'file_content_type'
    t.integer  'file_file_size'
    t.datetime 'file_updated_at'
    t.datetime 'created_at'
    t.datetime 'updated_at'
    t.text     'description'
    t.integer  'freeformattable_id'
    t.string   'freeformattable_type'
    t.boolean  'is_essential', default: false
    t.string   'uri'
  end

  add_index 'freeformats', %w[freeformattable_type freeformattable_id], name: 'idx_freeformats_type_id', using: :btree

  create_table 'import_categories', force: :cascade do |t|
    t.integer  'datacolumn_id'
    t.datetime 'created_at'
    t.datetime 'updated_at'
    t.string   'short'
    t.string   'long'
    t.text     'description'
  end

  add_index 'import_categories', ['datacolumn_id'], name: 'index_import_categories_on_datacolumn_id', using: :btree
  add_index 'import_categories', ['long'], name: 'index_import_categories_on_long', using: :btree
  add_index 'import_categories', ['short'], name: 'index_import_categories_on_short', using: :btree

  create_table 'notifications', force: :cascade do |t|
    t.integer  'user_id'
    t.text     'subject'
    t.text     'message'
    t.boolean  'read', default: false
    t.datetime 'created_at',                 null: false
    t.datetime 'updated_at',                 null: false
  end

  create_table 'paperproposal_votes', force: :cascade do |t|
    t.integer  'paperproposal_id'
    t.integer  'user_id'
    t.string   'comment'
    t.string   'vote', default: 'none'
    t.boolean  'project_board_vote'
    t.datetime 'created_at'
    t.datetime 'updated_at'
  end

  add_index 'paperproposal_votes', ['paperproposal_id'], name: 'index_paperproposal_votes_on_paperproposal_id', using: :btree
  add_index 'paperproposal_votes', ['user_id'], name: 'index_paperproposal_votes_on_user_id', using: :btree

  create_table 'paperproposals', force: :cascade do |t|
    t.integer  'author_id'
    t.text     'envisaged_journal'
    t.string   'title'
    t.text     'rationale'
    t.date     'envisaged_date'
    t.string   'state'
    t.date     'expiry_date'
    t.string   'board_state', default: 'prep'
    t.string   'external_data'
    t.boolean  'lock', default: false
    t.datetime 'created_at'
    t.datetime 'updated_at'
    t.string   'initial_title'
    t.text     'comment'
    t.integer  'project_id'
    t.integer  'freeformats_count', default: 0
  end

  add_index 'paperproposals', ['author_id'], name: 'index_paperproposals_on_author_id', using: :btree
  add_index 'paperproposals', ['project_id'], name: 'index_paperproposals_on_project_id', using: :btree

  create_table 'projects', force: :cascade do |t|
    t.string   'shortname'
    t.string   'name'
    t.text     'description'
    t.text     'comment'
    t.datetime 'created_at'
    t.datetime 'updated_at'
  end

  create_table 'roles', force: :cascade do |t|
    t.string   'name',              limit: 40
    t.string   'authorizable_type', limit: 25
    t.integer  'authorizable_id'
    t.datetime 'created_at'
    t.datetime 'updated_at'
  end

  add_index 'roles', %w[authorizable_type authorizable_id], name: 'index_roles_on_authorizable_type_and_authorizable_id', using: :btree

  create_table 'roles_users', id: false, force: :cascade do |t|
    t.integer 'user_id'
    t.integer 'role_id'
  end

  add_index 'roles_users', %w[user_id role_id], name: 'index_roles_users_on_user_id_and_role_id', using: :btree

  create_table 'sheetcells', force: :cascade do |t|
    t.integer  'datacolumn_id'
    t.string   'import_value'
    t.datetime 'created_at'
    t.datetime 'updated_at'
    t.integer  'category_id'
    t.string   'accepted_value'
    t.integer  'datatype_id'
    t.integer  'status_id', default: 1
    t.integer  'row_number'
  end

  add_index 'sheetcells', ['category_id'], name: 'index_sheetcells_on_category_id', using: :btree
  add_index 'sheetcells', ['datacolumn_id'], name: 'index_sheetcells_on_datacolumn_id', using: :btree
  add_index 'sheetcells', ['row_number'], name: 'index_sheetcells_on_row_number', using: :btree
  add_index 'sheetcells', %w[status_id datacolumn_id], name: 'index_sheetcells_on_status_id_and_datacolumn_id', using: :btree

  create_table 'taggings', force: :cascade do |t|
    t.integer  'tag_id'
    t.integer  'taggable_id'
    t.string   'taggable_type'
    t.integer  'tagger_id'
    t.string   'tagger_type'
    t.string   'context', limit: 128
    t.datetime 'created_at'
  end

  add_index 'taggings', ['context'], name: 'index_taggings_on_context', using: :btree
  add_index 'taggings', %w[tag_id taggable_id taggable_type context tagger_id tagger_type], name: 'taggings_idx', unique: true, using: :btree
  add_index 'taggings', ['tag_id'], name: 'index_taggings_on_tag_id', using: :btree
  add_index 'taggings', %w[taggable_id taggable_type context], name: 'index_taggings_on_taggable_id_and_taggable_type_and_context', using: :btree
  add_index 'taggings', %w[taggable_id taggable_type tagger_id context], name: 'taggings_idy', using: :btree
  add_index 'taggings', ['taggable_id'], name: 'index_taggings_on_taggable_id', using: :btree
  add_index 'taggings', ['taggable_type'], name: 'index_taggings_on_taggable_type', using: :btree
  add_index 'taggings', %w[tagger_id tagger_type], name: 'index_taggings_on_tagger_id_and_tagger_type', using: :btree
  add_index 'taggings', ['tagger_id'], name: 'index_taggings_on_tagger_id', using: :btree

  create_table 'tags', force: :cascade do |t|
    t.string  'name'
    t.integer 'taggings_count', default: 0
  end

  add_index 'tags', ['name'], name: 'index_tags_on_name', unique: true, using: :btree

  create_table 'users', force: :cascade do |t|
    t.string   'login',                               null: false
    t.string   'email',                               null: false
    t.string   'crypted_password',                    null: false
    t.string   'password_salt',                       null: false
    t.string   'persistence_token',                   null: false
    t.string   'single_access_token',                 null: false
    t.string   'perishable_token',                    null: false
    t.integer  'login_count',         default: 0,     null: false
    t.integer  'failed_login_count',  default: 0,     null: false
    t.datetime 'last_request_at'
    t.datetime 'current_login_at'
    t.datetime 'last_login_at'
    t.string   'current_login_ip'
    t.string   'last_login_ip'
    t.string   'firstname'
    t.string   'middlenames'
    t.string   'lastname'
    t.string   'salutation'
    t.text     'comment'
    t.string   'url'
    t.string   'institution_name'
    t.text     'affiliation'
    t.string   'institution_url'
    t.string   'institution_phone'
    t.string   'institution_fax'
    t.string   'street'
    t.string   'city'
    t.string   'country'
    t.datetime 'created_at'
    t.datetime 'updated_at'
    t.string   'avatar_file_name'
    t.string   'avatar_content_type'
    t.integer  'avatar_file_size'
    t.boolean  'receive_emails',      default: false
    t.boolean  'alumni',              default: false
  end

  create_table 'vocabs', force: :cascade do |t|
    t.string   'term'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
  end
end
