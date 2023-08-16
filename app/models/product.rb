# frozen_string_literal: true

class Product
  ATTRIBUTES = %i[id title description price discountPercentage rating stock brand category images].freeze
  include ActiveModel::Model

  validates :id, :title, :price, :category, presence: true

  attr_accessor(*ATTRIBUTES)

  def initialize(attributes = {})
    # Ignore passed attributes that are not defined in the ATTRIBUTES array
    super(attributes.symbolize_keys.slice(*ATTRIBUTES))
  end

  def ==(other)
    self.class == other.class &&
      attributes == other.attributes
  end

  def attributes
    instance_values
  end
end