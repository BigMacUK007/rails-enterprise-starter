# 08 — Bind verification evidence to individual controls

**What to build:** Let a reviewer see exactly which evidence verified each control and which outstanding decisions still block production readiness.

**Blocked by:** 04 — Fail closed with an explicit incomplete-install state; 07 — Generate assurance records from one control catalogue.

**Status:** completed

- [x] Each automated check reports the control identifiers it genuinely exercises.
- [x] A generic successful verification run cannot mark unrelated controls verified.
- [x] Manual and deferred controls retain an owner and evidence requirement until explicitly discharged.
- [x] Installation verification and production readiness are reported as separate, machine-readable outcomes.
- [x] A production-ready result fails when any applicable production gate lacks valid evidence or an approved not-applicable reason.
