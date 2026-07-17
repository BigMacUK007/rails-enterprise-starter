# Resolves Current.account STRICTLY from the authenticated identity's active
# memberships. Route segments, headers and form parameters are never trusted
# as tenant authority.
#
# Resolution order:
#   1. session[:account_id] when it matches one of the identity's active
#      memberships (set only via switch_account, which validates membership);
#   2. otherwise, the identity's single active membership when exactly one
#      exists;
#   3. otherwise nil — controllers that need an account call require_account!
#      or rely on Authorization#authorize! (which denies without a user).
#
# This concern also owns per-request context (Current.request_id, ip_address,
# user_agent) so that audit events and structured logs carry correlation
# identifiers. It lives here rather than in a separate concern to keep the
# installer's marked ApplicationController block stable.
module AccountScoping
  extend ActiveSupport::Concern

  included do
    around_action :set_request_context
    before_action :set_current_account, if: :authenticated?
    rescue_from ActiveRecord::RecordNotFound, with: :not_found_without_disclosure
  end

  private
    def set_request_context
      Current.request_id = request.request_id
      Current.ip_address = request.remote_ip
      Current.user_agent = request.user_agent
      yield
    end

    def set_current_account
      Current.account = resolve_account_from_membership
    end

    def resolve_account_from_membership
      memberships = Current.identity.users.active.includes(:account).to_a

      return memberships.one? ? memberships.first.account : nil if T40::Installation.single_account?

      chosen = nil
      if session[:account_id].present?
        chosen = memberships.find { |membership| membership.account_id == session[:account_id].to_i }
      end
      chosen ||= memberships.first if memberships.one?
      chosen&.account
    end

    # Switch the active account for this browser session. Membership is
    # validated first — an account the identity does not actively belong to
    # raises Authorization::Denied (rendered as 403 and audited).
    def switch_account(account)
      membership = Current.identity&.users&.active&.find_by(account: account)
      raise Authorization::Denied, "No active membership for that account" unless membership

      session[:account_id] = account.id
      Current.account = account
    end

    # Guard for controllers that cannot operate without an account context.
    def require_account!
      return if Current.account.present?

      render plain: "An active account is required for this action.", status: :forbidden
    end

    def not_found_without_disclosure
      render plain: "Not found.", status: :not_found
    end
end
