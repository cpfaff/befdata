# frozen_string_literal: true

class ::ApplicationController < ActionController::Base
  # for application wide pagination
  protect_from_forgery
  include Pagy::Backend

  # user session setup
  helper_method :current_user_session, :current_user, :current_cart
  # layout :layout_from_config

  access_control :deny_access_to_all do
    deny all
  end
  rescue_from 'Acl9::AccessDenied', with: :access_denied

  def dataset_is_free_for_members
    return true unless @dataset.blank? || !@dataset.free_for_members?

    false
  end

  def dataset_is_free_for_public
    return true unless @dataset.blank? || !@dataset.free_for_public?

    false
  end

  def dataset_is_free_for_project_of_user(user = current_user)
    return true unless @dataset.blank? || !(@dataset.free_within_projects? && !(user.projects & @dataset.projects).empty?)

    false
  end

  def user_may_edit_profile?
    return false unless @user && current_user

    @user == current_user
  end

  protected

  def layout_from_config
    LayoutHelper::BEF_LAYOUT
  end

  private

  def current_user_session
    return @current_user_session if defined?(@current_user_session)

    @current_user_session = UserSession.find
  end

  def current_user
    return @current_user if defined?(@current_user)

    @current_user = current_user_session&.user
  end

  def require_no_user
    if current_user
      flash[:error] = 'You must be logged out to access this page'
      redirect_back(fallback_location: root_url)
      false
    end
  end

  def current_cart
    cookies[:cart_id] ||= Cart.create!.id
    begin
      @current_cart ||= Cart.find(cookies[:cart_id])
    rescue StandardError
      cookies[:cart_id] = Cart.create!.id
      @current_cart ||= Cart.find(cookies[:cart_id])
    end
  end

  # specify a collection of sorted-by options, and one of them is the default
  # eg: validate_sort_params(collection: ['a', 'b'], default: 'a')
  def validate_sort_params(*options)
    options = options.extract_options!
    raise 'A collection of allowed sorting options should be specified!' unless options[:collection].present?

    options[:default] ||= options[:collection].first
    params[:sort] = options[:default] unless options[:collection].include?(params[:sort])
    params[:direction] = 'asc' unless %w[desc asc].include?(params[:direction])
  end

  def access_denied
    if current_user
      flash[:error] = 'Access denied. You do not have the appropriate rights to perform this operation.'
      redirect_back(fallback_location: root_url)
    else
      flash[:error] = 'Access denied. Try to log in first.'
      session[:return_to] = request.url if request.get?
      redirect_back(fallback_location: root_url)
    end
  end
end
