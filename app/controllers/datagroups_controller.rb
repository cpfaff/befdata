# frozen_string_literal: true

class DatagroupsController < ApplicationController
  skip_before_action :deny_access_to_all
  before_action :load_datagroup, except: %i[index new create]

  access_control do
    actions :index, :show, :import_categories, :new, :create, :datacolumns do
      allow logged_in
    end
    actions :upload_categories, :update_categories, :edit, :update, :destroy do
      allow :admin, :data_admin
    end
  end

  helper_method :sort_column, :sort_direction

  def index
    # get all
    @datagroups = Datagroup.select('id, title, description,
                                    created_at, updated_at, datacolumns_count,
                                    (select count(*) from categories where datagroup_id = datagroups.id) as categories_count')

    # sort
    @datagroups = @datagroups.order(sort_column + ' ' + sort_direction) if params[:sort]

    # search
    if params[:search]
      @filter = params.fetch(:search).permit(:query)
      @datagroups = @datagroups.search(@filter.fetch(:query)).order(:id) unless @filter.fetch(:query).empty?
    end


    # paginate
    @pagy, @datagroups = pagy(@datagroups)

    # respond
    respond_to do |format|
      format.html
      format.xml
    end
  end

  def new
    @datagroup = Datagroup.new
  end

  def create
    @datagroup = Datagroup.new(datagroup_params)
    if @datagroup.save
      flash[:notice] = "Data group '#{@datagroup.title}' was added successfully."
      redirect_to params[:import] ? new_datagroup_category_path(@datagroup) : @datagroup
    else
      render :new
    end
  end

  def show
    @datasets = @datagroup.datasets.order(:title).distinct
    @categories = @datagroup.categories.select('id, short, long, description, (select count(sheetcells.id) from sheetcells where sheetcells.category_id = categories.id) as count')
  end

  def update
    if @datagroup.update_attributes(datagroup_params)
      redirect_to @datagroup, notice: 'Successfully updated'
    else
      render :edit
    end
  end

  def destroy
    unless @datagroup.datasets.empty?
      flash[:error] = "Datagroup has associated datasets thus can't be deleted"
      redirect_back(fallback_location: root_url) and return
    end
    if @datagroup.destroy
      redirect_to datagroups_path, notice: "Deleted #{@datagroup.title}" and return
    else
      flash[:error] = @datagroup.errors.full_messages.to_sentence
      redirect_back(fallback_location: root_url)
    end
  end

  # step 1 to batch update datagroup categories via CSV
  def upload_categories; end

  # step 2 to batch update datagroup categories via CSV
  def update_categories
    unless csv_params
      flash[:error] = 'No File given'
      redirect_back(fallback_location: root_url) && return
    end

    f = csv_params.fetch(:file).path

    changes = @datagroup.update_and_merge_categories_with_csv(f, current_user)

    if @datagroup.errors.empty?
      flash[:notice] = "#{changes[:u]} categories are updated and #{changes[:m]} categories are merged"
      redirect_to datagroup_path(@datagroup)
    else
      flash[:error] = @datagroup.errors.full_messages.to_sentence
      redirect_back(fallback_location: root_url) && return
    end
  end

  def import_categories
    unless csv_params
      flash[:error] = 'No File given'
      redirect_back(fallback_location: root_url) && return
    end

    if @datagroup.import_categories_with_csv(csv_params.fetch(:file).path)
      redirect_back(fallback_location: root_url, notice: 'Categories are successfully imported')
    else
      flash[:error] = @datagroup.errors.full_messages.to_sentence
      redirect_back(fallback_location: root_url)
    end
  end

  def datacolumns
    respond_to do |format|
      format.html do
        @pagy, @datacolumns = pagy(@datagroup.datacolumns.order('dataset_id, columnheader'))
      end
      format.js { @headers = @datagroup.datacolumns.pluck(:columnheader) }
    end
  end

  private

  # sorting by
  def sort_column
    # allow columns names plus some extras
    sorting_columns = Datagroup.column_names + ['categories_count']
    # select the correct sorting columns or default to title
    sorting_columns.include?(params[:sort]) ? params[:sort] : 'title'
  end

  # sort direction
  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : 'asc'
  end

  # load datagroup
  def load_datagroup
    @datagroup = Datagroup.find(params[:id])
  end

  def datagroup_params
    params.require(:datagroup).permit(:title, :description, :comment)
  end

  def csv_params
    params.require(:datagroup).permit(:file, :@tempfile, :@original_filename, :@content_type, :@headers)
  end
end
