# frozen_string_literal: true

class AddMissingIndexes < ActiveRecord::Migration
  def change
    add_index :author_paperproposals, :user_id
    add_index :author_paperproposals, %i[paperproposal_id user_id]
    add_index :datacolumns, :term_id
    add_index :dataset_downloads, :dataset_id
    add_index :dataset_downloads, :user_id
    add_index :dataset_downloads, %i[dataset_id user_id]
    add_index :dataset_paperproposals, :dataset_id
    add_index :dataset_paperproposals, :paperproposal_id
    add_index :datasets_projects, :dataset_id
    add_index :exported_files, %i[id type]
    add_index :freeformats, %i[freeformattable_id freeformattable_type], name: 'freeformattable_index'
    add_index :notifications, :user_id
    add_index :roles, %i[authorizable_id authorizable_type]
    add_index :roles_users, :role_id
    add_index :roles_users, :user_id
    add_index :roles_users, %i[role_id user_id]
  end
    end
