class AddProjectPhaseToDatasets < ActiveRecord::Migration
  def change
    add_column :datasets, :project_phase, :integer
  end
end
