class Session < ApplicationRecord
  INACTIVITY_TIMEOUT = 2.weeks
  ABSOLUTE_LIFETIME = 12.weeks
  TOUCH_INTERVAL = 1.hour

  belongs_to :identity

  scope :ordered, -> { order(updated_at: :desc) }
  scope :active, -> { where(updated_at: INACTIVITY_TIMEOUT.ago..).where(created_at: ABSOLUTE_LIFETIME.ago..) }

  class << self
    # Global revocation by identity — an incident containment hook.
    # See docs/operations/incident-response.md.
    def revoke_all_for(identity)
      transaction do
        identity.sessions.destroy_all
        AuditEvent.record!(action: "session.revoke_all", target: identity)
      end
    end
  end

  def expired?
    updated_at < INACTIVITY_TIMEOUT.ago || created_at < ABSOLUTE_LIFETIME.ago
  end

  # Touches at most once per hour so per-request activity tracking does not
  # become a write storm.
  def touch_activity
    touch if updated_at < TOUCH_INTERVAL.ago
  end

  def revoke!
    transaction do
      revoked_identity = identity
      destroy!
      AuditEvent.record!(action: "session.revoke", target: revoked_identity)
    end
  end

  def step_up_verified?
    step_up_verified_at.present? && step_up_verified_at > 15.minutes.ago
  end

  def mark_step_up_verified!
    update!(step_up_verified_at: Time.current)
  end
end
