# frozen_string_literal: true

# This controller handles all calls for staff information.

class UsersController < ApplicationController
  before_action :load_user, only: %i[show edit destroy update]
  skip_before_action :deny_access_to_all
  access_control do
    actions :index, :show do
      allow all
    end
    actions :new, :create, :destroy, :edit, :update do
      allow :admin
    end
  end

  def index
    @users = User.select('id, firstname, lastname, salutation, email, avatar_file_name, alumni')
                 .order('lower(lastname) asc, lower(firstname) asc')
    respond_to do |format|
      format.html
      format.xml
    end
  end

  def show
    @datasets_owned = @user.datasets_owned.sort_by { |d| d.title.to_s }
    @datasets_with_responsible_datacolumns_not_owned = @user.datasets_with_responsible_datacolumns - @datasets_owned
    @project_roles = @user.projectroles
    @paperproposals = @user.paperproposals
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(users_params)
    if @user.save
      @user.projectroles = params.fetch(:roles, {})
      redirect_to user_path(@user), notice: "Successfully Created user #{@user.to_label}"
    else
      render action: :new
    end
  end

  def edit
    @project_roles = @user.projectroles.collect { |r| { role_name: r.name, project_id: r.authorizable_id } }
  end

  def update
    if @user.update_attributes(users_params)
      @user.projectroles = params.fetch(:roles, {})
      redirect_to user_path(@user), notice: 'Saved successfully'
    else
      render :edit
    end
  end

  def destroy
    user_name = @user.full_name
    if @user.destroy
      redirect_to users_path, notice: "Successfully deleted #{user_name}"
    else
      flash[:error] = @user.errors.full_messages.to_sentence
      redirect_back(fallback_location: root_url)
    end
  end

  private

  def load_user
    @user = User.find(params[:id])
  end

  def users_params
    params.require(:user).permit(:login,
                                 :password,
                                 :password_confirmation,
                                 :firstname,
                                 :middlenames,
                                 :lastname,
                                 :salutation,
                                 :email,
                                 :project_board,
                                 :admin,
                                 :data_admin,
                                 :alumni,
                                 :avatar)
  end
end
