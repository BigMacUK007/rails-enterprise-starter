# Server-side, default-deny authorisation.
#
# Two entry points:
#
#   require_role :admin, only: :destroy       # class-level role gate
#   authorize! :can_export_data?, record      # capability + tenant boundary
#
# Capabilities are explicit predicates on User (see User::Role) — no policy
# framework. Owners satisfy the :admin role because User::Role#admin? includes
# owners.
#
# Denials raise Authorization::Denied, which renders 403 and records an audit
# event. UI hiding (removing buttons or links) is a convenience only — these
# server-side checks are the authorisation boundary.
module Authorization
  extend ActiveSupport::Concern

  class Denied < StandardError; end
  class StepUpRequired < Denied; end

  included do
    rescue_from Authorization::Denied, with: :handle_authorization_denied
  end

  class_methods do
    # Default-deny role gate. Denies when there is no Current.user or when the
    # user holds none of the given roles. Accepts standard filter options
    # (only:, except:, if:, unless:).
    def require_role(*roles, **filter_opts)
      before_action(**filter_opts) do
        granted = Current.user.present? && roles.any? { |role| Current.user.public_send("#{role}?") }
        raise Authorization::Denied, "Requires role: #{roles.join(" or ")}" unless granted
      end
    end
  end

  private
    # Asserts that the current user holds the given capability predicate
    # (for example :can_manage_users?). When a record scoped to an account is
    # given, also asserts it belongs to Current.account — the tenant boundary
    # is enforced at the authorisation layer, not just in queries.
    def authorize!(capability, record = nil)
      user = Current.user
      raise Authorization::Denied, "Missing capability: #{capability}" unless user&.public_send(capability)

      if record.respond_to?(:account_id) && record.account_id != Current.account&.id
        raise Authorization::Denied, "Record does not belong to the current account"
      end

      true
    end

    def require_step_up!
      return true if Current.session&.step_up_verified?

      raise Authorization::StepUpRequired, "This action requires approved step-up authentication"
    end

    def handle_authorization_denied(exception)
      AuditEvent.record(action: "authorization.denied", result: "denied", reason: exception.message)

      respond_to do |format|
        format.html { render plain: "You are not authorised to perform this action.", status: :forbidden }
        format.any { head :forbidden }
      end
    end
end
