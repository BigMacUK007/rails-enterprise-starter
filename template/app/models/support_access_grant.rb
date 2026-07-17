# Explicit, time-limited support access for cross-account staff actions.
# Every grant, use and revocation leaves audit evidence — see
# docs/operations/support-access.md.
class SupportAccessGrant < ApplicationRecord
  DEFAULT_DURATION = 4.hours

  belongs_to :account
  belongs_to :identity # the staff member receiving access
  belongs_to :granted_by, class_name: "Identity"

  validates :reason, presence: true
  validates :expires_at, presence: true

  scope :active, -> { where(revoked_at: nil).where(expires_at: Time.current...) }

  class << self
    def grant!(account:, staff_identity:, granted_by:, reason:, duration: DEFAULT_DURATION)
      raise ArgumentError, "support access requires a staff identity" unless staff_identity.staff?

      transaction do
        grant = create!(
          account: account,
          identity: staff_identity,
          granted_by: granted_by,
          reason: reason,
          expires_at: duration.from_now
        )
        AuditEvent.record!(
          action: "support_access.grant",
          target: grant,
          reason: reason,
          changes: {
            "account_id" => account.id,
            "staff_identity_id" => staff_identity.id,
            "expires_at" => grant.expires_at.iso8601
          }
        )
        grant
      end
    end

    # Runs the block as a support-access action: Current.account and
    # Current.impersonator are set for its duration and audit events are
    # recorded around use. Raises unless the grant is active.
    def with_grant(grant)
      raise ArgumentError, "support access grant is not active" unless grant&.active?

      Current.set(account: grant.account, impersonator: grant.identity) do
        AuditEvent.record!(action: "support_access.begin", target: grant, reason: grant.reason)
        begin
          result = yield
        rescue StandardError
          AuditEvent.record(action: "support_access.end", target: grant, result: "failure")
          raise
        end
        AuditEvent.record!(action: "support_access.end", target: grant)
        result
      end
    end
  end

  def active?
    !revoked? && expires_at.future?
  end

  def revoked?
    revoked_at.present?
  end

  def revoke!(by:)
    transaction do
      update!(revoked_at: Time.current)
      AuditEvent.record!(action: "support_access.revoke", target: self, changes: { "revoked_by_id" => by.id })
    end
  end
end
