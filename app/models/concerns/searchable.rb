# app/models/concerns/searchable.rb
module Searchable
  extend ActiveSupport::Concern

  included do
    include PgSearch

    # search scope
    pg_search_scope :search, against: {
      name: 'A',
    },
    using: {
      tsearch: {
        dictionary: 'english',
        prefix: true
      }
    }
  end
end
