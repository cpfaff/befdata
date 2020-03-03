# frozen_string_literal: true

# This file contains the Dataset model, which maps the database table Datasets for the application.
# The Dataset title must be unique.

# Datasets contain the general metadata of a dataset. In addition, a dataset can contain:
# 1. Primary research data, as uploaded data values from a Workbook or CSV
#    where the information on the column is stored in Datacolumn instances
#    and the data values in Sheetcell instances. The original Workbook is stored as a Datafile
# 2. one or more asset (Freeformat) files.
#
# Datasets are taggable, that is, they can be linked to entries in the Tags table. This uses the Acts_as_taggable
# rails gem.
#
# Dataset provenance is managed using the ACL9 rails gem. Users can be given different roles in relation
# to a dataset (see User) and access to the dataset is controlled via the Role.
#
# Datasets can belong to one or more Project instances. They can also set free for download within their
# projects.
#
# Paperproposal instances contain one or more datasets. They are linked through
# the DatasetPaperproposal class.
#
# Highlighted methods:
# * approve_predefined_columns : after the initial upload of data a User can bulk approve columns,
#   without reviewing each column individually. The Datacolumn must be correctly described, in
#   that it must have a Datagroup and a Datatype.

require 'acl_patch'
class Dataset < ApplicationRecord
  # access control
  acts_as_authorization_object subject_class_name: 'User',
                               join_table_name: 'roles_users'
  include AclPatch

  attr_writer :owner_ids
  acts_as_taggable

  has_many :datafiles,
    -> { order 'id DESC' },
    dependent: :destroy,
    class_name: 'Datafile'

  has_one :current_datafile,
    -> { order 'id DESC' },
    class_name: 'Datafile'

  has_many :exported_files,
    dependent: :destroy

  # exported excel workbook
  has_one :exported_excel

  # exported regular csv
  has_one :exported_csv

  # exported csv with separate coategory columns
  has_one :exported_scc_csv

  has_many :datacolumns,
    -> { order 'columnnr' },
    dependent: :destroy

  has_many :sheetcells,
    through: :datacolumns

  has_many :datagroups,
    -> { includes :categories },
    through: :datacolumns

  has_many :freeformats,
    as: :freeformattable,
    dependent: :destroy

  has_many :dataset_downloads

  has_many :downloaders,
           -> { distinct },
           through: :dataset_downloads,
           source: :user

  has_many :dataset_edits,
           -> { order 'updated_at DESC' },
           dependent: :destroy

  has_one :unsubmitted_edit,
          -> { where submitted: false },
          class_name: 'DatasetEdit'

  has_and_belongs_to_many :projects

  has_many :dataset_paperproposals

  has_many :paperproposals,
           through: :dataset_paperproposals

  has_many :proposers,
    -> { distinct },
    through: :paperproposals,
    source: :author

  has_many :dataset_tags
  has_many :all_tags,
           -> { order 'lower(name)' },
           through: :dataset_tags,
           source: :tag

  # constants
  # TODO: These constants need to be transformed into enumerables
  ACCESS_CODES = {
    private: 0,
    free_within_projects: 1,
    free_for_members: 2,
    free_for_public: 3
  }.freeze

  PROJECT_PHASE = PHASE_CONFIG.freeze

  # validations
  validates :title,
            presence: true,
            uniqueness: { case_sensitive: false }

  validates_inclusion_of :access_code,
                         in: ACCESS_CODES.values,
                         message: 'is invalid! Access Rights is out of Range.'

  # hooks
  before_destroy :check_for_paperproposals
  before_save :set_include_license,
              :check_author,
              :set_default_phase

  # includes
  include PgSearch

  pg_search_scope :search, against: {
    title: 'A',
    abstract: 'B',
    design: 'C',
    spatialextent: 'C',
    temporalextent: 'C',
    taxonomicextent: 'C',
    circumstances: 'C',
    dataanalysis: 'C'
  }, associated_against: {
    tags: { name: 'A' }
  }, using: {
    tsearch: {
      dictionary: 'english',
      prefix: true
    }
  }

  def load_projects_and_authors_from_current_datafile
    return unless current_datafile

    current_datafile.authors_list[:found_users].each { |user| user.has_role!(:owner, self) }
    self.projects = current_datafile.projects_list if current_datafile.projects_list.present?
  end

  def add_datafile(datafile)
    datafile.update_attributes(dataset: self)
    update_attributes(filename: datafile.basename, import_status: 'new')
  end

  def has_research_data?
    datafiles_count && datafiles_count > 0
  end

  def access_rights
    ACCESS_CODES.invert[access_code].to_s.humanize
  end

  %w[free_within_projects free_for_members free_for_public].each do |right|
    define_method("#{right}?") do
      access_code >= ACCESS_CODES[right.to_sym]
    end
  end

  def project_phases
    PROJECT_PHASE.invert[project_phase].to_s.humanize
  end

  %w[from_befchina from_treedi].each do |phase|
    define_method("#{phase}?") do
      access_code >= ACCESS_CODES[phase.to_sym]
    end
  end

  def abstract_with_freeformats
    f_strings = freeformats.collect do |f|
      'File asset ' + f.file_file_name + (f.description.blank? ? '' : (': ' + f.description))
    end
    abstract.to_s + (f_strings.empty? ? '' : (' - ' + f_strings.join(' - ')))
  end

  def cells_linked_to_values?
    sheetcells.exists?(["accepted_value IS NOT NULL OR accepted_value !='' OR category_id > 0"])
  end

  def headers
    datacolumns.pluck(:columnheader)
  end

  def predefined_columns
    datacolumns.select(&:predefined?)
  end

  def approve_predefined_columns
    @columns_with_invalid_values = []
    predefined_columns.each do |column|
      column.datagroup_approved = true

      # Approve the datatype and store the values
      column.add_data_values
      column.datatype_approved = true

      # Check for invalid values
      column.finished = true unless column.has_invalid_values?
      @columns_with_invalid_values << column if column.has_invalid_values?

      # Save the column
      column.save
    end
  end

  def columns_with_invalid_values_after_approving_predefined
    # TODO: this should be a proper method without relying on the state of this object
    raise "This method may be only called directly after executing 'approve_predefined_columns'" unless @columns_with_invalid_values

    @columns_with_invalid_values
  end

  def delete_imported_research_data
    datacolumns.destroy_all
    exported_files.destroy_all
  end

  def log_download(downloading_user)
    DatasetDownload.create(user: downloading_user, dataset: self)
  end

  def number_of_observations
    # TODO: use sql query finding max rownumber
    return 0 if datacolumns.empty?

    datacolumns.first.sheetcells.count
  end

  def import_data
    update_attribute(:import_status, 'started importing')
    current_datafile.import_data
    update_attribute(:import_status, 'finished')
    ExportedFile.initialize_export(self)
  rescue Exception => e
    Rails.logger.error e.message
    Rails.logger.error e.backtrace.join("\n")
    update_attribute(:import_status, "error: #{e.message.first(248)}")
  end

  def finished_import?
    import_status.to_s == 'finished' || !has_research_data?
  end

  def being_imported? # TODO: this is prone to be out of sync if new status added
    return false unless has_research_data?

    %w[new finished].exclude?(import_status) && !import_status.start_with?('error')
  end

  def refresh_paperproposal_authors
    paperproposals.each(&:update_datasets_providers)
  end

  # This method returns similar datasets which share keywords with current dataset.
  # datasets are sorted by similarity in descending order
  def find_related_datasets
    tags = all_tags.pluck(:id)
    return [] if tags.empty?

    datasets = Dataset.joins(:dataset_tags)
                      .select('datasets.*')
                      .where(['tag_id in (?) and datasets.id <> ?', tags, id])
                      .group('datasets.id').order('count(tag_id) desc')
    datasets
  end

  # acl9 role related staff: different kinds of user
  def owners
    get_user_with_role(:owner)
  end

  def owner_ids
    owners.map(&:id)
  end

  def owners=(people)
    set_user_with_role(:owner, people)
  end

  # keep log of edits
  def create_or_use_unsubmitted_edit
    if !unsubmitted_edit.nil?
      unsubmitted_edit
    else
      dataset_edits.new
    end
  end

  def log_edit(string)
    create_or_use_unsubmitted_edit.add_line!(string) unless unsubmitted_edit.nil? && (Time.now - 10.minutes) < created_at
  end

  def free_for?(user)
    return true if free_for_public?
    return false unless user
    return true if free_for_members?
    return true if free_within_projects? && !(user.projects & projects).empty?

    false
  end

  def can_be_downloaded_by?(user)
    return false unless current_datafile
    return true if free_for?(user)
    return false unless user
    return true if user.has_role?(:proposer, self) || user.has_role?(:owner, self)
    return true if user.has_role?(:admin) || user.has_role?(:data_admin)

    false
  end

  def can_be_edited_by?(user)
    return false unless user
    return true if user.has_role?(:owner, self) || user.has_role?(:admin) || user.has_role?(:data_admin)

    false
  end

  private

  def check_for_paperproposals
    if paperproposals.count > 0
      errors.add(:dataset,
                 "can not be deleted while linked paperproposals exist [ids: #{paperproposals.map(&:id).join(', ')}]")
      throw :abort
    end
  end

  def set_include_license
    self.include_license = false unless free_for_public?
    true
  end

  def check_author
    if @owner_ids
      @owner_ids.reject!(&:blank?)
      if @owner_ids.empty?
        errors.add :base, 'The dataset should have at least one author.'
        throw :abort
      else
        self.owners = User.find(@owner_ids)
      end
    end
  end

  def set_default_phase
    self.project_phase = '1' if project_phase.nil?
  end
end
