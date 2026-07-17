# Convention: the including model has a nullable `deleted_at` datetime column.
#
# Soft deletion is a RECOVERABILITY tool, not legal erasure: personal data in
# a soft-deleted row still exists and remains subject to retention and
# subject-rights obligations — see docs/privacy/subject-rights.md. Use the
# PrivacySubject erasure flow for irreversible removal.
module SoftDeletable
  extend ActiveSupport::Concern

  included do
    scope :kept, -> { where(deleted_at: nil) }
    scope :soft_deleted, -> { where.not(deleted_at: nil) }
  end

  def soft_deleted?
    deleted_at.present?
  end

  def soft_delete!
    transaction do
      update!(deleted_at: Time.current)
      AuditEvent.record!(action: soft_deletable_audit_action("soft_delete"), target: self)
    end
  end

  def restore!
    transaction do
      update!(deleted_at: nil)
      AuditEvent.record!(action: soft_deletable_audit_action("restore"), target: self)
    end
  end

  private
    def soft_deletable_audit_action(event)
      subject = self.class.name&.underscore || self.class.table_name
      "#{subject}.#{event}"
    end
end
