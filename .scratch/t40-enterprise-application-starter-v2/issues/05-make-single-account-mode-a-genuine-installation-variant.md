# 05 — Make single-account mode a genuine installation variant

**What to build:** Give applications selecting single-account tenancy a complete, usable account bootstrap and resolution flow rather than merely documenting the selection.

**Blocked by:** 03 — Persist a reproducible installation manifest on apply.

**Status:** completed

- [x] A single-account install creates or resolves its one account without presenting a multi-account chooser.
- [x] Authentication derives tenant authority from an active membership and never from unverified request input.
- [x] Attempts to introduce or select an unauthorised second account fail closed.
- [x] Generated guidance, tests and control evidence describe the selected single-account behaviour accurately.
- [x] Multi-account installation behaviour remains unchanged and independently testable.
