# frozen_string_literal: true

module DummyJson
  # ProductCatalog adapter backed by https://dummyjson.com/docs/products.
  class Products < Base
    PATH = 'products'
    PRODUCTS_LIMIT = 100

    def list(limit: PRODUCTS_LIMIT)
      response = get(url_for, query: { limit: })
      return ProductCatalog::Result.failure(response.errors) unless response.success?

      products = Array(response.parsed_body['products']).map { |data| Product.new(data) }
      ProductCatalog::Result.success(products:)
    end

    def find(id)
      response = get(url_for(id))
      return ProductCatalog::Result.failure(response.errors) unless response.success?

      product = Product.new(response.parsed_body)
      return ProductCatalog::Result.failure(ResponseFormatter::DEFAULT_ERROR) unless product.valid?

      ProductCatalog::Result.success(product:)
    end
  end
end
