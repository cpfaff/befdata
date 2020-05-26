# frozen_string_literal: true

class ProjectsController < ApplicationController
  # acess control
  access_control do
    allow all, to: %i[index show]
    allow :admin, to: %i[new create edit update destroy]
  end

  # actions
  before_action :load_project,
                only: %i[show edit update destroy]

  skip_before_action :deny_access_to_all

  # helpers
  helper_method :sort_column, :sort_direction

  # methods
  def index
    # get all
    @projects = Project.all

    # order (needs to take place before search)
    if params[:sort]
      @projects = @projects.order(sort_column + ' ' + sort_direction)
    end

    # search
    if params[:search]
      @filter = params.fetch(:search).permit(:query)
      @projects = @projects.search(@filter.fetch(:query)).order(:id) unless @filter.fetch(:query).empty?
    end

    # paginate
    @pagy, @projects = pagy(@projects)

    # TODO:
    # This has been used in datagroups and might help here as well
    # in order to sort for the user count and the count of datasets
    # @datagroups = Datagroup.select('id, title, description, created_at,
    # datacolumns_count, (select count(*) from categories where datagroup_id
    # = datagroups.id) as categories_count')
  end

  def show
    @project_datasets = @project.datasets.order(:title).distinct
    @members = @project.users
  end

  def new
    @project = Project.new
  end

  def create
    @project = Project.new(params.require(:project).permit(:name, :shortname, :description, :comment))
    if @project.save
      unless params.fetch(:roles, {}).blank?
        params.fetch(:roles, {}).each do |role|
          @project.set_user_with_role(role[:type], User.find(role[:value] || []))
        end
      end
      redirect_to projects_path, notice: "Successfully Added project #{@project.shortname}"
    else
      render :new
    end
  end

  def edit
    @roles = @project.accepted_roles.includes(:users).collect { |r| { name: r.name, id: r.users.map(&:id) } }
  end

  def update
    if @project.update_attributes(params.require(:project).permit(:name, :shortname, :description, :comment))
      roles_config = params.fetch(:roles, {}).blank? ? [] : params.fetch(:roles, {})
      to_be_delete = @project.accepted_roles.map(&:name) - roles_config.map { |r| r['type'] }
      to_be_delete.each do |role|
        @project.set_user_with_role(role, [])
      end
      roles_config.each do |role|
        @project.set_user_with_role(role[:type], User.find(role[:value] || []))
      end
      redirect_to project_path(@project), notice: "Successfully saved project #{@project.name}"
    else
      render :edit
    end
  end

  def destroy
    name = @project.name
    if @project.destroy
      redirect_to projects_path, notice: "Successfully destroyed Prject: #{name}"
    else
      redirect_to projects_path, error: @project.errors.full_messages.to_sentence
    end
  end

  private

  def sort_column
    # defines default sort column
    Project.column_names.include?(params[:sort]) ? params[:sort] : 'shortname'
  end

  def sort_direction
    # defines default sort direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : 'asc'
  end

  def load_project
    @project = Project.find(params[:id])
  end
end
