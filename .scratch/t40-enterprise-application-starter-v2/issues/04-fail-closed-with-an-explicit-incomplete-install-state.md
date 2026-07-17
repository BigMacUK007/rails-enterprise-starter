# 04 — Fail closed with an explicit incomplete-install state

**What to build:** Prevent a partial or unverified installation from being mistaken for a successfully installed enterprise baseline.

**Blocked by:** 03 — Persist a reproducible installation manifest on apply.

**Status:** completed

- [x] Every mutating entry point runs the required prerequisite and conflict checks before its first target write.
- [x] A dependency-installation or verification failure returns non-zero and records the installation as incomplete.
- [x] Failure output identifies the completed changes, failed stage and safe recovery or rerun action.
- [x] No control becomes verified and no success report is emitted after a failed apply or verification stage.
- [x] A subsequent safe rerun can resume or reconcile the incomplete installation without duplicating resources.
