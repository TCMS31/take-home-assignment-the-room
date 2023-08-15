# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '~> 3.1.0'

gem 'bootsnap', require: false
gem 'importmap-rails'
gem 'jbuilder'
gem 'puma', '~> 5.0'
gem 'rails', '~> 7.0.7'
gem 'sprockets-rails'
gem 'stimulus-rails'
gem 'turbo-rails'
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]

gem 'bootstrap', '~> 5.1.0'
gem 'httparty'

# Pinned: json 3.x breaks Rails 7.0 parameter parsing and `render json:`.
gem 'json', '~> 2.6'

# PostgreSQL is the database for Docker, staging and production.
gem 'pg', '~> 1.1'

group :development, :test do
  gem 'debug', platforms: %i[mri mingw x64_mingw]
  gem 'dotenv-rails'
  # Local fallback database so the suite runs without a Postgres server.
  gem 'sqlite3', '~> 1.6'
end

group :development do
  gem 'rubocop', '~> 1.50', require: false
  gem 'rubocop-minitest', require: false
  gem 'rubocop-rails', require: false
  gem 'web-console'
end

group :test do
  gem 'rails-controller-testing'
  gem 'webmock', '~> 3.18'
end
