# frozen_string_literal: true

module DummyJson
  # Thin HTTP wrapper for the dummyjson.com API.
  #
  # Every transport failure is converted into a ResponseFormatter failure so
  # callers only ever deal with one result shape and never see an exception.
  class Base
    DEFAULT_BASE_DOMAIN = 'https://dummyjson.com'
    DEFAULT_TIMEOUT = 7

    TRANSPORT_ERRORS = [
      HTTParty::Error,
      Net::OpenTimeout,
      Net::ReadTimeout,
      SocketError,
      Errno::ECONNREFUSED,
      Errno::EHOSTUNREACH,
      OpenSSL::SSL::SSLError
    ].freeze

    def self.base_domain
      ENV['DUMMY_JSON_BASE_DOMAIN'].presence || DEFAULT_BASE_DOMAIN
    end

    protected

    # Builds a URL per call rather than mutating shared state, so an instance
    # can be reused without the path accumulating segments.
    def url_for(*segments)
      [self.class.base_domain.chomp('/'), self.class::PATH, *segments].compact.join('/')
    end

    def get(url, query: {})
      response = HTTParty.get(url, headers: default_headers, query:, timeout: DEFAULT_TIMEOUT)
      ResponseFormatter.new(response:)
    rescue *TRANSPORT_ERRORS => e
      Rails.logger.warn("[DummyJson] #{url} failed: #{e.class}: #{e.message}")
      ResponseFormatter.failure
    end

    def default_headers
      { 'Accept' => 'application/json' }
    end
  end
end
