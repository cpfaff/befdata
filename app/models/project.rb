# frozen_string_literal: true

# A project is actually a sub-project of the whole BEF project.
require 'acl_patch'
class Project < ApplicationRecord
  acts_as_authorization_object subject_class_name: 'User', join_table_name: 'roles_users'
  include AclPatch

  has_and_belongs_to_many :datasets
  has_many :authored_paperproposals, class_name: 'Paperproposal', foreign_key: :project_id

  validates_presence_of :shortname, :name
  validates_uniqueness_of :shortname, :name

  before_destroy :check_destroyable

  # includes
  include PgSearch

  # search scope
  pg_search_scope :search, against: {
    shortname: 'A',
    name: 'A',
    description: 'B'
  },
  using: {
    tsearch: {
      dictionary: 'english',
      prefix: true
    }
  }

  def to_s
    name.to_s
  end
  alias to_label to_s

  def to_tag
    Project.create_tag shortname
  end

  def self.find_by_converting_to_tag(project_tag)
    project_tag = Project.create_tag project_tag
    Project.all.detect { |p| p.to_tag == project_tag }
  end

  def self.create_tag(string)
    # "P1 Europe productivity" becomes "p1e"
    # downcase, erase non-numbers and non-letters, cut after first letter behind possible numbers
    string.downcase.scan(/\w/).join.slice(/^\D+\d*\D/)
  end

  def pi
    get_user_with_role(:pi)
  end

  def destroyable?
    (datasets.count + users.count + authored_paperproposals.count) == 0
  end

  private

  def check_destroyable
    unless destroyable?
      errors.add(:base, "#{shortname} still is linked to some resources like datasets, users, and proposals. Thus it can not be deleted!")
      false
    end
  end
end
