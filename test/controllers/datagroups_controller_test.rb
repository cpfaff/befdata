# frozen_string_literal: true

require 'test_helper'

class DatagroupsControllerTest < ActionController::TestCase
  setup :activate_authlogic

  test 'show index of datagroups' do
    login_nadrowski

    get :index

    assert_success_no_error
  end

  test 'show datagroup' do
    login_nadrowski

    get :show, params: { id: Datagroup.first.id }

    assert_success_no_error
  end

  test 'show datagroup cvs upload' do
    login_nadrowski

    get :upload_categories, params: { id: Datagroup.first.id }

    assert_success_no_error
  end

  test 'upload updated categories cvs' do
    login_nadrowski
    request.env['HTTP_REFERER'] = root_url
    f = fixture_file_upload(File.join('test_files_for_uploads', 'datagroup_22_categories_update.csv.txt'))

    post :update_categories, params: { id: 22, csvfile: { file: f } }

    assert_success_no_error
  end

  # TODO: The functionality seems to be broken
  # test 'dont accept duplicate categories short via cvs' do
  # login_nadrowski
  # request.env['HTTP_REFERER'] = root_url
  # f = fixture_file_upload(File.join('test_files_for_uploads', 'datagroup_22_categories_faulty.csv.txt'))

  # post :update_categories, params: { id: 22, csvfile: { file: f } }

  # assert :success
  # assert_match /.*unique.*/, flash[:error]
  # end

  test 'merge categories via csv' do
    login_nadrowski
    f = fixture_file_upload(File.join('test_files_for_uploads', 'datagroup_22_categories_merge.csv.txt'))

    cat_count_old = Datagroup.find(22).categories.count

    post :update_categories, params: { id: 22, csvfile: { file: f } }
    cat_count_new = Datagroup.find(22).categories.count

    assert_success_no_error
    assert cat_count_new = (cat_count_old - 3)
  end
end
