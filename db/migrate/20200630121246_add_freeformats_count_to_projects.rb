class AddFreeformatsCountToProjects < ActiveRecord::Migration[5.0]
  def change
    add_column :projects, :freeformats_count, :integer
  end
end
