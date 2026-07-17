# 11 — Prove tenant isolation across every context carrier

**What to build:** Ensure tenant authority follows an authenticated membership through every application boundary and fails closed whenever context is missing or invalid.

**Blocked by:** 10 — Add account selection and session management.

**Status:** completed

- [x] Cross-account reads, writes, exports and existence probes are denied without leaking the other account's data.
- [x] Background jobs reject missing or deleted tenant context before performing side effects.
- [x] Cache keys, stored-object paths, rate-limit keys, audit events and structured logs carry the correct account context.
- [x] Database constraints and account-scoped uniqueness prevent ambiguous tenant-owned relationships.
- [x] Negative tests exercise each carrier and prove no request-supplied tenant value becomes authority.
