# frozen_string_literal: true

class RefactorIndexes < ActiveRecord::Migration
  def self.up
    # datacolumns
    remove_index :datacolumns, %i[datagroup_id dataset_id]
    add_index :datacolumns, [:dataset_id]

    # dataset
    add_index :datasets, [:filename]

    # freeformats
    add_index :freeformats, %i[freeformattable_type freeformattable_id], name: 'idx_freeformats_type_id'

    # paperproposals
    add_index :paperproposals, [:senior_author_id]
    add_index :paperproposals, [:project_id]

    # sheetcells
    remove_index :sheetcells, %i[category_id status_id datacolumn_id]
    add_index :sheetcells, [:row_number]
    add_index :sheetcells, [:category_id]
    add_index :sheetcells, %i[status_id datacolumn_id]

    # datagroups
    add_index :datagroups, [:title]

    # roles_users
    add_index :roles_users, %i[user_id role_id]

    # projects_roles
    add_index :projects_roles, %i[project_id role_id]

    # author_paperproposals
    add_index :author_paperproposals, [:paperproposal_id]
  end

  def self.down
    # datacolumns
    add_index :datacolumns, %i[datagroup_id dataset_id]
    remove_index :datacolumns, [:dataset_id]

    # dataset
    remove_index :datasets, [:filename]

    # freeformats
    remove_index :freeformats, %i[freeformattable_type freeformattable_id], name: 'idx_freeformats_type_id'

    # paperproposals
    remove_index :paperproposals, [:senior_author_id]
    remove_index :paperproposals, [:project_id]

    # sheetcells
    add_index :sheetcells, %i[category_id status_id datacolumn_id]
    remove_index :sheetcells, [:row_number]
    remove_index :sheetcells, [:category_id]
    remove_index :sheetcells, %i[status_id datacolumn_id]

    # datagroups
    remove_index :datagroups, [:title]

    # roles_users
    remove_index :roles_users, %i[user_id role_id]

    # projects_roles
    remove_index :projects_roles, %i[project_id role_id]

    # author_paperproposals
    remove_index :author_paperproposals, [:paperproposal_id]
  end
end
