# frozen_string_literal: true

# A product from the upstream catalogue. Not persisted: the brief keeps product
# data in the remote API and only comments in our database.
class Product
  include ActiveModel::Model

  ATTRIBUTES = %i[
    id title description price discount_percentage rating stock brand category images
  ].freeze

  # The upstream API uses camelCase for this one field.
  API_KEY_ALIASES = { discountPercentage: :discount_percentage }.freeze

  attr_accessor(*ATTRIBUTES)

  validates :id, :title, :price, :category, presence: true

  def initialize(attributes = {})
    super(self.class.normalize_attributes(attributes))
  end

  # Maps upstream keys onto our attribute names and drops anything unknown, so
  # a new field appearing upstream cannot break object construction.
  def self.normalize_attributes(attributes)
    attributes.to_h.symbolize_keys
              .transform_keys { |key| API_KEY_ALIASES.fetch(key, key) }
              .slice(*ATTRIBUTES)
  end

  def attributes
    ATTRIBUTES.index_with { |name| public_send(name) }
  end

  def discounted?
    discount_percentage.to_f.positive?
  end

  # Upstream `price` is the list price; `discountPercentage` is the reduction
  # applied to it. Computed in BigDecimal so money never rides on float error.
  def discounted_price
    return nil if price.nil?

    rate = BigDecimal(discount_percentage.presence.to_s.presence || '0')
    (BigDecimal(price.to_s) * (1 - (rate / 100))).round(2)
  end

  def saving
    return nil if price.nil?

    (BigDecimal(price.to_s) - discounted_price).round(2)
  end

  def in_stock?
    stock.to_i.positive?
  end

  def image_url
    Array(images).first.presence
  end

  def ==(other)
    other.is_a?(self.class) && attributes == other.attributes
  end
  alias eql? ==

  delegate :hash, to: :attributes
end
