# Explicit, minimised activity evidence. Replaces the removed generic
# page-view/params tracker.
#
# Purpose: record *deliberate* product events (an export ran, a report was
# viewed, a record was accessed) as non-critical audit events with a fixed,
# allowlisted metadata schema. There is no automatic capture of request
# parameters, search text or free-form payloads — every recorded field is
# named below and nothing else is stored.
#
# Retention: activity events share the audit_events table; set their retention
# period in docs/privacy/retention.md before production. Events are written
# with AuditEvent.record (non-critical) — a recording failure is logged but
# never fails the user's request. Use AuditEvent.record! directly for
# security-critical actions instead.
module ActivityEvents
  extend ActiveSupport::Concern

  # The only metadata keys that will be persisted. Extend deliberately —
  # never add keys that could carry personal data, search text or secrets.
  ALLOWED_METADATA_KEYS = %w[ record_type record_id record_count export_type format page source duration_ms ].freeze

  private
    # record_activity "report.exported", subject: report, metadata: { export_type: "csv", record_count: 42 }
    def record_activity(action, subject: nil, metadata: {})
      AuditEvent.record(
        action: action,
        target: subject,
        changes: allowlisted_metadata(metadata)
      )
    end

    def allowlisted_metadata(metadata)
      metadata.stringify_keys.slice(*ALLOWED_METADATA_KEYS).presence
    end
end
