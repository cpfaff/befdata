# frozen_string_literal: true

require 'test_helper'

class FreeformatsControllerTest < ActionController::TestCase
  setup :activate_authlogic

  test 'download freeformat file should work' do
    login_nadrowski

    get :download, params: { id: Freeformat.first }

    assert_success_no_error
  end

  test 'add freeformat to dataset and change it and delete it' do
    login_nadrowski
    dataset = Dataset.first
    f = fixture_file_upload(File.join('test_files_for_uploads', 'empty_test_file.txt'))
    request.env['HTTP_REFERER'] = edit_dataset_path dataset

    post :create, params: { freeformat: { file: f }, freeformattable_id: dataset.id, freeformattable_type: dataset.class.to_s }

    freeformat = dataset.freeformats.select { |ff| ff.file_file_name == 'empty_test_file.txt' }.first
    assert_not_nil freeformat
    assert_equal freeformat.freeformattable, dataset

    # and now change it...
    f = fixture_file_upload(File.join('test_files_for_uploads', 'empty_freeformat_file.ppt'))

    put :update, params: { id: freeformat.id, freeformat: { file: f } }

    assert Freeformat.find(freeformat.id).file_file_name == 'empty_freeformat_file.ppt'
    assert_empty Freeformat.select { |ff| ff.file_file_name == 'empty_test_file.txt' }

    # now delete it
    get :destroy, params: { id: freeformat.id }

    assert !Freeformat.exists?(freeformat.id)
  end

  test 'adding and deleting file on paperproposal' do
    login_and_load_paperproposal 'nadrowski', 'Step 1 Paperproposal'
    request.env['HTTP_REFERER'] = edit_paperproposal_path(@paperproposal)
    f = fixture_file_upload(File.join('test_files_for_uploads', 'empty_test_file.txt'))

    post :create, params: { freeformat: { file: f },
                            freeformattable_id: @paperproposal.id, freeformattable_type: @paperproposal.class.to_s }
    freeformat = @paperproposal.freeformats.select { |ff| ff.file_file_name == 'empty_test_file.txt' }.first

    assert_redirected_to edit_paperproposal_path(@paperproposal)
    assert_equal freeformat.freeformattable, @paperproposal

    get :destroy, params: { id: freeformat.id }

    assert !Freeformat.exists?(freeformat.id)
  end

  test 'freeformat download error message if inappropriate rights' do
    ds = Dataset.find_by_title 'Unit tests'
    f = ds.freeformats.first
    user = User.find_by_login 'Pidata'

    login_user user.login
    @request.env['HTTP_REFERER'] = root_url

    assert ds.freeformats.count > 0
    assert !ds.free_for?(user) && !user.has_roles_for?(ds) && !user.has_role?(:admin) && !user.has_role?(:data_admin)

    get :download, params: { id: f.id }
    assert_match /.*Access denied.*/, flash[:error]
  end

  test 'freeformat download failure if dataset not for public' do
    @request.env['HTTP_REFERER'] = root_url
    ds = Dataset.find_by_title 'Unit tests'
    f = ds.freeformats.first
    get :download, params: { id: f.id }

    assert_match /.*Access denied.*/, flash[:error]
  end

  test 'dataset owner my download freeformat' do
    login_user 'Phdstudentnutrientcycling'
    ds = Dataset.find_by_title 'Unit tests'
    f = ds.freeformats.first

    get :download, params: { id: f.id }

    assert_success_no_error
  end

  # TODO: this has to be changed with better acl9 for paperproposal
  test 'public user may not download freeformat from paperproposal' do
    @request.env['HTTP_REFERER'] = root_url
    f = Freeformat.find_by_file_file_name '8346952459374534ppNutrientCyclingtest.doc'

    get :download, params: { id: f.id }

    assert_match /.*Access denied.*/, flash[:error]
  end

  # test 'logged in user may download freeformat from paperproposal' do
  # login_user 'Phdstudentnutrientcycling'
  # f = Freeformat.find_by_file_file_name '8346952459374534ppNutrientCyclingtest.doc'

  # get :download, params: { id: f.id }

  # assert_success_no_error
  # end
end
