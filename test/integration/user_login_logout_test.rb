# frozen_string_literal: true

require 'test_helper'

class UserLoginTest < ActionDispatch::IntegrationTest
  fixtures :users

  def setup
    @user = User.find_by_login('nadrowski')
  end

  test 'login with wrong password should fail' do
    get datasets_path
    assert_response :success
    post user_session_path, params: { user_session: { login: @user.login, password: 'wrong' } }, headers: { 'HTTP_REFERER' => datasets_path }
    assert_redirected_to datasets_path
    follow_redirect!
    assert_match /not/, flash[:error]
  end

  test 'login with correct password should pass' do
    get datasets_path
    assert_response :success
    post user_session_path, params: { user_session: { login: @user.login, password: 'test' } }, headers: { 'HTTP_REFERER' => datasets_path }
    assert_redirected_to datasets_path
    follow_redirect!
    assert_equal 'Login successful!', flash[:notice]
  end

  test 'only logged-in users can visit forbidden page' do
    get current_cart_path
    assert_redirected_to root_path

    post user_session_path, params: { user_session: { login: @user.login, password: 'test' } }
    get current_cart_path
    assert_response :success
  end
  test 'logout should redirect to welcome page' do
    post user_session_path, params: { user_session: { login: @user.login, password: 'test' } }
    get current_cart_url

    post logout_path, params: { method: :delete }
    assert_redirected_to root_url
    follow_redirect!
    assert_select 'h2', /BEFdata/
  end
end
