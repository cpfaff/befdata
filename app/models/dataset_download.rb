# frozen_string_literal: true

class DatasetDownload < ApplicationRecord
  belongs_to :user
  belongs_to :dataset, counter_cache: true
end
