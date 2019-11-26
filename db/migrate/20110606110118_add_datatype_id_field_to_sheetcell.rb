require 'active_record/fixtures'

class AddDatatypeIdFieldToSheetcell < ActiveRecord::Migration
  def self.up
    add_column :sheetcells, :datatype_id, :integer
  end

  def self.down
    remove_column :sheetcells, :datatype_id

    Datatype.delete_all
  end
end
