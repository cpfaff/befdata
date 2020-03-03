# frozen_string_literal: true

## The Datacolumn class models the Datacolumn table.
##
## A Datacolumn manages all the observations for a particular measurement which are stored in the the "Sheetcell" table.
##
## There are two particularly important methods on the Datacolumn class:
## 1. "add_data_values" validates the imported data value (import_value column in the "Sheetcell" table)
## and saves the validated value to the accepted_value column of the "Sheetcell" table in the case on non-"Category" "Datatype"s.
## If the data is of type "Category" then the validated "Category" Id is saved the in the CategoryId column of the "Sheetcell" table.
## Any unvalidated "Sheetcell" values are flagged as INVALID in the StatusId column of the "Sheetcell" table and their original uploaded
## data value remains in the import_value column "Sheetcell" table.
##
## 2. "update_invalid_value" creates a "Category" instance for the invalid value and assigns the "Category" to all "Sheetcell" instances
## that have the same invalid value in the "DataColumn". Regardless of the "Datatype" a "Category" is created for each invalid value and the
## "Datatype" of the "Sheetcell" updated to "Category". This results in Datacolumns consisting of more than one "Datatype".

require 'acl_patch'
class Datacolumn < ApplicationRecord
  include PgSearch
  acts_as_authorization_object subject_class_name: 'User', join_table_name: 'roles_users'
  include AclPatch

  acts_as_taggable

  belongs_to :datagroup, counter_cache: true
  has_many :categories, through: :datagroup
  belongs_to :dataset, touch: true

  has_many :sheetcells, dependent: :delete_all
  has_many :exported_sheetcells
  has_many :import_categories, dependent: :delete_all

  validates_presence_of :dataset_id, :columnheader, :columnnr, :definition
  validates_uniqueness_of :columnheader, :columnnr, scope: :dataset_id, case_sensitive: false

  pg_search_scope :search, against: {
    columnheader: 'A',
    definition: 'B'
  }, associated_against: {
    tags: { name: 'A' },
    datagroup: { title: 'A', description: 'B' }
  }, using: {
    tsearch: {
      dictionary: 'english',
      prefix: true
    }
  }

  before_validation :fill_missing_definition
  def fill_missing_definition
    self.definition = columnheader if definition.blank?
  end

  # Are there data values associated to the measurements of this data column instance?
  def values_stored?
    sheetcells.exists?(status_id: [2, 3, 4])
  end

  def predefined?
    # To be predefined, a column must have datatype that is not 'unknown'.
    return false if Datatypehelper.find_by_name(import_data_type).name == 'unknown'

    # To be predefined, a column must belongs to a datagroup
    # Furthermore, the datacolumn approval process must not have already started.
    datagroup_id && untouched?
  end

  # override the datagroup method.
  # when datagroup is not assigned, used NullDatagroup instead.
  alias fetch_datagroup_via_datagroup_id datagroup
  private :fetch_datagroup_via_datagroup_id
  def datagroup
    fetch_datagroup_via_datagroup_id || NullDatagroup.new
  end

  # returns the first 'count' number unique imported values
  def imported_values(_count)
    values = sheetcells.order('import_value').limit(2).group('import_value').select('import_value').to_a
    values
  end

  # returns the first 'count' number unique accepted values
  def accepted_values(count)
    sheetcells.select('case when category_id >0 then (select short from categories where id = sheetcells.category_id) else accepted_value end AS accepted_value')
              .where(status_id: [2, 3, 4])
              .limit(count).distinct.order('accepted_value')
  end

  # saves the accepted values for each "Sheetcell" in the column
  # first looking for a match in existing categories
  # then looking for a match in categories from the "Workbook"
  # if there are no "Category" matches then the import value is used as the accepted value
  # NB: all of the business logic is in functions within the database
  # found in db/non_schema_sql.sql
  def add_data_values
    # remove any previous accepted values so that we can keep a track of what has been updated
    sqlclean = "select clear_datacolumn_accepted_values(#{id})"

    datatype = Datatypehelper.find_by_name(import_data_type)

    # I would like to change this so that the SQL is in one function but it wasn't working
    # TODO: I will look at this again - SR
    if datatype.name == 'text'
      sql = "select accept_text_datacolumn_values(#{id})"
    else
      dataset = Dataset.find(dataset_id)
      comment = ''
      comment = dataset.title unless dataset.nil?
      sql = "select accept_datacolumn_values(#{datatype.id}, #{id}, #{datagroup_id}, '#{comment}')"
    end

    begin
      connection = ActiveRecord::Base.connection()
      connection.begin_db_transaction
      connection.execute(sqlclean)
      connection.execute(sql)

      connection.commit_db_transaction
    rescue StandardError
      connection.rollback_db_transaction
      raise
    end
  end

  def approve_datagroup(datagroup)
    self.datagroup = datagroup
    self.datagroup_approved = true
    self.datatype_approved = false
    self.finished = false
    save
  end

  def approve_datatype(datatype, _user)
    # selecting a datatype means that the imported values can validated against the datatype.
    self.import_data_type = datatype
    add_data_values

    self.datatype_approved = true
    self.finished = false
    save
  end

  def has_invalid_values?
    sheetcells.where(status_id: Sheetcellstatus::INVALID).exists?
  end

  # returns the unique invalid uploaded sheetcells
  def invalid_values
    sheetcells.select(:import_value).where(status_id: Sheetcellstatus::INVALID).order(:import_value).distinct
  end

  # returns any invalid sheetcells with the given value
  def invalid_sheetcells_by_value(value)
    sheetcells.where(status_id: Sheetcellstatus::INVALID, import_value: value)
  end

  # creates a category for the invalid value and assigns the category to all matching sheetcells
  def update_invalid_value(original_value, short, long, description, dataset)
    # firstly check that the category doesn't already exist in the datagroup
    cat = datagroup.categories.where(short: short).first_or_create do |c|
      c.long = long
      c.description = description
      c.datagroup = datagroup
      c.comment = dataset.title
    end

    # update all invalid sheetcells with the same original value with the new category id
    if cat.valid?
      invalid_sheetcells_by_value(original_value).update_all(
        category_id: cat.id,
        status_id: Sheetcellstatus::VALID,
        accepted_value: nil,
        datatype_id: Datatypehelper.find_by_name('category').id
      )
    end
    self.finished = false
  end

  def batch_approve_invalid_values(_user)
    sql = "select accept_invalid_values(#{id}, #{datagroup_id}, '#{dataset.title}')"
    connection = ActiveRecord::Base.connection()
    connection.execute(sql)
  end

  # this should not be happen but we thought it might be a good last step before we can
  # confirm the dataset as completely approved
  def final_check_for_valid_sheetcells
    if has_invalid_values?
      self.finished = false
      save
      return false
    end

    self.finished = true
    save
    true
  end

  def to_label
    columnheader
  end

  def approval_stage
    stage = 0
    stage = 1 if datagroup_approved
    stage = 2 if datagroup_approved && datatype_approved
    stage = 3 if datagroup_approved && datatype_approved && !has_invalid_values?
    stage = 4 if datagroup_approved && datatype_approved && !has_invalid_values? && finished
    stage
  end

  def untouched?
    approval_stage == 0 && !finished?
  end

  def split_me?
    # This method returns true for a column when it requires splitting.
    return false unless datagroup_approved && datatype_approved
    return false if %w[category text].include? import_data_type

    sheetcells.where('category_id is not null').exists?
  end

  # users of a datacolumn are those who are responsible for it
  def users=(people)
    set_user_with_role(:responsible, people)
  end
end
