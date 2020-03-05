# frozen_string_literal: true

class PagesController < ApplicationController
  skip_before_action :deny_access_to_all
  access_control do
    actions :home, :legal, :help do
      allow all
    end
  end

  def home; end

  def legal; end

  def help; end
end
