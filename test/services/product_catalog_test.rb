# frozen_string_literal: true

require 'test_helper'

class ProductCatalogTest < ActiveSupport::TestCase
  # A stand-in adapter, which is also the proof that the seam is usable: it
  # implements list/find and nothing else.
  class FakeAdapter
    attr_reader :list_calls, :find_calls

    def initialize(result:)
      @result = result
      @list_calls = 0
      @find_calls = 0
    end

    def list(**)
      @list_calls += 1
      @result
    end

    def find(_id)
      @find_calls += 1
      @result
    end
  end

  setup do
    @original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    ProductCatalog.reset!
  end

  teardown do
    Rails.cache = @original_cache
    ProductCatalog.reset!
  end

  test 'defaults to the dummyjson adapter' do
    assert_instance_of DummyJson::Products, ProductCatalog.adapter
  end

  test 'a different adapter can be substituted without touching callers' do
    product = Product.new(product_payload(title: 'From another catalogue'))
    ProductCatalog.adapter = FakeAdapter.new(result: ProductCatalog::Result.success(products: [product]))

    assert_equal 'From another catalogue', ProductCatalog.list.products.first.title
  end

  test 'a successful list is served from cache on the second call' do
    adapter = FakeAdapter.new(result: ProductCatalog::Result.success(products: [Product.new(product_payload)]))
    ProductCatalog.adapter = adapter

    3.times { ProductCatalog.list }

    assert_equal 1, adapter.list_calls, 'the upstream catalogue should be fetched once, then cached'
  end

  test 'a successful find is cached per product id' do
    adapter = FakeAdapter.new(result: ProductCatalog::Result.success(product: Product.new(product_payload)))
    ProductCatalog.adapter = adapter

    2.times { ProductCatalog.find(1) }
    ProductCatalog.find(2)

    assert_equal 2, adapter.find_calls, 'each distinct id is fetched once'
  end

  # An upstream outage must not be pinned in the cache for the whole TTL.
  test 'failures are never cached' do
    adapter = FakeAdapter.new(result: ProductCatalog::Result.failure('upstream down'))
    ProductCatalog.adapter = adapter

    3.times { ProductCatalog.list }

    assert_equal 3, adapter.list_calls
  end

  test 'results are frozen value objects' do
    assert_predicate ProductCatalog::Result.success, :frozen?
    assert_predicate ProductCatalog::Result.failure('x'), :frozen?
    assert_predicate ProductCatalog::Result.success, :success?
    assert_not_predicate ProductCatalog::Result.failure('x'), :success?
  end
end
