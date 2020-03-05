# frozen_string_literal: true

class DropVocabsTable < ActiveRecord::Migration[5.0]
  def up
    drop_table :vocabs
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
