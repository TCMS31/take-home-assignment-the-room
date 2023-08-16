# frozen_string_literal: true

require 'json'

module DummyJson
  # Format response from DummyJson APIs.
  class ResponseFormatter
    attr_reader :status, :body, :errors, :response

    def initialize(response:, body: nil)
      @status = response.code.to_i
      @body = body || response.body || response['body']
      @response = parsed_body
      @errors = parse_errors

      freeze
    end

    def success?
      (200..299).cover?(status)
    end

    def parsed_body
      JSON.parse(body)
    end

    def parse_errors
      return '' if success?

      if response&.key?('errors') && response&.dig('errors')
        response['errors'].map { |error| error['product'] }.join(', ')
      else
        'Something went wrong in loading products'
      end
    end
  end
end
