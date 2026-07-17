# 15 — Make background work operable under failure

**What to build:** Make tenant-aware background work safe to retry and give operators a visible, authorised way to understand and recover failed work.

**Blocked by:** 11 — Prove tenant isolation across every context carrier; 12 — Complete authorised audit access and export.

**Status:** completed

- [x] The generated application verifies that its production queue backend is installed and usable.
- [x] Each generated job example declares bounded timeout, retry, discard and maximum-attempt behaviour.
- [x] A retryable side effect uses a stable idempotency key and cannot be duplicated by job retry.
- [x] Operators can see failed or blocked jobs and relevant backlog age without gaining unrestricted application access.
- [x] An authorised replay is bounded, tenant-aware and audited, while invalid tenant context is never replayed.
