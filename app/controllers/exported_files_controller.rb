# frozen_string_literal: true

class ExportedFilesController < ApplicationController
  before_action :load_file
  skip_before_action :deny_access_to_all

  access_control do
    actions :regenerate_download do
      allow :admin, :data_admin
      allow :owner, :proposer, of: :dataset
      allow logged_in, if: :dataset_is_free_for_members
      allow logged_in, if: :dataset_is_free_for_project_of_user
      allow all, if: :dataset_is_free_for_public
    end
  end

  def regenerate_download
    @exported_file.queued_to_be_exported

    # status of the downloadable files
    @exported_excel = @dataset.exported_excel || @dataset.create_exported_excel
    @exported_csv = @dataset.exported_csv || @dataset.create_exported_csv
    @exported_scc_csv = @dataset.exported_scc_csv || @dataset.create_exported_scc_csv

    respond_to do |format|
      format.html
      format.js { render template: 'datasets/regenerate_downloads.js.haml' }
    end
  end

  private

  def load_file
    @exported_file = ExportedFile.find(params[:id])
    @dataset = @exported_file.dataset
  end
end
