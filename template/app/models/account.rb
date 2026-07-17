class Account < ApplicationRecord
  include Account::Entitlements

  has_many :users, dependent: :destroy
  has_many :identities, through: :users
  has_many :audit_events, dependent: nil # audit history outlives membership; erasure runs through the privacy flow

  validates :name, presence: true
  before_validation :set_single_account_guard, on: :create

  # Offboarding revokes access immediately and records audit evidence.
  # Data export and eventual deletion are deliberate human follow-ups —
  # see docs/privacy/retention.md and docs/privacy/subject-rights.md.
  def offboard!(reason:, obligations: %w[export retention deletion])
    transaction do
      users.active.find_each(&:deactivate)
      AuditEvent.record!(action: "account.offboard", target: self, reason: reason,
        changes: { remaining_obligations: Array(obligations) })
    end
  end

  private
    def set_single_account_guard
      self.single_account_guard = true if T40::Installation.single_account?
    end
end
