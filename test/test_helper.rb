# frozen_string_literal: true

ENV['RAILS_ENV'] ||= 'test'
ENV['DUMMY_JSON_BASE_DOMAIN'] ||= 'https://dummyjson.com'

require_relative '../config/environment'
require 'rails/test_help'
require 'webmock/minitest'

# No test in this suite may reach the network. WebMock raises on any request
# that is not explicitly stubbed, which keeps the upstream API out of CI.
WebMock.disable_net_connect!(allow_localhost: false)

module ActiveSupport
  class TestCase
    parallelize(workers: 1)
    fixtures :all

    private

    # Minimal product payload matching the shape dummyjson.com returns.
    def product_payload(id: 1, title: 'iPhone 9', overrides: {})
      {
        'id' => id,
        'title' => title,
        'description' => 'An apple mobile which is nothing like apple',
        'price' => 549,
        'discountPercentage' => 12.96,
        'rating' => 4.69,
        'stock' => 94,
        'brand' => 'Apple',
        'category' => 'smartphones',
        'images' => ["https://i.dummyjson.com/data/products/#{id}/1.jpg"]
      }.merge(overrides)
    end

    def stub_products_index(products: [product_payload], status: 200)
      stub_request(:get, "#{ENV.fetch('DUMMY_JSON_BASE_DOMAIN')}/products")
        .with(query: { 'limit' => DummyJson::Products::PRODUCTS_LIMIT })
        .to_return(
          status:,
          body: { 'products' => products, 'total' => products.size }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    def stub_product_show(id: 1, product: nil, status: 200, body: nil)
      stub_request(:get, "#{ENV.fetch('DUMMY_JSON_BASE_DOMAIN')}/products/#{id}")
        .to_return(
          status:,
          body: body || (product || product_payload(id:)).to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end
  end
end

module ActionDispatch
  class IntegrationTest
    # The app authenticates by username only; this mirrors SessionsController.
    def sign_in_as(user)
      post sessions_path, params: { username: user.username }
      user
    end
  end
end
