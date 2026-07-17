# 13 — Complete privacy lifecycle and account offboarding hooks

**What to build:** Give project teams working, auditable extension seams for privacy requests and account offboarding without pretending unknown domain data can be handled automatically.

**Blocked by:** 12 — Complete authorised audit access and export.

**Status:** completed

- [x] The starter exposes explicit hooks for export, correction, restriction, retention, legal hold, erasure and irreversible anonymisation.
- [x] A generated example proves that soft deletion remains recoverable and is distinct from legal erasure.
- [x] The complaint workflow records receipt, acknowledgement, investigation, progress and outcome states.
- [x] Account offboarding revokes access immediately and records the remaining export, retention and deletion obligations.
- [x] Privacy operations remain tenant-scoped, authorised and covered by audit evidence and negative tests.
