---
status: accepted
owner: ""
review_by: ""
---

# 0002. Passwordless magic-link authentication

Date: 2026-07-16
Status: Accepted

## Context

Password authentication drags in credential storage, strength policies, breach-corpus
checks, reset flows and credential-stuffing defence — a large, permanently attackable
surface that most T40 client tools do not need. Enterprise clients who require stronger
guarantees ask for their own identity provider (OIDC or SAML) rather than better local
passwords. Devise would bring that whole password surface plus a large dependency; it
also fights the Rails 8 authentication primitives.

## Decision

Use passwordless magic-link authentication as the local default, built on Rails
primitives rather than an authentication framework. Devise is not used.

- A global `Identity` (the person) is separate from account-scoped `User` membership;
  one person can belong to several accounts with one credential-free identity.
- Sign-in sends a short-lived (15 minutes), single-use, `SecureRandom`-generated code
  (`MagicLink`); consumption destroys the code.
- Responses do not reveal whether an address is known (anti-enumeration), and sign-in and
  verification endpoints are rate-limited without enabling permanent lockout.
- Sessions are server-side records: rotated on authentication, individually and globally
  revocable (`Session.revoke_all_for`), with inactivity and absolute lifetimes, carried in
  Secure/HttpOnly/SameSite cookies over enforced HTTPS.
- Step-up authentication for privileged actions is a recorded, deferred control in the
  control manifest. Enterprise SSO (OIDC first) is an optional module keyed by issuer and
  subject, never by email.

## Consequences

- No password hashes, reset tokens or strength policies to store, test or defend; the
  email account becomes the key dependency, which is why step-up authentication for
  privileged actions remains an owned, deferred control rather than a forgotten one.
- Sign-in requires a working outbound email path in every environment; boot validation
  fails production without a mail delivery configuration.
- Session behaviour is fully testable at the request seam (revocation, expiry, rotation),
  which the generated spec suite exercises.
- Projects whose clients mandate passwords or an IdP must record that as a new ADR and
  scope the appropriate module rather than bolting Devise on.
