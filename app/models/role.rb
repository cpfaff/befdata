# frozen_string_literal: true

class Role < ApplicationRecord
  acts_as_authorization_role subject_class_name: 'User', join_table_name: 'roles_users'
  validates_uniqueness_of :name, scope: %i[authorizable_type authorizable_id]
end
