# frozen_string_literal: true

class ApplicationController < ActionController::Base
  helper_method :current_user, :logged_in?

  private

  # The signed-in user, or nil. Memoised per request; `false` distinguishes
  # "looked up and found nothing" from "not looked up yet", so a stale session
  # pointing at a deleted user costs one query rather than one per call.
  def current_user
    return @current_user || nil if defined?(@current_user)

    @current_user = session[:user_id] && User.find_by(id: session[:user_id])
  end

  def logged_in?
    current_user.present?
  end

  def require_login
    return if logged_in?

    reset_session
    redirect_to new_session_path, alert: 'Please enter your username first.'
  end
end
