# frozen_string_literal: true

require 'test_helper'

class CommentsFlowTest < ActionDispatch::IntegrationTest
  setup do
    @alice = users(:alice)
    sign_in_as(@alice)
    stub_product_show(id: 1)
  end

  test 'a user can post a comment on a product' do
    assert_difference 'Comment.count', 1 do
      post comments_path, params: { comment: { product_id: 1, message: 'Sturdier than I expected.' } }
    end

    comment = Comment.order(:id).last

    assert_equal @alice.id, comment.user_id
    assert_equal 'Sturdier than I expected.', comment.message
    assert_redirected_to product_path(1)
    assert_equal 'Comment successfully created!', flash[:notice]
  end

  test 'an empty comment is rejected and re-renders the form' do
    assert_no_difference 'Comment.count' do
      post comments_path, params: { comment: { product_id: 1, message: '   ' } }
    end

    assert_response :unprocessable_entity
    assert_select 'form'
  end

  test 'a user can edit their own comment' do
    comment = comments(:alice_on_iphone)

    get edit_comment_path(comment)

    assert_response :success

    patch comment_path(comment), params: { comment: { message: 'Updated after a month of use.' } }

    assert_equal 'Updated after a month of use.', comment.reload.message
    assert_redirected_to product_path(1)
  end

  # Regression: destroy redirected using comment_params, which called
  # params.require(:comment). A DELETE carries no comment param, so the record
  # was deleted and the response was then a 400 ParameterMissing error.
  test 'deleting a comment redirects to the product instead of raising' do
    comment = comments(:alice_on_iphone)

    assert_difference 'Comment.count', -1 do
      delete comment_path(comment)
    end

    assert_redirected_to product_path(1)
    assert_equal 'Comment successfully deleted!', flash[:notice]
    follow_redirect!

    assert_response :success
  end

  test 'updating a comment cannot move it to another product' do
    comment = comments(:alice_on_iphone)

    patch comment_path(comment), params: { comment: { message: 'still here', product_id: 42 } }

    assert_equal 1, comment.reload.product_id
  end

  test 'the new comment form is scoped to the signed in user' do
    get new_comment_path(product_id: 1)

    assert_response :success
    assert_select 'input[name="comment[product_id]"][value="1"]'
    assert_select 'input[name="comment[user_id]"]', false,
                  'the form must not expose user_id as an input'
  end

  test 'the product page does not expose a user id field' do
    get product_path(1)

    assert_response :success
    assert_select 'input[name="comment[user_id]"]', false
  end
end
