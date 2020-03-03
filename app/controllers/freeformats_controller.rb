# frozen_string_literal: true

class FreeformatsController < ApplicationController
  before_action :load_freeformat_and_freeformattable, except: :create
  before_action :load_freeformattable, only: :create
  after_action  :dataset_edit_message, except: [:download]

  skip_before_action :deny_access_to_all

  access_control do
    actions :download, :update, :edit, :create, :destroy do
      allow :admin, :data_admin
      allow :owner, of: :dataset
      allow logged_in, if: :paperproposal_author
    end
    actions :download do
      allow :proposer, of: :dataset
      allow logged_in, if: :dataset_is_free_for_project_of_user
      allow logged_in, if: :dataset_is_free_for_members
      allow all, if: :dataset_is_free_for_public
      allow logged_in, if: :freeformattable_is_paperproposal
    end
  end

  def create
    freeformat = @freeformattable.freeformats.build(freeformat_params)
    if freeformat.save
      redirect_back(fallback_location: root_url)
    else
      flash[:error] = freeformat.errors.to_a.first.capitalize.to_s
      redirect_back(fallback_location: root_url)
    end
  end

  def update
    if @freeformat.update_attributes(freeformat_params)
      redirect_back(fallback_location: root_url)
    else
      flash[:error] = @freeformat.errors.to_a.first.capitalize.to_s
      redirect_back(fallback_location: root_url)
    end
  end

  def destroy
    @freeformat.destroy
    if @freeformat.destroyed?
      redirect_back(fallback_location: root_url)
    else
      flash[:error] = @freeformat.errors.to_a.first.capitalize.to_s
      redirect_back(fallback_location: root_url)
    end
  end

  def download
    send_file @freeformat.file.path, filename: @freeformat.to_label, disposition: 'attachment'
  end

  private

  def load_freeformattable
    @freeformattable = params[:freeformattable_type].classify.constantize.find(params[:freeformattable_id])
    load_type_of_freeformattable
  end

  def load_freeformat_and_freeformattable
    @freeformat = Freeformat.find params[:id]
    @freeformattable = @freeformat.freeformattable
    load_type_of_freeformattable
  end

  def load_type_of_freeformattable
    @dataset = @freeformattable if @freeformattable.is_a? Dataset
    @paperproposal = @freeformattable if @freeformattable.is_a? Paperproposal
  end

  def freeformattable_is_paperproposal
    defined? @paperproposal
  end

  def paperproposal_author
    @paperproposal && @paperproposal.author == current_user
  end

  def dataset_edit_message
    @freeformattable.log_edit('Files changed') if @freeformattable.is_a? Dataset
  end

  def freeformat_params
    params.require(:freeformat).permit(:file, :description, :is_essential, :uri)
  end
end
