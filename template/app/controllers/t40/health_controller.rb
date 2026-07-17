# Liveness and readiness endpoints for load balancers and operators.
#
#   GET /health/live   — the process is up and serving requests.
#   GET /health/ready  — the process can do useful work (database reachable).
#
# Responses never include configuration, hostnames or connection details —
# only pass/fail booleans and the release identifier.
class T40::HealthController < ApplicationController
  # Health checks are unauthenticated. Guarded with respond_to? so this
  # controller still loads if the Authentication concern is not installed on
  # ApplicationController.
  allow_unauthenticated_access if respond_to?(:allow_unauthenticated_access)

  def live
    render json: { status: "ok", release: T40::Runtime.release }
  end

  def ready
    checks = { db: database_ready?, queue: queue_ready? }
    status = if checks[:db]
      checks[:queue] ? "ok" : "degraded"
    else
      "unavailable"
    end

    render json: { status: status, checks: checks, release: T40::Runtime.release },
      status: checks[:db] ? :ok : :service_unavailable
  end

  private
    def database_ready?
      ActiveRecord::Base.connection_pool.with_connection { |connection| connection.execute("SELECT 1") }
      true
    rescue StandardError
      false
    end

    # A quiet queue is reported as degraded but does not fail readiness —
    # worker restarts must not take the web tier out of rotation.
    def queue_ready?
      return false unless defined?(SolidQueue::Process)

      SolidQueue::Process.where("last_heartbeat_at > ?", 5.minutes.ago).exists?
    rescue StandardError
      false
    end
end
