# frozen_string_literal: true

module DummyJson
  class Products < Base
    PRODUCTS_LIMIT = 100
    PATH = 'products'

    def fetch_all
      @response = request(method: :get, query: { limit: PRODUCTS_LIMIT })
    end

    def fetch
      @url += "/#{@id}"
      @response = request(method: :get)
    end

    def show_product
      Product.new(@response.parsed_body)
    end

    def all_products
      @response.parsed_body['products'].map do |product_data|
        Product.new(product_data)
      end
    end
  end
end
