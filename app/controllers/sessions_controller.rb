# frozen_string_literal: true

class SessionsController < ApplicationController
  def new
    redirect_to products_path if logged_in?
  end

  def create
    user = User.for_login(params[:username])

    return render_sign_in_error(user) unless user.persisted? || user.save

    reset_session
    session[:user_id] = user.id
    redirect_to products_path, notice: 'Logged in successfully!'
  end

  def destroy
    reset_session
    redirect_to new_session_path, notice: 'Logged out successfully!'
  end

  private

  def render_sign_in_error(user)
    flash.now[:alert] = user.errors.full_messages.to_sentence
    render :new, status: :unprocessable_entity
  end
end
