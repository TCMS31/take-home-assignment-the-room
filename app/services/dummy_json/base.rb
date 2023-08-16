# frozen_string_literal: true

module DummyJson
  # Base class for API Wrapper for DummyJson APIs.
  class Base
    attr_reader :url, :path

    def initialize(url: nil, path: '', args: {})
      @path = path
      args.each { |name, value| instance_variable_set("@#{name}", value) }
      @url = url || request_url
    end

    protected

    def request(method: :get, headers: default_headers, timeout: 7, query: {})
      response = HTTParty.send(method, url, headers:, query:, timeout:)

      ResponseFormatter.new(response:)
    end

    def default_headers
      {
        'Accept' => 'application/json'
      }
    end

    def path
      self.class::PATH
    end

    def request_url
      "#{ENV['DUMMY_JSON_BASE_DOMAIN']}/#{path}"
    end
  end
end
