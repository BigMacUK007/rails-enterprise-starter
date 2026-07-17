# 14 — Secure uploads, downloads and browser boundaries

**What to build:** Allow tenant users to handle files through private, authorised paths while rejecting malicious content and shipping safe browser defaults.

**Blocked by:** 11 — Prove tenant isolation across every context carrier.

**Status:** completed

- [x] Uploaded files are private, tenant-bound, size-limited and checked using both declared and detected type.
- [x] Malicious or executable uploads cannot be served as application code or made public accidentally.
- [x] Direct downloads require authorisation and use short-lived signed access where object storage is involved.
- [x] Security headers, transport enforcement and the Content Security Policy have tested safe defaults and a documented rollout path.
- [x] The core application exposes no permissive cross-origin API surface when the API module is absent.
