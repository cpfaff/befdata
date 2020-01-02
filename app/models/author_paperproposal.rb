# frozen_string_literal: true

class AuthorPaperproposal < ApplicationRecord
  belongs_to :user
  belongs_to :paperproposal

  validates_uniqueness_of :user_id, scope: %i[paperproposal_id kind]
end
