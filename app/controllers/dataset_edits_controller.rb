# frozen_string_literal: true

class DatasetEditsController < ApplicationController
  before_action :load_dataset_and_its_edit, only: [:submit]

  skip_before_action :deny_access_to_all

  access_control do
    actions :index do
      allow logged_in
    end
    actions :submit do
      allow :admin
      allow :data_admin
      allow :owner, of: :dataset
    end
  end

  def index
    @dataset = Dataset.find(params[:dataset_id])
  end

  def submit
    if params[:notify].blank?
      flash[:error] = 'You should choose to whom the notifications are sent !'
      redirect_back(fallback_location: root_url) && return
    end

    if @dataset_edit.update_attributes(dataset_edit_params.merge(submitted: true))
      @dataset_edit.notify(params[:notify])
      flash[:notice] = 'Notifications were successfully submitted and sent, Thanks!'
    else
      flash[:error] = @dataset_edit.errors.full_messages.to_sentence
    end
    redirect_back(fallback_location: root_url)
  end

  private

  def dataset_edit_params
    params.require(:dataset_edit).permit(:description, :dataset_id, :id, :notify, :proposers, :downloaders)
  end

  def load_dataset_and_its_edit
    @dataset_edit = DatasetEdit.find(params[:id])
    @dataset = @dataset_edit.dataset
  end
end
