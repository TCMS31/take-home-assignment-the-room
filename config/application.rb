# frozen_string_literal: true

require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module TakeHome
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    # Business logic lives in app/services; autoload it eagerly in production.
    config.eager_load_paths << root.join('app/services')

    # The committed db/schema.rb is the PostgreSQL schema, because PostgreSQL is
    # the deployed adapter. Migrating against the local SQLite fallback must not
    # overwrite it with a SQLite-flavoured dump.
    config.active_record.dump_schema_after_migration =
      ENV.fetch('DATABASE_ADAPTER', 'sqlite3') == 'postgresql'
  end
end
