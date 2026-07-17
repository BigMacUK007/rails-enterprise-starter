# Safe degradation modes for incident containment (see
# docs/operations/maintenance-mode.md).
#
#   Maintenance: T40_MAINTENANCE=1 or tmp/maintenance.txt present — every
#   request renders the maintenance page with 503. Health endpoints stay live
#   so load balancers and operators can still observe the app.
#
#   Read-only: T40_READ_ONLY=1 — GET/HEAD continue to work; every other verb
#   is rejected with 503 (JSON) or redirected back with a flash (HTML) so no
#   further writes occur while an incident is contained.
module MaintenanceMode
  extend ActiveSupport::Concern

  included do
    before_action :enforce_maintenance_mode
    before_action :enforce_read_only_mode
  end

  private
    def enforce_maintenance_mode
      return unless T40::Runtime.maintenance?
      return if health_check_request?

      render "t40/maintenance", layout: "public", formats: :html, status: :service_unavailable
    end

    def enforce_read_only_mode
      return unless T40::Runtime.read_only?
      return if request.get? || request.head?
      return if health_check_request?

      if request.format.html?
        redirect_back fallback_location: "/",
          alert: "The application is temporarily read-only. Your change was not saved."
      else
        render json: { error: "read_only", message: "The application is temporarily read-only." },
          status: :service_unavailable
      end
    end

    def health_check_request?
      request.path.start_with?("/health")
    end
end
