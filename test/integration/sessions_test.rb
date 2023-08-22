# frozen_string_literal: true

require 'test_helper'

class SessionsTest < ActionDispatch::IntegrationTest
  test 'signing in with a new username creates the account' do
    assert_difference 'User.count', 1 do
      post sessions_path, params: { username: 'carol' }
    end

    assert_redirected_to products_path
    assert_equal 'carol', User.order(:id).last.username
  end

  test 'signing in with an existing username reuses the account' do
    assert_no_difference 'User.count' do
      post sessions_path, params: { username: 'alice' }
    end

    assert_equal users(:alice).id, session[:user_id]
  end

  test 'username lookup is case and whitespace insensitive' do
    assert_no_difference 'User.count' do
      post sessions_path, params: { username: '  ALICE  ' }
    end

    assert_equal users(:alice).id, session[:user_id]
  end

  test 'a blank username is rejected' do
    assert_no_difference 'User.count' do
      post sessions_path, params: { username: '   ' }
    end

    assert_response :unprocessable_entity
    assert_nil session[:user_id]
  end

  test 'an over-long username is rejected' do
    post sessions_path, params: { username: 'a' * (User::MAX_USERNAME_LENGTH + 1) }

    assert_response :unprocessable_entity
  end

  test 'signing out clears the session' do
    sign_in_as(users(:alice))

    assert_equal users(:alice).id, session[:user_id]

    delete logout_path

    assert_nil session[:user_id]
    assert_redirected_to new_session_path
  end

  test 'the sign in page redirects a user who is already signed in' do
    sign_in_as(users(:alice))

    get new_session_path

    assert_redirected_to products_path
  end

  test 'a session pointing at a deleted user is treated as signed out' do
    sign_in_as(users(:alice))
    users(:alice).destroy

    get products_path

    assert_redirected_to new_session_path
  end
end
