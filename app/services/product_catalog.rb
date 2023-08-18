# frozen_string_literal: true

# The application's port onto an upstream product source.
#
# Controllers depend on this module, never on a concrete HTTP client. Swapping
# dummyjson.com for a real catalogue (or a fake, in tests) is a one-line adapter
# change: `ProductCatalog.adapter = MyCatalog.new`. An adapter must respond to
# `list(limit:)` and `find(id)`, each returning a ProductCatalog::Result.
module ProductCatalog
  CACHE_TTL = 5.minutes

  # Uniform result shape, so callers never branch on exceptions.
  class Result
    attr_reader :products, :product, :error

    def self.success(products: [], product: nil)
      new(success: true, products:, product:)
    end

    def self.failure(error)
      new(success: false, error:)
    end

    def initialize(success:, products: [], product: nil, error: nil)
      @success = success
      @products = products
      @product = product
      @error = error

      freeze
    end

    def success?
      @success
    end
  end

  class << self
    attr_writer :adapter

    def adapter
      @adapter ||= DummyJson::Products.new
    end

    def reset!
      @adapter = nil
    end

    # The catalogue is upstream, read-only and identical for every visitor, so
    # it is cached rather than refetched on each page view. Only successful
    # responses are cached; an upstream outage must not be pinned for CACHE_TTL.
    def list(limit: DummyJson::Products::PRODUCTS_LIMIT)
      fetch("product_catalog/list/#{limit}") { adapter.list(limit:) }
    end

    def find(id)
      fetch("product_catalog/product/#{id}") { adapter.find(id) }
    end

    private

    def fetch(key)
      cached = Rails.cache.read(key)
      return cached if cached

      yield.tap { |result| Rails.cache.write(key, result, expires_in: CACHE_TTL) if result.success? }
    end
  end
end
