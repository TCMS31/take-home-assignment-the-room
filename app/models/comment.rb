# frozen_string_literal: true

# A user's comment on an upstream product. Products are not stored locally, so
# product_id is a plain integer reference to the remote catalogue.
class Comment < ApplicationRecord
  MAX_MESSAGE_LENGTH = 2_000

  belongs_to :user

  validates :message, presence: true, length: { maximum: MAX_MESSAGE_LENGTH }
  validates :product_id, presence: true, numericality: { only_integer: true, greater_than: 0 }

  # Comments are always read for one product and always render the author's
  # name, so the association is eager loaded here rather than at each call site.
  scope :for_product, lambda { |product_id|
    where(product_id:).includes(:user).order(created_at: :desc, id: :desc)
  }
end
