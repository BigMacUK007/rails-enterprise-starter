# 06 — Make data risk and deployment profile drive gates

**What to build:** Turn manifest risk answers and deployment profile into meaningful control selection, human follow-up and production-readiness decisions.

**Blocked by:** 03 — Persist a reproducible installation manifest on apply.

**Status:** completed

- [x] Each data-risk answer has a documented, testable effect on applicable controls or required project decisions.
- [x] The high-assurance profile activates stricter gates than the standard profile and explains the added obligations.
- [x] Unsupported or contradictory combinations fail validation instead of silently receiving the standard baseline.
- [x] Reports identify why each risk-derived control is applicable, deferred or not applicable.
- [x] Equivalent manifests produce equivalent control selections in separate installations.
