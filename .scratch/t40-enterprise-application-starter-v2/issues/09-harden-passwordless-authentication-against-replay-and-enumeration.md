# 09 — Harden passwordless authentication against replay and enumeration

**What to build:** Provide a passwordless sign-in flow whose codes cannot be replayed, consumed for the wrong identity or used to distinguish registered addresses.

**Blocked by:** 01 — Reconcile and pin the protected v2 baseline; 04 — Fail closed with an explicit incomplete-install state.

**Status:** completed

- [x] A code is consumed atomically and at most once, including under concurrent verification attempts.
- [x] Verification binds the code to the expected identity and purpose before it is invalidated or a session is created.
- [x] Known and unknown addresses receive the same outward response and a timing-resistant processing path.
- [x] Expired, malformed, guessed, cross-identity and reused codes fail without creating a session.
- [x] Rate limits constrain request and verification abuse without creating a permanent attacker-triggered lockout.
