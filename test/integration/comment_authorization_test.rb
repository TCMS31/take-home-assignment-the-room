# frozen_string_literal: true

require 'test_helper'

# Cross-user access control on every mutating comment endpoint.
class CommentAuthorizationTest < ActionDispatch::IntegrationTest
  setup do
    @alice = users(:alice)
    @bob = users(:bob)
    @alices_comment = comments(:alice_on_iphone)
    stub_product_show(id: 1)
  end

  test 'a user cannot open the edit form for another users comment' do
    sign_in_as(@bob)

    get edit_comment_path(@alices_comment)

    assert_redirected_to products_path
    assert_equal 'Comment not found.', flash[:alert]
  end

  test 'a user cannot update another users comment' do
    sign_in_as(@bob)
    original = @alices_comment.message

    patch comment_path(@alices_comment), params: { comment: { message: 'defaced by bob' } }

    assert_redirected_to products_path
    assert_equal original, @alices_comment.reload.message
  end

  test 'a user cannot destroy another users comment' do
    sign_in_as(@bob)

    assert_no_difference 'Comment.count' do
      delete comment_path(@alices_comment)
    end

    assert_redirected_to products_path
    assert Comment.exists?(@alices_comment.id)
  end

  test 'a user cannot forge a comment as another user' do
    sign_in_as(@bob)

    post comments_path, params: { comment: { product_id: 1, message: 'not really alice', user_id: @alice.id } }

    assert_equal @bob.id, Comment.order(:id).last.user_id,
                 'user_id must come from the session, never from request parameters'
  end

  test 'a user cannot transfer ownership of their comment to someone else' do
    sign_in_as(@bob)
    bobs_comment = comments(:bob_on_iphone)

    patch comment_path(bobs_comment), params: { comment: { message: 'still mine', user_id: @alice.id } }

    assert_equal @bob.id, bobs_comment.reload.user_id,
                 'user_id must not be assignable through mass assignment'
  end

  test 'signed out users are redirected to login rather than hitting the database' do
    get edit_comment_path(@alices_comment)

    assert_redirected_to new_session_path
  end
end
