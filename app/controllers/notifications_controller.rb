# frozen_string_literal: true

class NotificationsController < ApplicationController
  before_action :load_notification, except: [:index]

  skip_before_action :deny_access_to_all
  # this has been moved over from the model with strong params it
  # is not neccessary anymore
  # attr_accessible :message, :read, :subject, :user_id

  access_control do
    actions :index, :mark_as_read, :destroy do
      allow logged_in
    end
  end

  def index
    @notifications = current_user.notifications.order('created_at DESC')
  end

  def mark_as_read
    if defined?(params[:read]) && @notification.update_attribute(:read, params[:read])
      redirect_to notifications_url
    else
      redirect_to notifications_url, alert: 'Error'
    end
  end

  def destroy
    @notification.destroy
    redirect_to notifications_url
  end

  private

  def load_notification
    @notification = current_user.notifications.where(id: params[:id]).first
    redirect_back(fallback_location: root_url) && return unless @notification
  end
end
