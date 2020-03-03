class RemoveTermIdFromDatacolumns < ActiveRecord::Migration[5.0]
  def change
    remove_index :datacolumns, :term_id
    remove_column :datacolumns, :term_id, :integer
  end
end
