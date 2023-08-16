# frozen_string_literal: true

# Idempotent development seed data: a handful of accounts and comments spread
# across the first few products in the upstream catalogue. Products themselves
# are never stored locally; they are always fetched from the catalogue API.

USERS = %w[maya devin priya tomas noor].freeze

COMMENTS = {
  1 => [
    ['maya',  'Pigment is good but the brush is a little thin for the price. Still repurchasing.'],
    ['priya', 'Lasted a full day without flaking. The formula is drier than I expected though.'],
    ['tomas', 'Bought this on the discount and it is decent value. Not sure about full price.']
  ],
  2 => [
    ['devin', 'Colour matched the swatch almost exactly, which is rare for an online order.'],
    ['noor',  'Packaging arrived dented. Product itself was fine, so only knocking off a point.']
  ],
  3 => [
    ['priya', 'Lightweight and the coverage builds nicely. Works under sunscreen without pilling.'],
    ['maya',  'Shade range is narrow. Fine for me but I can see it being a problem for others.'],
    ['devin', 'Second bottle now. Consistent between batches, which is what I care about.']
  ],
  6 => [
    ['tomas', 'Scent fades after about four hours. Pleasant while it lasts.'],
    ['noor',  'Great everyday option. I keep one at the office and one at home.']
  ]
}.freeze

users = USERS.index_with { |name| User.find_or_create_by!(username: name) }

COMMENTS.each do |product_id, entries|
  entries.each do |(username, message)|
    user = users.fetch(username)
    next if user.comments.exists?(product_id:, message:)

    user.comments.create!(product_id:, message:)
  end
end

puts "Seeded #{User.count} users and #{Comment.count} comments."
