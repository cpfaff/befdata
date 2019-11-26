class FillImportCategoryFieldsFromCategories < ActiveRecord::Migration
  def self.up
    import_categories = ImportCategory.all
    import_categories.each do |ic|
      ic.update_attributes(short: ic.category.short,
                           long: ic.category.long,
                           description: ic.category.description)
    end
  end

  def self.down
    # raise ActiveRecord::IrreversibleMigration
  end
end
