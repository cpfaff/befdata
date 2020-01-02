# frozen_string_literal: true

class DatafilesController < ApplicationController
  skip_before_action :deny_access_to_all
  before_action :load_dataset_and_datafile
  access_control do
    action :download, :destroy do
      allow :admin
      allow :owner, of: :dataset
    end
  end

  def download
    send_file @datafile.file.path
  end

  def destroy
    flash[:error] = @datafile.errors.full_messages.to_sentence unless @datafile.destroy
    redirect_back(fallback_location: root_url)
  end

  private

  def load_dataset_and_datafile
    @dataset = Dataset.find(params[:dataset_id])
    @datafile = @dataset.datafiles.find(params[:id])
  end
end
