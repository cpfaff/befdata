# class UsersDatatable < ApplicationDatatable
class CategoriesDatatable < ApplicationDatatable
  delegate :current_user, to: :@view

  private

  def data
    categories.map do |category|
      [].tap do |column|
        column << category.short
        column << category.long
        column << category.description
        links = []
        # links << link_to('Show', user)
        # links << link_to('Edit', edit_user_path(user))
        # links << link_to('Delete', category, method: :delete, data: { confirm: 'Are you sure?' }, class: 'btn btn-sm btn-outline-primary')
        if current_user.admin? || current_user.data_admin?
          links << link_to('Delete', category, method: :delete, class: 'btn btn-sm btn-outline-primary')
        else
          links << link_to('Delete', category, method: :delete, class: 'btn btn-sm btn-outline-primary disabled')
        end
        column << links.join(' | ')
      end
    end
  end

  def count
    pagy(categories).count
  end

  def total_entries
    categories.count
  end

  def categories
    @categories ||= fetch_categories
  end

  def fetch_categories
    categories = Datagroup.find_by_id(params.require(:datagroup_id).to_i).categories

    search_string = []
    columns.tap(&:pop).each do |term|
      search_string << "#{term} like :search"
    end

    # will_paginate
    # users = User.page(page).per_page(per_page)
    # categories = categories.page(page).per(per_page)
    # categories = pagy(categories)
    categories = categories.order("#{sort_column} #{sort_direction}")
    categories = categories.where(search_string.join(' or '), search: "%#{params[:search][:value]}%")
  end

  def columns
    %w(short long description actions)
  end
end
