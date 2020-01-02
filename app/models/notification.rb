# frozen_string_literal: true

class Notification < ApplicationRecord
  belongs_to :user

  validates_presence_of :user, :subject
end
