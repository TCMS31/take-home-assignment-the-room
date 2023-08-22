# frozen_string_literal: true

require 'test_helper'

class ProductsTest < ActionDispatch::IntegrationTest
  setup { sign_in_as(users(:alice)) }

  test 'index lists products from the catalogue' do
    stub_products_index(products: [product_payload(id: 1), product_payload(id: 2, title: 'iPhone X')])

    get products_path

    assert_response :success
    assert_select '.product-card', 2
    assert_select '.product-card__title', text: 'iPhone 9'
  end

  test 'index degrades to an empty state when the catalogue is unavailable' do
    stub_products_index(status: 500)

    get products_path

    assert_response :success
    assert_select '.empty-state'
    assert_select '.alert-danger'
  end

  # The controller used to call a bare JSON.parse on the response body, so an
  # HTML error page from upstream produced a 500 rather than this message.
  test 'index survives a non-JSON response from upstream' do
    stub_request(:get, "#{DummyJson::Base.base_domain}/products")
      .with(query: hash_including({}))
      .to_return(status: 502, body: '<html>Bad Gateway</html>')

    get products_path

    assert_response :success
    assert_select '.empty-state'
  end

  test 'show renders the product and its comments' do
    stub_product_show(id: 1)

    get product_path(1)

    assert_response :success
    assert_select 'h1', text: 'iPhone 9'
    assert_select '.comment', 2
  end

  test 'show displays the discounted price, not the list price' do
    stub_product_show(id: 1, product: product_payload(overrides: { 'price' => 549, 'discountPercentage' => 12.96 }))

    get product_path(1)

    assert_select '.product-detail__price', text: '$477.85'
    assert_select '.product-detail__was', text: '$549.00'
  end

  test 'show redirects with the upstream message when the product is missing' do
    stub_product_show(id: 999, status: 404, body: { 'message' => "Product with id '999' not found" }.to_json)

    get product_path(999)

    assert_redirected_to products_path
    assert_equal "Product with id '999' not found", flash[:alert]
  end

  test 'products require a signed in user' do
    delete logout_path

    get products_path

    assert_redirected_to new_session_path

    get product_path(1)

    assert_redirected_to new_session_path
  end

  # Regression: the comments partial renders comment.user.username, and the
  # controller did not eager load the association, so each comment cost a query.
  test 'the comment list does not issue a query per comment' do
    stub_product_show(id: 1)
    5.times { |i| users(:bob).comments.create!(product_id: 1, message: "comment #{i}") }

    queries = []
    counter = ->(_n, _s, _f, _i, payload) { queries << payload[:sql] unless payload[:name] == 'SCHEMA' }

    ActiveSupport::Notifications.subscribed(counter, 'sql.active_record') do
      get product_path(1)
    end

    user_queries = queries.count { |sql| sql.include?('"users"') }

    assert_operator user_queries, :<=, 2,
                    "expected users to be eager loaded, saw #{user_queries} user queries for 7 comments"
  end
end
