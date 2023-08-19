# frozen_string_literal: true

# Liveness probe for the container healthcheck and any load balancer.
# Deliberately unauthenticated and free of database access, so it reports
# whether the web process is serving, not whether the whole stack is well.
class HealthController < ApplicationController
  def show
    render plain: 'ok', status: :ok
  end
end
