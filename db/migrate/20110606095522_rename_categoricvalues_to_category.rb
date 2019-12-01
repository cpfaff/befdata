# frozen_string_literal: true

class RenameCategoricvaluesToCategory < ActiveRecord::Migration
  def self.up
    rename_table :categoricvalues, :categories
  end

  def self.down
    rename_table :categories, :categoricvalues
  end
end
