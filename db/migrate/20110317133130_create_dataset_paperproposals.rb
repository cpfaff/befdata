# frozen_string_literal: true

class CreateDatasetPaperproposals < ActiveRecord::Migration
  def self.up
    create_table :dataset_paperproposals, id: false do |t|
      t.integer  'id', null: false
      t.string   'aspect'
      t.integer  'paperproposal_id'
      t.integer  'dataset_id'
      t.timestamps
    end
  end

  def self.down
    drop_table :dataset_paperproposals
  end
end
