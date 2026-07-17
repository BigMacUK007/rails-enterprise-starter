# 01 — Reconcile and pin the protected v2 baseline

**What to build:** Preserve the existing v2 work as the implementation baseline and establish one honest, reproducible compatibility contract for the starter and every generated application.

**Blocked by:** None — can start immediately.

**Status:** completed

- [x] Existing uncommitted authentication and installer work is inventoried and preserved without reset, overwrite or cleanup.
- [x] The supported Ruby, Rails and PostgreSQL versions agree across preflight, generated migrations, documentation and continuous integration.
- [x] The installer unit suite passes on the supported Ruby version and the result is recorded as baseline evidence.
- [x] Stale repository-state statements are corrected, including the obsolete Git index-lock warning.
- [x] The product contract explicitly distinguishes a verified starter installation from a production-ready client application.
