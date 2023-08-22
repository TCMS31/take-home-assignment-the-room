# frozen_string_literal: true

require 'test_helper'

class CommentTest < ActiveSupport::TestCase
  test 'requires a message' do
    comment = users(:alice).comments.new(product_id: 1, message: '  ')

    assert_not comment.valid?
    assert_includes comment.errors[:message], "can't be blank"
  end

  test 'requires a positive integer product id' do
    assert_not users(:alice).comments.new(message: 'hi').valid?
    assert_not users(:alice).comments.new(message: 'hi', product_id: 0).valid?
    assert_predicate users(:alice).comments.new(message: 'hi', product_id: 3), :valid?
  end

  test 'rejects a message beyond the maximum length' do
    comment = users(:alice).comments.new(product_id: 1, message: 'a' * (Comment::MAX_MESSAGE_LENGTH + 1))

    assert_not comment.valid?
  end

  test 'requires a user' do
    assert_not Comment.new(product_id: 1, message: 'orphan').valid?
  end

  test 'for_product returns only that product, newest first' do
    other = users(:alice).comments.create!(product_id: 99, message: 'different product')
    newest = users(:alice).comments.create!(product_id: 1, message: 'newest')

    result = Comment.for_product(1)

    assert_not_includes result, other
    assert_equal newest, result.first
    assert_equal 3, result.size
  end

  test 'deleting a user deletes their comments' do
    assert_difference 'Comment.count', -1 do
      users(:alice).destroy
    end
  end
end
