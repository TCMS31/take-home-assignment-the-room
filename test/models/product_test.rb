# frozen_string_literal: true

require 'test_helper'

class ProductTest < ActiveSupport::TestCase
  test 'maps the camelCase upstream discount key and ignores unknown fields' do
    product = Product.new(product_payload(overrides: { 'somethingNew' => 'ignored' }))

    assert_in_delta(12.96, product.discount_percentage)
    assert_not product.respond_to?(:somethingNew)
  end

  # Expected values derived independently (BigDecimal, half-up to 2dp) rather
  # than by running the implementation.
  DISCOUNT_CASES = [
    { price: 549,   discount: 12.96, discounted: '477.85',  saving: '71.15' },
    { price: 899,   discount: 17.94, discounted: '737.72',  saving: '161.28' },
    { price: 1249,  discount: 11.83, discounted: '1101.24', saving: '147.76' },
    { price: 100,   discount: 0,     discounted: '100.0',   saving: '0.0' },
    { price: 0,     discount: 50,    discounted: '0.0',     saving: '0.0' },
    { price: 9.99,  discount: 5.5,   discounted: '9.44',    saving: '0.55' }
  ].freeze

  DISCOUNT_CASES.each do |row|
    test "discounted price for #{row[:price]} at #{row[:discount]}% is #{row[:discounted]}" do
      product = Product.new(product_payload(
                              overrides: { 'price' => row[:price], 'discountPercentage' => row[:discount] }
                            ))

      assert_equal BigDecimal(row[:discounted]), product.discounted_price
      assert_equal BigDecimal(row[:saving]), product.saving
    end
  end

  test 'discounted? is false when there is no discount' do
    assert_not Product.new(product_payload(overrides: { 'discountPercentage' => 0 })).discounted?
    assert_predicate Product.new(product_payload), :discounted?
  end

  test 'in_stock? reflects the stock count' do
    assert_predicate Product.new(product_payload(overrides: { 'stock' => 1 })), :in_stock?
    assert_not Product.new(product_payload(overrides: { 'stock' => 0 })).in_stock?
  end

  test 'image_url returns the first image or nil' do
    assert_equal 'https://i.dummyjson.com/data/products/1/1.jpg', Product.new(product_payload).image_url
    assert_nil Product.new(product_payload(overrides: { 'images' => [] })).image_url
  end

  test 'requires the fields the views depend on' do
    assert_not Product.new({}).valid?
    assert_predicate Product.new(product_payload), :valid?
  end

  test 'equality is by attributes, not identity' do
    assert_equal Product.new(product_payload), Product.new(product_payload)
    assert_not_equal Product.new(product_payload), Product.new(product_payload(id: 2))
  end
end
