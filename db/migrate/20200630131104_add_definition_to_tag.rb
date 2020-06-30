class AddDefinitionToTag < ActiveRecord::Migration[5.0]
  def change
    add_column :tags, :definition, :text
  end
end
