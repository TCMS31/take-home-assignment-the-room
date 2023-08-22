# frozen_string_literal: true

require 'test_helper'

class HealthTest < ActionDispatch::IntegrationTest
  test 'the health endpoint is served without authentication' do
    get health_path

    assert_response :success
    assert_equal 'ok', response.body
  end
end
