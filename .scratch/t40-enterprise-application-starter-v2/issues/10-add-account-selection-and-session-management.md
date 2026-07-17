# 10 — Add account selection and session management

**What to build:** Let signed-in people choose an authorised account, understand their active sessions and revoke access from an untrusted device.

**Blocked by:** 05 — Make single-account mode a genuine installation variant; 09 — Harden passwordless authentication against replay and enumeration.

**Status:** completed

- [x] A person with multiple active memberships chooses an account before accessing tenant-owned functionality.
- [x] Switching accounts validates active membership on the server and rejects forged account identifiers.
- [x] A person can list active sessions with useful device and activity context and revoke an individual session.
- [x] Global sign-out revokes every session for the identity and produces audit evidence.
- [x] Sensitive actions encounter a fail-closed step-up hook, with production readiness blocked until the project supplies an approved phishing-resistant mechanism.
