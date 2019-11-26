# Sheetcell entries are pointing at the raw data obtained from
# measuring something.
#
# The accepted value of the data is stored in the accepted_value field unless
# the "Datatype" is a "Category" where the category id is stored instead.
class Sheetcell < ActiveRecord::Base
  belongs_to :datacolumn
  belongs_to :category

  # Datatypes are defined in config/initializers/datatype_load.rb and the valitation procedures are
  # stored in https://github.com/befdata/befdata/blob/master/db/non_schema_sql.sql
  def datatype
    Datatypehelper.find_by_id(datatype_id) unless datatype_id.nil?
  end

  def same_entry_cells
    datacolumn.sheetcells.where(['import_value = ?', import_value])
  end

  # returns the accepted data for the sheet cell
  # we need to check that the category exists as it might not
  def show_value
    unless datatype.nil?
      if datatype.is_category? && !category.nil?
        category.show_value
      else
        # TODO: we should format the field based on the datatype
        accepted_value
      end
    end
  end

  def export_value
    value = nil
    value = if datatype && datatype.is_category? && category
              category.short
            elsif datatype && datatype.name.match(/^date/) && accepted_value
              accepted_value.to_datetime.to_s(:db)
            elsif accepted_value
              accepted_value
            else
              import_value
            end
    value
  end
end
