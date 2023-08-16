# frozen_string_literal: true

class CommentsController < ApplicationController
  before_action :set_comment, only: %i[edit update destroy]
  before_action :ensure_logged_in

  def new
    @comment = Comment.new
  end

  def edit; end

  def create
    @comment = Comment.new(comment_params)
    if @comment.save
      redirect_to product_path(@comment.product_id), notice: 'Comment successfully created!'
    else
      render :new, alert: 'Failed to create the comment. Please try again.'
    end
  end

  def update
    if @comment.update(comment_params)
      redirect_to product_path(@comment.product_id), notice: 'Comment successfully updated!'
    else
      render :edit, alert: 'Failed to update the comment.'
    end
  end

  def destroy
    if @comment.destroy
      flash[:notice] = 'Comment successfully deleted!'
    else
      flash[:alert] = 'Failed to delete the comment.'
    end

    redirect_to product_path(comment_params[:product_id])
  end

  private

  def set_comment
    @comment = Comment.find(params[:id])
  end

  def comment_params
    params.require(:comment).permit(:user_id, :message, :product_id)
  end
end
