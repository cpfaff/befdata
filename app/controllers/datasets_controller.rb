# frozen_string_literal: true

class DatasetsController < ApplicationController
  skip_before_action :deny_access_to_all

  before_action :load_dataset,
                except: %i[new create create_with_datafile importing index download_excel_template]

  before_action :redirect_if_without_workbook,
                only: %i[download approve approve_predefined batch_update_columns approval_quick]

  before_action :redirect_unless_import_succeed,
                only: %i[download approve approve_predefined approval_quick batch_update_columns]

  before_action :redirect_while_importing,
                only: %i[edit_files update_workbook destroy]

  after_action :edit_message_datacolumns,
               only: %i[batch_update_columns approve_predefined]

  access_control do
    allow all,
          to: %i[show index download_excel_template importing keywords download_status]

    actions :edit, :update, :destroy,
            :edit_files, :update_workbook,
            :approve, :approve_predefined,
            :approval_quick, :batch_update_columns do
      allow :admin, :data_admin
      allow :owner, of: :dataset
    end

    actions :download, :freeformats_csv do
      allow :admin, :data_admin
      allow :owner, :proposer, of: :dataset
      allow logged_in, if: :dataset_is_free_for_members
      allow logged_in, if: :dataset_is_free_for_project_of_user
      allow all, if: :dataset_is_free_for_public
    end

    actions :new, :create, :create_with_datafile do
      allow logged_in
    end
  end

  helper_method :sort_column, :sort_direction

  # create dataset with only a title
  def create
    @dataset = Dataset.new(title: params.require(:dataset)[:title].to_s.squish)
    if @dataset.save
      current_user.has_role! :owner, @dataset
    else
      flash[:error] = @dataset.errors.full_messages.to_sentence
      redirect_back(fallback_location: root_url)
    end
  end

  # create a dataset with a csv file
  def create_with_datafile
    unless params.require(:datafile).permit(:utf8, :authenticity_token, :title, :file, :'@tempfile', :'@original_filename', :'@content_type', :'@headers')
      flash[:error] = 'No data file given for upload'
      redirect_back(fallback_location: root_url) && return
    end

    datafile = Datafile.new(params.require(:datafile).permit(:utf8, :authenticity_token, :title, :file, :'@tempfile', :'@original_filename', :'@content_type', :'@headers'))
    unless datafile.save
      flash[:error] = datafile.errors.full_messages.to_sentence
      redirect_back(fallback_location: root_url) && return
    end

    attributes = datafile.general_metadata_hash
    attributes[:title] = params.slice(:title)[:title].to_s.squish if params[:title]

    @dataset = Dataset.new(attributes)
    if @dataset.save
      @dataset.add_datafile(datafile)
      @dataset.load_projects_and_authors_from_current_datafile
      current_user.has_role! :owner, @dataset
      @unfound_usernames = datafile.authors_list[:unfound_usernames]
      render action: :create
    else
      datafile.destroy
      flash[:error] = @dataset.errors.full_messages.to_sentence
      redirect_back(fallback_location: root_url)
    end
  end

  # update the metatadata of a file
  def update
    if @dataset.update_attributes(params.require(:dataset).permit(:authenticity_token,
                                                                  :title, :project_phase, :access_code, :include_license, :usagerights, :tag_list,
                                                                  :abstract, :published, :spatialextent, :'datemin(1i)', :'datemin(2i)',
                                                                  :'datemin(3i)', :'datemax(1i)', :'datemax(2i)', :'datemax(3i)', :temporalextent,
                                                                  :taxonomicextent, :design, :dataanalysis, :circumstances, :comment, owner_ids: [],
                                                                                                                                      project_ids: []))

      @dataset.refresh_paperproposal_authors if params.require(:dataset)[:owner_ids].present?
      # TODO: should not refresh all authors of the pp
      @dataset.log_edit('Metadata updated')

      # invalidate exported xls file
      ExportedFile.invalidate(@dataset.id, :xls)

      redirect_to dataset_path, notice: 'Sucessfully Saved'
    else
      last_request = request.env['HTTP_REFERER']
      render action: (last_request == edit_dataset_url(@dataset) ? :edit : :create)
    end
  end

  # note: this funciton is used by the ajax import status query
  def importing
    @dataset = Dataset.where(id: params.fetch(:id)).first
    render plain: @dataset.import_status
  end

  def approve
    @predefined_columns = @dataset.predefined_columns.collect(&:id)
    render layout: 'approval'
  end

  def approval_quick
    @datagroups = Datagroup.order(:title)
    @datatypes = Datatypehelper.known
    render layout: 'approval'
  end

  def batch_update_columns
    datacolumns = params.permit(:utf8, :authenticity_token, datacolumn: %i[id datagroup import_data_type]).require(:datacolumn)
    changes = 0
    datacolumns.each do |hash|
      datacolumn = Datacolumn.find hash[:id]
      unless datacolumn.dataset == @dataset
        flash[:error] = 'Updated datacolumns must be part of the dataset!'
        redirect_to(dataset_url(@dataset)) && return
      end

      if hash[:datagroup].present?
        datagroup = Datagroup.find(hash[:datagroup])
        datacolumn.approve_datagroup(datagroup)
        changes += 1
      end

      next unless datacolumn.datagroup_approved && hash[:import_data_type].present?

      datatype = hash[:import_data_type]
      datacolumn.approve_datatype datatype, current_user
      changes += 1
    end
    ExportedFile.invalidate(@dataset.id, :all) if changes > 0 # invalidate all exported files
    flash[:notice] = "Successfully approved #{changes} properties of your dataset."
    redirect_to dataset_url(@dataset)
  end

  def approve_predefined
    @dataset.approve_predefined_columns

    if @dataset.columns_with_invalid_values_after_approving_predefined.blank?
      flash[:notice] = 'All available columns were successfully approved.'
    else
      still_unapproved_columns = @dataset.columns_with_invalid_values_after_approving_predefined
      flash[:error] = "Unfortunately we could not automatically validate entries in the following data columns:
        #{still_unapproved_columns.map(&:columnheader).join(', ')}"
      flash[:non_auto_approved] = still_unapproved_columns.map(&:id)
    end
    ExportedFile.invalidate(@dataset.id, :all)
    redirect_back(fallback_location: root_url)
  end

  def show
    # tigger import on visit
    trigger_import_if_nessecary

    # owners of the dataset
    @owners = @dataset.owners.order('alumni')

    # projects the dataset belongs to
    @projects = @dataset.projects

    # freeformats attached to the dataset
    @freeformats = @dataset.freeformats.order('file_file_name')

    # datacolumns of the dataset
    @datacolumns = @dataset.datacolumns.includes(:datagroup, :tags)

    # all tags of the dataset
    @tags = @dataset.all_tags

    # get the exported files
    @exported_excel = @dataset.exported_excel || @dataset.create_exported_excel
    @exported_csv = @dataset.exported_csv || @dataset.create_exported_csv
    @exported_scc_csv = @dataset.exported_scc_csv || @dataset.create_exported_scc_csv
    @freeformats = @dataset.freeformats

    # when there is need to create them do so (it may be better to handle this
    # in a javascript function calling for the status and if necessary trigger
    # the correct action in the datafiles related controller.
    @exported_excel.queued_to_be_exported if @exported_excel.status.eql? 'new'

    if @exported_excel.invalidated_at.present? && @exported_excel.generated_at.present?
      @exported_excel.queued_to_be_exported if @exported_excel.invalidated_at > @exported_excel.generated_at
    end

    @exported_csv.queued_to_be_exported if @exported_csv.status.eql? 'new'

    if @exported_csv.invalidated_at.present? && @exported_csv.generated_at.present?
      @exported_csv.queued_to_be_exported if @exported_csv.invalidated_at > @exported_csv.generated_at
    end

    @exported_scc_csv.queued_to_be_exported if @exported_scc_csv.status.eql? 'new'

    if @exported_scc_csv.invalidated_at.present? && @exported_scc_csv.generated_at.present?
      @exported_scc_csv.queued_to_be_exported if @exported_scc_csv.invalidated_at > @exported_scc_csv.generated_at
    end

    # answer to
    respond_to do |format|
      format.html
      format.xml
      format.eml
      format.js
    end
  end

  def index
    @datasets = Dataset.all
    @tagged_datasets = DatasetTag.all

    if params[:search]
      @filter = params.fetch(:search).permit(:query, project_phase: [], access_code: [], tag: [])
      @datasets = @datasets.search(@filter.fetch(:query)).order(:id) unless @filter.fetch(:query).empty?
      @datasets = @datasets.where(access_code: @filter.fetch(:access_code)) unless @filter.fetch(:access_code).all?(&:blank?)

      # depending on configuration of the application  we have project phases or not
      if PHASE_CONFIG.present?
        @datasets = @datasets.where(project_phase: @filter.fetch(:project_phase)) unless @filter.fetch(:project_phase).all?(&:blank?)
      end

      @datasets = @datasets.tagged_with(Dataset.all_tags.where(id: @filter.fetch(:tag)).pluck(:name), any: true) unless @filter.fetch(:tag).all?(&:blank?)
    end

    @datasets = @datasets.order(sort_column + ' ' + sort_direction) if params[:sort]

    @pagy, @datasets = pagy(@datasets)

    respond_to do |format|
      format.html
      format.xml { render xml: @datasets }
      format.json { render json: @datasets }
    end
  end

  def download_status
    respond_to do |format|
      format.json do
        result = {}

        if @dataset.has_research_data?
          if @dataset.finished_import?
            @dataset.exported_files.each { |ef| result[ef.format] = ef.status }
          else
            result[:error] = 'Importing of the dataset is not finished yet.'
          end
        else
          result[:error] = 'The requested dataset has no data'
        end
        render json: result
      end
    end
  end

  def download
    @dataset.log_download(current_user)
    respond_to do |format|
      format.html do
        send_file_if_exists @dataset.exported_excel, filename: "#{@dataset.filename}.xls", disposition: 'attachment'
      end
      format.csv do
        if params[:separate_category_columns] =~ /true/i
          send_file_if_exists @dataset.exported_scc_csv, filename: "#{@dataset.filename}-scc.csv", disposition: 'attachment'
        else
          send_file_if_exists @dataset.exported_csv, filename: "#{@dataset.filename}.csv", disposition: 'attachment'
        end
      end
    end
  end

  def freeformats_csv
    filename = "dataset-#{@dataset.id}-files" + (current_user ? "-for-#{current_user.login}" : '') + '.csv'
    send_data generate_freeformats_csv(true), type: 'text/csv',
                                              disposition: 'attachment', filename: filename
  end

  def edit_files
    redirect_to(action: 'show') && return unless @dataset.import_status.nil? || @dataset.import_status.starts_with?('finished', 'error')
    @freeformats = @dataset.freeformats order: :file_file_name
    @datafiles = @dataset.datafiles
  end

  def update_workbook
    unless params.require(:datafile).permit(:utf8, :authenticity_token, :title, :file, :'@tempfile', :'@original_filename', :'@content_type', :'@headers')
      flash[:error] = 'No filename given'
      redirect_back(fallback_location: root_url) && return
    end
    new_datafile = Datafile.new(params.require(:datafile).permit(:utf8, :authenticity_token, :title, :file, :'@tempfile', :'@original_filename', :'@content_type', :'@headers'))
    if new_datafile.save
      @dataset.delete_imported_research_data
      @dataset.add_datafile(new_datafile)
      @dataset.log_edit('Workbook updated')
      flash[:notice] = 'Research data has been replaced.'
      redirect_to(action: 'show')
    else
      flash[:error] = new_datafile.errors.full_messages.to_sentence
      redirect_back(fallback_location: root_url)
    end
  end

  def destroy
    if @dataset.destroy
      flash[:notice] = 'The dataset was successfully deleted.'
      redirect_to datasets_path
    else
      flash[:error] = @dataset.errors.full_messages.to_sentence
      redirect_back(fallback_location: root_url)
    end
  end

  def keywords
    @dataset_keywords = @dataset.tags
    @datacolumns = @dataset.datacolumns.includes(:tags)
    @related_datasets = @dataset.find_related_datasets
  end

  private

  def sort_column
    Dataset.column_names.include?(params[:sort]) ? params[:sort] : 'name'
  end

  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : 'asc'
  end

  def generate_freeformats_csv(_user)
    CSV.generate do |csv|
      csv << %w[Filename URL Description]
      @dataset.freeformats.each do |ff|
        csv << [
          ff.file_file_name, download_freeformat_url(ff, user_credentials: current_user.try(:single_access_token)), ff.description
        ]
      end
    end
  end

  def load_dataset
    @dataset = Dataset.find(params[:id])
  end

  def trigger_import_if_nessecary
    if @dataset.import_status.eql? 'new'
      @dataset.update_attribute(:import_status, 'queued')
      @dataset.delay.import_data
    end
  end

  def redirect_if_without_workbook
    unless @dataset.has_research_data?
      flash[:error] = "The operation requires the dataset to have a workbook, but it doesn't."
      redirect_to(action: 'show') && return
    end
  end

  def redirect_unless_import_succeed
    unless @dataset.import_status == 'finished'
      flash[:error] = "The dataset hasn't been successfully imported!"
      redirect_to(action: 'show') && return
    end
  end

  def redirect_while_importing
    if @dataset.being_imported?
      flash[:error] = 'Please wait till the importing finishes'
      redirect_to(action: 'show') && return
    end
  end

  def edit_message_datacolumns
    @dataset.log_edit('Datacolumns approved')
  end

  def send_file_if_exists(file, options = {})
    if file&.path && File.file?(file.path)
      send_file file.path, options
    else
      flash[:error] = "The file is not found on the server. Likely it's being created at the moment, Please wait till it's finished."
      redirect_back(fallback_location: dataset_path(@dataset))
    end
  end
end
