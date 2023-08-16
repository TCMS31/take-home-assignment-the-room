# frozen_string_literal: true

class SessionsController < ApplicationController
  def new; end

  def create
    username = params[:username]
    user = User.find_or_create_by(username:)
    if user
      session[:user_id] = user.id
      redirect_to products_path, notice: 'Logged in successfully!'
    else
      flash.now[:alert] = 'Error creating or logging in user.'
      render :new
    end
  end

  def destroy
    session[:user_id] = nil
    redirect_to new_session_path, notice: 'Logged out successfully!'
  end
end
