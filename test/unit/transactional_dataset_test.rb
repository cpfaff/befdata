# frozen_string_literal: true

require 'test_helper'

# This class does not use transactional fixtures thus allowing to
# test functions using transactions
class TransactionalDatasetTest < ActiveSupport::TestCase
  self.use_transactional_fixtures = false

  test 'creating and approving dataset then destroying should not leave any remains in the database' do
    models = "AuthorPaperproposal Cart CartDataset Category Datacolumn Datafile Datagroup
              Dataset DatasetPaperproposal Freeformat ImportCategory Paperproposal
              PaperproposalVote Project Role Sheetcell User".split(' ')
    # cleanup existing orphan datagroups & categories
    Datagroup.delete_orphan_datagroups
    Category.delete_orphan_categories
    before = {}
    models.each do |model|
      before[model] = eval("#{model}.count")
    end
    datagroup_ids_before = Datagroup.all.map(&:id)

    datafile = Datafile.create(file: File.new(File.join(fixture_path, 'test_files_for_uploads',
                                                        'z2_SiteB_PLOTS 1mGIS meta_kn_for  testing.xls')))

    datafile.save
    dataset = Dataset.create(title: 'APlainSimpleTestTitle')
    dataset.current_datafile = datafile
    dataset.save
    book = Workbook.new(dataset.current_datafile)
    # TODO: on import_data I get a whole bunch of
    # DEPRECATION WARNING: `serialized_attributes`
    # is deprecated without replacement, and will be
    # removed in Rails 5.0. (called from save_data_into_database
    # at /home/ctpfaff/Schreibtisch/befdata_development/befdata/app/models/workbook.rb:320)
    # it is not yet clear how to resolve that issue.
    book.import_data
    dataset.approve_predefined_columns
    # on destroy tag category with id 43 is missing
    # STDERR.puts ActsAsTaggableOn::Tag.all
    # For whatever reason tag 43 vanishes when the name of the fixture
    # is "variable". I renamed it to "avariable" and now it works
    # tags_012:
    # id: '43'
    # name: avariable
    dataset.destroy

    Datagroup.delete_orphan_datagroups
    Category.delete_orphan_categories

    after = {}
    models.each do |model|
      after[model] = eval("#{model}.count")
    end

    datagroups_ids_after = Datagroup.all.map(&:id)
    # assert_equal datagroup_ids_before, datagroups_ids_after
    before.each do |model, count|
      assert count == after[model], "For #{model} the numbers are: #{count} -> #{after[model]}"
    end
  end
end
