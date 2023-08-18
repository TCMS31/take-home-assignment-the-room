# frozen_string_literal: true

require 'json'

module DummyJson
  # Wraps an HTTP response in a uniform, always-safe shape.
  #
  # The previous version parsed the body in the constructor with a bare
  # JSON.parse, so any non-JSON response (an HTML error page, an empty body, a
  # proxy timeout) raised out of the service and 500'd the request instead of
  # reaching the controller's error branch.
  class ResponseFormatter
    DEFAULT_ERROR = 'Something went wrong in loading products'

    attr_reader :status, :body, :parsed_body, :errors

    def initialize(response:, body: nil)
      @status = response&.code.to_i
      @body = body || response&.body
      @parsed_body = parse_body
      @errors = build_errors

      freeze
    end

    # Builds a failure result for transport-level problems, where there is no
    # HTTP response at all.
    def self.failure(message: DEFAULT_ERROR, status: 0)
      allocate.tap do |formatter|
        formatter.instance_variable_set(:@status, status)
        formatter.instance_variable_set(:@body, nil)
        formatter.instance_variable_set(:@parsed_body, nil)
        formatter.instance_variable_set(:@errors, message)
        formatter.freeze
      end
    end

    def success?
      (200..299).cover?(status) && parsed_body.is_a?(Hash)
    end

    private

    def parse_body
      return nil if body.blank?

      JSON.parse(body)
    rescue JSON::ParserError
      nil
    end

    def build_errors
      return '' if success?

      upstream_errors.presence || DEFAULT_ERROR
    end

    def upstream_errors
      return nil unless parsed_body.is_a?(Hash)

      # dummyjson returns {"message": "..."} for a missing product.
      return parsed_body['message'] if parsed_body['message'].present?

      Array(parsed_body['errors']).filter_map { |error| error['product'] }.join(', ')
    end
  end
end
