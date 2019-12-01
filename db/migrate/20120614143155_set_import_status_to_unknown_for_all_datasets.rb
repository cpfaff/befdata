# frozen_string_literal: true

class SetImportStatusToUnknownForAllDatasets < ActiveRecord::Migration
  def self.up
    Dataset.all.each do |dataset|
      dataset.update_attribute(:import_status, 'unknown')
    end
  end

  def self.down; end
end
