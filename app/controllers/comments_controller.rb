# frozen_string_literal: true

class CommentsController < ApplicationController
  # Order matters: authenticate before touching the database, so a signed-out
  # request is redirected rather than raising on a record lookup.
  before_action :require_login
  before_action :set_comment, only: %i[edit update destroy]

  def new
    @comment = current_user.comments.new(product_id: params[:product_id])
  end

  def edit; end

  def create
    @comment = current_user.comments.new(create_params)

    if @comment.save
      redirect_to product_path(@comment.product_id), notice: 'Comment successfully created!'
    else
      flash.now[:alert] = @comment.errors.full_messages.to_sentence
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @comment.update(update_params)
      redirect_to product_path(@comment.product_id), notice: 'Comment successfully updated!'
    else
      flash.now[:alert] = @comment.errors.full_messages.to_sentence
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    product_id = @comment.product_id
    @comment.destroy

    redirect_to product_path(product_id), notice: 'Comment successfully deleted!'
  end

  private

  # Scoped to the signed-in user: a comment belonging to anyone else is simply
  # not found, so edit/update/destroy cannot reach another user's record.
  def set_comment
    @comment = current_user.comments.find_by(id: params[:id])
    return if @comment

    redirect_to products_path, alert: 'Comment not found.'
  end

  # user_id is never accepted from the request; it comes from the session via
  # `current_user.comments`. Permitting it would allow both forging a comment as
  # another user and transferring an existing comment to them.
  def create_params
    params.require(:comment).permit(:message, :product_id)
  end

  # A comment never changes the product it belongs to.
  def update_params
    params.require(:comment).permit(:message)
  end
end
