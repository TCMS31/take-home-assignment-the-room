# frozen_string_literal: true

require 'test_helper'

module DummyJson
  class ProductsTest < ActiveSupport::TestCase
    setup { @adapter = Products.new }

    test 'list returns Product objects' do
      stub_products_index(products: [product_payload(id: 1), product_payload(id: 2, title: 'iPhone X')])

      result = @adapter.list

      assert_predicate result, :success?
      assert_equal ['iPhone 9', 'iPhone X'], result.products.map(&:title)
      assert(result.products.all?(Product))
    end

    test 'list reports the upstream error instead of raising' do
      stub_products_index(status: 500)

      result = @adapter.list

      assert_not_predicate result, :success?
      assert_equal ResponseFormatter::DEFAULT_ERROR, result.error
      assert_empty result.products
    end

    test 'find returns a single product' do
      stub_product_show(id: 7, product: product_payload(id: 7, title: 'Samsung Universe 9'))

      result = @adapter.find(7)

      assert_predicate result, :success?
      assert_equal 'Samsung Universe 9', result.product.title
    end

    test 'find surfaces a 404 as a failure' do
      stub_product_show(id: 999, status: 404, body: { 'message' => "Product with id '999' not found" }.to_json)

      result = @adapter.find(999)

      assert_not_predicate result, :success?
      assert_equal "Product with id '999' not found", result.error
    end

    test 'find rejects a payload missing the fields the views need' do
      stub_product_show(id: 5, body: { 'id' => 5 }.to_json)

      assert_not_predicate @adapter.find(5), :success?
    end

    # Regression: fetch used to do `@url += "/#{id}"`, so a reused instance
    # accumulated path segments (/products/1/2).
    test 'reusing an adapter does not accumulate path segments' do
      stub_product_show(id: 1)
      stub_product_show(id: 2, product: product_payload(id: 2))

      assert_predicate @adapter.find(1), :success?
      assert_predicate @adapter.find(2), :success?

      assert_requested :get, "#{Base.base_domain}/products/2", times: 1
    end

    test 'a network timeout becomes a failure result, not an exception' do
      stub_request(:get, "#{Base.base_domain}/products").with(query: hash_including({}))
                                                        .to_timeout

      result = nil
      assert_nothing_raised { result = @adapter.list }
      assert_not_predicate result, :success?
      assert_equal ResponseFormatter::DEFAULT_ERROR, result.error
    end

    test 'a refused connection becomes a failure result' do
      stub_request(:get, "#{Base.base_domain}/products/3").to_raise(Errno::ECONNREFUSED)

      result = nil
      assert_nothing_raised { result = @adapter.find(3) }
      assert_not_predicate result, :success?
    end

    test 'base domain falls back to the public API when the env var is unset' do
      with_env('DUMMY_JSON_BASE_DOMAIN' => nil) do
        assert_equal Base::DEFAULT_BASE_DOMAIN, Base.base_domain
      end
    end

    private

    def with_env(values)
      original = values.keys.index_with { |key| ENV.fetch(key, nil) }
      values.each { |key, value| ENV[key] = value }
      yield
    ensure
      original.each { |key, value| ENV[key] = value }
    end
  end
end
