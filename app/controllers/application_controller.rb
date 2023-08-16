# frozen_string_literal: true

class ApplicationController < ActionController::Base
  private

  def ensure_logged_in
    return if session[:user_id]

    redirect_to new_session_path, alert: 'Please enter your username first.'
  end
end
