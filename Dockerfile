# syntax=docker/dockerfile:1

# ---- Build stage -----------------------------------------------------------
# Compiles native gem extensions and precompiles assets. None of the build
# toolchain reaches the runtime image.
FROM ruby:3.1.3-slim AS build

ENV RAILS_ENV=production \
    BUNDLE_DEPLOYMENT=1 \
    BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_WITHOUT=development:test

RUN apt-get update -qq \
 && apt-get install --no-install-recommends -y build-essential git libpq-dev pkg-config \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN bundle install \
 && rm -rf "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git

COPY . .

# SECRET_KEY_BASE_DUMMY lets assets:precompile run without a real secret; the
# value never reaches the runtime image.
RUN SECRET_KEY_BASE=dummy_key_for_asset_precompilation_only \
    bundle exec rails assets:precompile \
 && rm -rf tmp/cache log/*.log

# ---- Runtime stage ---------------------------------------------------------
FROM ruby:3.1.3-slim AS runtime

ENV RAILS_ENV=production \
    BUNDLE_DEPLOYMENT=1 \
    BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_WITHOUT=development:test \
    RAILS_LOG_TO_STDOUT=1 \
    RAILS_SERVE_STATIC_FILES=1 \
    DATABASE_ADAPTER=postgresql

# libpq5 for the pg gem, curl for the healthcheck. No compilers here.
RUN apt-get update -qq \
 && apt-get install --no-install-recommends -y curl libpq5 \
 && rm -rf /var/lib/apt/lists/* \
 && groupadd --system --gid 1000 rails \
 && useradd --system --uid 1000 --gid rails --create-home rails

WORKDIR /app

COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build --chown=rails:rails /app /app

RUN mkdir -p tmp/pids log storage && chown -R rails:rails tmp log storage

USER rails:rails

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD curl --fail --silent http://127.0.0.1:3000/up || exit 1

ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
