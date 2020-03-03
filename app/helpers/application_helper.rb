# frozen_string_literal: true

# TODO:
# * Search proposals on date range
# def selection_paperproposal_publication_years
  # Paperproposal.pluck("DISTINCT EXTRACT(YEAR FROM updated_at)::Integer").sort.reverse
# end
# * add a new implementation of tag clouds

module ApplicationHelper
  include Acl9Helpers
  include Pagy::Frontend

  def with_customized_layout?
    LayoutHelper::BEF_LAYOUT != 'standard'
  end

  # set the title of the page in the browser
  def page_title(title)
    content_for :title, title
  end

  # seletion helpers
  def all_project_roles_for_select
    t('role').slice(:pi, :"co-pi", :postdoc, :"phd student",
                    :technician, :student).invert
  end

  def all_project_phases_for_select
    Dataset::PROJECT_PHASE.map{ |code, id| [code.to_s.humanize, id]}
  end


  def all_tags_for_select
    ActsAsTaggableOn::Tag.all.map{ |tag| [ tag.name, tag.id ] }.uniq
  end

  def all_dataset_tags_for_select
    Dataset.all_tags.map{ |tag| [ "#{tag.name} (#{tag.taggings_count})", tag.id.to_s ] }.sort.uniq
  end

  def all_paperproposal_external_states_for_select
    { "Accepted": "accepted", "In Review": "in review", "Manuscript available": "manuscript avaible", "In preparation": "in prep", "Flagged for deletion": "deletion"  }
  end

  def all_paperproposal_internal_states_for_select
    Paperproposal.pluck(:state).uniq.sort.map(&:humanize)
  end

  def all_dataset_access_righs_for_select
    Dataset::ACCESS_CODES.map{ |code, id| [code.to_s.humanize, id]}
  end

  def all_projects_for_select
    Project.select('id, name').order('lower(name)').collect { |p| [p.to_s, p.id] }
  end

  # sort by table columns
  def sortable(column, title = nil, type = nil)
    title ||= column.titleize
    type ||= "alpha"
    direction = column == sort_column && sort_direction == "asc" ? "desc" : "asc"
    if type == "alpha"
      if direction == "asc"
        link_to fa_icon('sort-alpha-up', text: "#{title}:", right: true),
          { :sort => column, :direction => direction, search: params[:search], filter: params[:filter], select: params[:select]}
      else
        link_to fa_icon('sort-alpha-down', text: "#{title}:", right: true),
          { :sort => column, :direction => direction, search: params[:search], filter: params[:filter], select: params[:select]}
      end
    else
      if direction == "asc"
        link_to fa_icon('sort-numeric-up', text: "#{title}:", right: true),
          { :sort => column, :direction => direction, search: params[:search], filter: params[:filter], select: params[:select]}
      else
        link_to fa_icon('sort-numeric-down', text: "#{title}:", right: true),
          { :sort => column, :direction => direction, search: params[:search], filter: params[:filter], select: params[:select]}
      end
    end
  end
end
