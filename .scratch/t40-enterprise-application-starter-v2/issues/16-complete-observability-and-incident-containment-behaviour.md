# 16 — Complete observability and incident-containment behaviour

**What to build:** Give operators enough safe signals and containment controls to diagnose a failing application and limit damage without exposing sensitive data.

**Blocked by:** 14 — Secure uploads, downloads and browser boundaries; 15 — Make background work operable under failure.

**Status:** completed

- [x] Structured request and job logs preserve release, tenant and correlation context while redacting prohibited values.
- [x] Exception reporting uses a replaceable boundary and proves that redacted events reach the selected backend or local fake.
- [x] Liveness and readiness distinguish process health from required and optional dependency degradation.
- [x] Alerts name a threshold, accountable owner, response route and runbook.
- [x] Maintenance, read-only and feature kill switches preserve health visibility and block unsafe work as documented.
