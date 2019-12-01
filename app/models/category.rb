# frozen_string_literal: true

## Categories store naming conventions that are referenced by an instance of a "Sheetcell".
##
## Categories are linked to "Datagroup"s. The validation process ensures that Categories are unique within a "Datagroup".
class Category < ActiveRecord::Base
  belongs_to :datagroup, class_name: 'Datagroup', foreign_key: 'datagroup_id'
  has_many :sheetcells

  validates_presence_of :short, :long, :description
  before_validation :try_filling_missing_values

  before_destroy :check_for_sheetcells_associated
  after_update :expire_related_exported_datasets

  def self.delete_orphan_categories
    # delete categories that has no assciated sheetcells
    to_be_deleted = Category.joins('left outer join sheetcells on sheetcells.category_id = categories.id')
                            .where('sheetcells.category_id is NULL')
    unless to_be_deleted.empty?
      puts "#{to_be_deleted.count} categories is deleted at #{Time.now.utc}"
    end
    Category.delete(to_be_deleted)
  end

  def try_filling_missing_values
    if short
      self.long = short if long.blank?
      self.description = long if description.blank?
    end
  end

  def show_value
    "#{long} (#{short})"
  end

  def check_for_sheetcells_associated
    sc = sheetcells(true)
    unless sc.empty? || (sc.count == 1 && sc.first.destroyed?)
      errors[:base] = "#{short} has associated sheetcells, thus can't be deleted"
      false
    end
  end

  def self.search(search)
    if search
      where('short iLIKE :q OR long iLIKE :q OR description iLIKE :q', q: "%#{search}%")
    else
      all
    end
  end

  def update_sheetcells_with_csv(file, user)
    begin
      lines = CSV.read(file, CsvData::OPTS)
    rescue StandardError
      errors.add(:file, 'can not be read') && (return false)
    end
    return false if validate_sheetcells_csv?(lines)

    update_overview = split_sheetcells_category(lines, user)
    unless update_overview.blank?
      self.comment = "#{comment} Split via CVS by #{user.lastname}, #{Time.now}.".strip
      save
    end
    update_overview
  end

  def merge_to(to_category, user)
    return unless datagroup_id == to_category.datagroup_id

    expire_related_exported_datasets

    comment_string = "Merged #{short} by #{user.lastname} at #{Time.now.utc} via CSV; "
    sheetcells.update_all(category_id: to_category.id, updated_at: Time.now)
    Category.where(id: to_category.id).update_all(
      comment: "#{to_category.comment} #{comment_string}".strip,
      updated_at: Time.now
    )
    delete
  end

  protected

  # find and update the updated_at date for all datasets that share this category
  def expire_related_exported_datasets
    sql = "select update_date_category_datasets(#{id})"
    connection = ActiveRecord::Base.connection()
    connection.execute(sql)
  end

  private

  def validate_sheetcells_csv?(csv_lines)
    errors.add(:csv, 'seems to be empty') && (return false) if csv_lines.empty?
    unless (['ID', 'IMPORT VALUE', 'COLUMNHEADER', 'DATASET', 'NEW CATEGORY SHORT'] - csv_lines.headers).empty?
      errors.add(:csv, 'column headers does not match') && (return false)
    end

    csv_sheetcell_ids = csv_lines['ID'].collect(&:to_i)
    unless csv_sheetcell_ids.uniq!.nil?
      errors.add(:csv, 'IDs must be unique') && (return false)
    end

    if csv_lines['ID'].any?(&:blank?)
      errors.add(:csv, 'ID must not be empty') && (return false)
    end

    cat_sheetcell_ids = sheetcell_ids
    sheetcells_no_match = csv_sheetcell_ids - cat_sheetcell_ids
    unless sheetcells_no_match.empty?
      errors.add(:csv, "sheetcell #{sheetcells_no_match} not found in category") && (return false)
    end
  end

  def split_sheetcells_category(csv_lines, user)
    pairs = csv_lines.reject { |l| l[4].blank? }.collect { |l| [l[0].to_i, l[4]] }
    updates_overview = []
    altered_cats = []
    pairs.each do |p|
      existing_cat = Category.where(datagroup_id: datagroup_id, short: p[1]).first
      if existing_cat
        if existing_cat == self
          updates_overview << [p[0], 'already', nil, nil]
        else
          Sheetcell.find(p[0]).update_attributes(category: existing_cat)
          altered_cats << existing_cat
          updates_overview << [p[0], 'added', existing_cat.id, existing_cat.short]
        end
      else
        new_category = Category.create(short: p[1], datagroup: datagroup)
        Sheetcell.find(p[0]).update_attributes(category: new_category)
        altered_cats << new_category
        updates_overview << [p[0], 'new', new_category.id, new_category.short]
      end
    end

    comment_string = "Added sheetcells via CVS by #{user.lastname}, #{Time.now}.".strip
    altered_cats.uniq.each do |c|
      c.comment = "#{c.comment} #{comment_string}".strip
      c.save
    end
    updates_overview
  end
end
