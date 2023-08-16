# frozen_string_literal: true

# An account identified by username alone. The brief specifies no password, so
# sign-in creates the account on first use.
class User < ApplicationRecord
  MAX_USERNAME_LENGTH = 50

  has_many :comments, dependent: :destroy

  before_validation :normalize_username

  validates :username,
            presence: true,
            length: { maximum: MAX_USERNAME_LENGTH },
            uniqueness: { case_sensitive: false }

  # LOWER() rather than ILIKE so the lookup behaves identically on SQLite and
  # PostgreSQL. Matches the case-insensitive uniqueness validation above.
  scope :with_username, lambda { |username|
    where('LOWER(username) = ?', username.to_s.strip.downcase)
  }

  # Sign-in is by username alone, so an unknown name is a new account.
  def self.for_login(username)
    with_username(username).first || new(username:)
  end

  private

  def normalize_username
    self.username = username.to_s.strip
  end
end
