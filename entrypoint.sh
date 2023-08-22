#!/bin/bash
set -e

# A stale pidfile from an ungraceful stop prevents Puma from booting.
rm -f /app/tmp/pids/server.pid

# Bring the schema up to date before serving. Safe to run on every boot:
# db:prepare creates the database if it is missing and is otherwise a no-op
# when there are no pending migrations.
if [ "${RUN_DB_PREPARE:-true}" = "true" ]; then
  bundle exec rails db:prepare
fi

exec "$@"
