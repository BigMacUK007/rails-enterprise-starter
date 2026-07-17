# 18 — Prove delivery and release evidence

**What to build:** Make every generated release traceable to its tests, security checks, approvals and resolved software inventory without exposing trusted secrets to untrusted changes.

**Blocked by:** 08 — Bind verification evidence to individual controls; 13 — Complete privacy lifecycle and account offboarding hooks; 15 — Make background work operable under failure; 16 — Complete observability and incident-containment behaviour; 17 — Ship the Phlex design-system and accessibility seam.

**Status:** completed

- [x] Generated continuous integration runs application, tenant, authorisation, migration, static-analysis, dependency and secret checks on every change.
- [x] An untrusted pull request cannot access trusted secrets, privileged runners or a release path.
- [x] Release evidence links the immutable release identifier to the source revision, required checks and approvals.
- [x] The software bill of materials represents the resolved release artefact and is retained with the release evidence.
- [x] Critical or high findings without an owned, expiring exception block release readiness.
