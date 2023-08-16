# frozen_string_literal: true

# Comments are only ever read by product (Comment.for_product), but the original
# schema indexed user_id alone, so every product page ran a sequential scan of
# the comments table.
class AddIndexToCommentsProductId < ActiveRecord::Migration[7.0]
  def change
    add_index :comments, %i[product_id created_at]
  end
end
