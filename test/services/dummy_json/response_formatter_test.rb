# frozen_string_literal: true

require 'test_helper'

module DummyJson
  class ResponseFormatterTest < ActiveSupport::TestCase
    Fake = Struct.new(:code, :body)

    test 'a 200 with JSON is a success' do
      formatter = ResponseFormatter.new(response: Fake.new(200, { 'products' => [] }.to_json))

      assert_predicate formatter, :success?
      assert_equal({ 'products' => [] }, formatter.parsed_body)
      assert_equal '', formatter.errors
    end

    # Regression: the original parsed in the constructor with a bare JSON.parse,
    # so an HTML error page raised JSON::ParserError out of the service and
    # 500'd the request instead of reaching the controller's error branch.
    test 'a non-JSON body is a failure rather than an exception' do
      formatter = ResponseFormatter.new(response: Fake.new(502, '<html>Bad Gateway</html>'))

      assert_not_predicate formatter, :success?
      assert_nil formatter.parsed_body
      assert_equal ResponseFormatter::DEFAULT_ERROR, formatter.errors
    end

    test 'a 200 carrying a non-JSON body is still a failure' do
      formatter = ResponseFormatter.new(response: Fake.new(200, 'not json at all'))

      assert_not_predicate formatter, :success?
    end

    test 'an empty body is a failure rather than an exception' do
      assert_not_predicate ResponseFormatter.new(response: Fake.new(204, '')), :success?
      assert_not_predicate ResponseFormatter.new(response: Fake.new(200, nil)), :success?
    end

    test 'surfaces the upstream message for a missing product' do
      formatter = ResponseFormatter.new(
        response: Fake.new(404, { 'message' => "Product with id '999' not found" }.to_json)
      )

      assert_not_predicate formatter, :success?
      assert_equal "Product with id '999' not found", formatter.errors
    end

    test 'joins a list of upstream errors' do
      body = { 'errors' => [{ 'product' => 'out of range' }, { 'product' => 'bad id' }] }.to_json
      formatter = ResponseFormatter.new(response: Fake.new(422, body))

      assert_equal 'out of range, bad id', formatter.errors
    end

    test 'falls back to the default error when the payload explains nothing' do
      formatter = ResponseFormatter.new(response: Fake.new(500, { 'unexpected' => true }.to_json))

      assert_equal ResponseFormatter::DEFAULT_ERROR, formatter.errors
    end

    test 'failure builds a result with no HTTP response at all' do
      formatter = ResponseFormatter.failure

      assert_not_predicate formatter, :success?
      assert_equal 0, formatter.status
      assert_equal ResponseFormatter::DEFAULT_ERROR, formatter.errors
    end

    test 'is frozen so a result cannot be mutated after the fact' do
      assert_predicate ResponseFormatter.new(response: Fake.new(200, '{}')), :frozen?
    end
  end
end
