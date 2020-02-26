# frozen_string_literal: true

require 'test_helper'
require 'fileutils'
require 'libxml'

class DatasetsControllerTest < ActionController::TestCase
  setup :activate_authlogic

  # because the update of a datacolumns datatype in test "quick approve updates datacolumn properties" calls some
  # sql statement in Datacolumn.add_data_values(user) which is conflicting with the dafault rails test transactions
  self.use_transactional_tests = false

  test 'should get show dataset' do
    get :show, params: { id: Dataset.first.id }
    assert_success_no_error
  end

  test 'test update metadata expires exported Excel file' do
    login_nadrowski
    dataset = Dataset.find(5)
    orig_excel_invalidated_at = dataset.exported_excel.invalidated_at
    orig_csv_invalidated_at = dataset.exported_csv.invalidated_at

    post :update, params: { id: 5, dataset: { comment: 'test' } }
    assert_success_no_error
    assert_equal dataset.exported_excel.invalidated_at, orig_excel_invalidated_at
    assert_equal dataset.exported_csv.invalidated_at, orig_csv_invalidated_at
  end

  test 'should show eml metadata as xml' do
    get :show, params: { id: Dataset.first.id, format: :eml }
    assert_success_no_error
  end

  test 'eml should be valid' do
    get :show, params: { id: Dataset.last, format: :eml }
    dataset_as_eml = LibXML::XML::Document.string(@response.body)
    eml_schema = LibXML::XML::Schema.new('test/fixtures/test_files_for_eml/eml-2.1.0/eml.xsd')
    assert dataset_as_eml.validate_schema(eml_schema)
  end

  test 'dataset can be downloaded' do
    login_nadrowski
    ds = Dataset.find_by_title 'Test species name import second version'

    get :download, params: { id: ds.id }
    assert_success_no_error
  end

  test 'dataset can be downloaded via api key' do
    timeout_seconds = 60
    exported_file_status = Dataset.second.exported_files.map(&:status).any? {|item| item == "finished"}

    while timeout_seconds > 0 && exported_file_status == false do
      timeout_seconds = timeout_seconds - 1
      exported_file_status = Dataset.second.exported_files.map(&:status).any? {|item| item == "finished"}
      sleep(1)
    end

    if exported_file_status == true
      get :download, params: { id: Dataset.second.id, format: :csv, user_credentials: User.find_by_login('admin').single_access_token }
      assert_success_no_error
    end
  end

  test 'dataset can not be downloaded via invalid api key' do
    get :download, params: { id: Dataset.first.id, format: :csv, user_credentials: '12345' }
    assert_match(/Access denied. Try to log in first./, flash[:error])
  end

  test 'download datasets freeformats csv' do
    login_nadrowski
    get :freeformats_csv, params: { id: 7 }
    assert_success_no_error
  end

  test 'unlogged-in visitors can not download non free_for_public datasets' do
    ds = Dataset.find_by_title 'Test species name import second version'
    assert !ds.free_for_public?
    get :download, params: { id: ds.id, format: :csv}
    assert_match(/Access denied. Try to log in first./, flash[:error])
  end

  test 'unlogged-in visitors can only download free_for_public datasets' do
    ds_public = Dataset.find_by_title('TITLE: use for visual testing of export')
    assert ds_public.free_for_public?
    get :download, params: { id: ds_public.id, format: :csv }
    assert_nil flash[:error]
  end

  test 'members can download free for members datasets' do
    user = User.find_by_login 'Phdstudentnutrientcycling'
    login_user user.login
    ds = Dataset.find_by_title 'Test species name import second version'

    assert ds.free_for_members? && !user.has_roles_for?(ds)
    get :download, params: { id: ds.id }
    assert_nil flash[:error]
  end

  test "members cann't download datasets not free for members" do
    user = User.find_by_login 'Phdstudentnutrientcycling'
    login_user user.login
    ds = Dataset.find_by_title 'Test species name import'
    # make sure the dataset is not free for members and user has no role about it.
    assert !(ds.free_for_members? || ds.free_for_public? || user.has_roles_for?(ds))
    get :download, params: { id: ds.id }
    assert_match(/Access denied/, flash[:error])
  end

  test 'members can not download datasets belonging to other projects only' do
    user = User.find_by_login('Pidata')
    login_user user.login
    ds = Dataset.find_by_title 'Unit tests'
    assert_not_equal user.projects, ds.projects
    assert !(ds.free_for_members? || ds.free_for_public? || user.has_roles_for?(ds))
    get :download, params: { id: ds.id }
    assert_match(/Access denied/, flash[:error])
  end

  # download page was removed
  # test 'Only datasets with workbook can be downloaded' do
    # login_nadrowski
    # ds = Dataset.create(title: 'a dataset without workbook')
    # get :download, params: { id: ds.id }
    # assert_redirected_to dataset_path(ds)
    # assert_not_nil flash[:error]
    # get :download_page, params: { id: ds.id }
    # assert_redirected_to dataset_path(ds)
    # assert_not_nil flash[:error]
  # end

  # Approval

  test 'approve shows table for all datacolumns' do
    login_nadrowski
    dataset = Dataset.find 5

    get :approve, params: { id: dataset.id }

    assert_success_no_error
    assert_select 'tbody tr', count: dataset.datacolumns.count
  end

  test 'auto approve works' do
    login_nadrowski
    dataset = Dataset.find 8
    @request.env['HTTP_REFERER'] = approve_dataset_url(dataset)
    assert_not_empty dataset.predefined_columns

    orig_exported_excel_invalidated_at = dataset.exported_excel.invalidated_at
    orig_exported_csv_invalidated_at = dataset.exported_csv.invalidated_at

    post :approve_predefined, params: { id: dataset.id }

    assert :success
    assert_empty Dataset.find(dataset.id).predefined_columns
    assert_equal Datacolumn.find(53).import_data_type, 'text'

    assert dataset.reload_exported_excel.invalidated_at > orig_exported_excel_invalidated_at
    assert dataset.reload_exported_csv.invalidated_at > orig_exported_csv_invalidated_at
  end

  test 'quick approve is displaying all select boxes' do
    login_nadrowski
    dataset = Dataset.find 5

    get :approval_quick, params: { id: dataset.id }
    assert_select '.quick-approve-table select', count: dataset.datacolumns.count * 2
  end

  test 'quick approve updates datacolumn properties' do
    login_nadrowski
    dataset = Dataset.find 5
    orig_xls_invalidated_at = dataset.exported_excel.invalidated_at
    orig_csv_invalidated_at = dataset.exported_csv.invalidated_at

    datacolumn_1_id = 33
    datagroup_1_id = 5

    datacolumn_2_id = 35
    datagroup_2_id = 21
    datatype_2 = 'text'

    post :batch_update_columns, params: { id: dataset.id,
                                datacolumn: [{ id: datacolumn_1_id, datagroup: datagroup_1_id },
                                             { id: datacolumn_2_id, import_data_type: datatype_2, datagroup: datagroup_2_id }] }

    assert_equal datagroup_1_id, Datacolumn.find(datacolumn_1_id).datagroup.id
    assert_equal datatype_2, Datacolumn.find(datacolumn_2_id).import_data_type.to_s

    assert_not_equal orig_xls_invalidated_at, dataset.reload_exported_excel.invalidated_at
    assert_not_equal orig_csv_invalidated_at, dataset.reload_exported_csv.invalidated_at

    assert_match /3/, flash[:notice]
  end

  test 'quick approve works only for the dataset columns' do
    login_nadrowski
    dataset = Dataset.find 5
    datacolumn_id = 62
    post :batch_update_columns, params: { id: dataset.id,
                                datacolumn: [{ id: datacolumn_id, import_data_type: 'text' }] }

    assert_not_equal Datacolumn.find(datacolumn_id).import_data_type, 'text'
  end

  test 'destroy should delete a dataset' do
    dataset = Dataset.new(title: 'test')
    dataset.save
    dataset.destroy
    assert dataset.destroyed? == true
  end

  test 'replacing original research data with new file' do
    login_nadrowski
    @dataset = Dataset.first

    old_workbook = @dataset.datacolumns.map(&:columnheader)

    # upload the same workbook again. This should not cause error.
    assert_nothing_raised do
      post :update_workbook,
           params: { id: @dataset.id,
           datafile: {
             file: fixture_file_upload(File.join('test_data_files', 'uploaded', '4_8346952459374534species first test.xls'))
           } }
    end
    assert_nil flash[:error]
    assert_redirected_to dataset_path(@dataset)
    @dataset.reload
    assert_equal Workbook.new(@dataset.current_datafile).headers, old_workbook

    # upload another workbook
    post  :update_workbook,
          params: { id: @dataset.id,
          datafile: {
            file: fixture_file_upload(File.join('test_files_for_uploads', 'SP5_TargetSpecies_CN_final_8_target_spec_kn_-_short.xls'))
          } }

    assert_redirected_to dataset_path(@dataset)

    @dataset.reload
    assert_not_equal Workbook.new(@dataset.current_datafile).headers, old_workbook

    # clean and recover
    @dataset.current_datafile.destroy
  end

  test 'should show new dataset page' do
    login_nadrowski
    get :new
    assert_success_no_error
  end

  test 'upload a workbook with duplicated column headers should fail' do
    login_nadrowski
    uploaded_file = fixture_file_upload(File.join('test_files_for_uploads', 'problem_workbook-1.xls'))

    # create a new dataset using this problematic workbook
    @request.env['HTTP_REFERER'] = new_dataset_path
    post :create_with_datafile, params: { datafile: { file: uploaded_file } }
    assert_redirected_to new_dataset_path
    assert_equal 'Column headers in the raw data sheet must be unique', flash[:error]

    # update workbook of a dataset with this problematic workbook
    @request.env['HTTP_REFERER'] = edit_files_dataset_path(5)
    post :update_workbook, params: { id: 5, datafile: { file: uploaded_file } }
    assert_redirected_to edit_files_dataset_path(5)
    assert_equal 'Column headers in the raw data sheet must be unique', flash[:error]
  end
end
