# Append-only audit evidence, usable from models, jobs and controllers.
#
# Use AuditEvent.record! inside the same transaction as the business change
# for critical actions, so the action cannot succeed while its audit evidence
# silently fails. Use AuditEvent.record for best-effort, non-critical
# activity events only.
#
# Operational logs and audit events are deliberately separate: they have
# different audiences, retention and sensitivity.
class AuditEvent < ApplicationRecord
  belongs_to :account, optional: true # nil only for documented global/pre-auth events
  belongs_to :identity, optional: true
  belongs_to :impersonator, class_name: "Identity", optional: true
  belongs_to :target, polymorphic: true, optional: true

  validates :action, presence: true
  validates :result, presence: true
  validates :occurred_at, presence: true

  # Append-only: application code can never rewrite or remove audit history.
  before_update -> { raise ActiveRecord::ReadOnlyRecord }
  before_destroy -> { raise ActiveRecord::ReadOnlyRecord }

  class << self
    # Records an audit event and raises on failure. Call inside the business
    # transaction for critical actions.
    def record!(action:, target: nil, result: "success", reason: nil, changes: nil)
      create!(
        action: action,
        target: target,
        result: result,
        reason: reason,
        change_summary: changes ? Redactor.redact(changes) : nil,
        account: Current.account,
        identity: Current.identity,
        impersonator_id: Current.impersonator&.id,
        correlation_id: Current.request_id,
        release: ENV["RELEASE_SHA"] || ENV["KAMAL_VERSION"],
        occurred_at: Time.current
      )
    end

    # Best-effort variant for NON-critical events only: failures are logged
    # and swallowed so they cannot break the user-facing action.
    def record(...)
      record!(...)
    rescue StandardError => error
      Rails.logger.error("AuditEvent.record failed: #{error.class}: #{error.message}")
      nil
    end

    # Returns the account's audit history as an array of hashes (change
    # summaries were already redacted at write time). Exporting audit history
    # is itself an audited action.
    def export(account:)
      require_current_account!(account)
      events = where(account: account).order(:occurred_at, :id).map(&:to_export)
      record!(action: "audit.export", target: account)
      events
    end

    def for_authorized_access(account:)
      require_current_account!(account)
      record!(action: "audit.view", target: account)
      where(account: account).order(occurred_at: :desc, id: :desc)
    end

    private
      def require_current_account!(account)
        return if account.present? && account == Current.account

        raise Authorization::Denied, "Audit evidence is restricted to the current account"
      end
  end

  def to_export
    {
      "id" => id,
      "action" => action,
      "result" => result,
      "reason" => reason,
      "identity_id" => identity_id,
      "impersonator_id" => impersonator_id,
      "target_type" => target_type,
      "target_id" => target_id,
      "correlation_id" => correlation_id,
      "release" => release,
      "change_summary" => change_summary,
      "occurred_at" => occurred_at&.iso8601
    }
  end
end
