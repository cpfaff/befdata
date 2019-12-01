# frozen_string_literal: true

class Notification < ActiveRecord::Base
  belongs_to :user

  validates_presence_of :user, :subject
end
