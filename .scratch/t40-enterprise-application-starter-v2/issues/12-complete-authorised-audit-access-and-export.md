# 12 — Complete authorised audit access and export

**What to build:** Let authorised account administrators inspect and export trustworthy, redacted audit evidence without exposing another tenant or bypassing the audit trail.

**Blocked by:** 08 — Bind verification evidence to individual controls; 11 — Prove tenant isolation across every context carrier.

**Status:** completed

- [x] Authorised users can inspect and export only their current account's audit events.
- [x] Audit access and export create their own correctly attributed audit events.
- [x] Critical business changes roll back when their required audit event cannot be persisted.
- [x] Exported evidence excludes secrets and prohibited sensitive fields and retains correlation and release identifiers.
- [x] Application-level update, destroy and bulk-deletion attempts cannot silently rewrite or remove audit history.
