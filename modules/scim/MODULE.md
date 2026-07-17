# Module: SCIM (User Provisioning)

> **Not implemented in v2.0.0 — requires approved funded scope.** Selecting this module
> in `t40-manifest.yml` fails preflight by design: it requires an approved, funded
> client requirement; interface only in this release.

## Purpose

Automate joiner, mover and leaver changes from an enterprise customer's identity
provider into this application using SCIM 2.0 (RFC 7643/7644). When the customer
deactivates a leaver in their IdP, their membership here is deactivated within minutes,
without a support ticket. SCIM is scoped separately from SSO because it is a
provisioning API with its own authentication, tenancy and conformance surface —
customers frequently want SSO without SCIM, and each IdP's SCIM client behaves slightly
differently.

## Selection rules

Select this module when:

- A contracted customer requires automated provisioning/deprovisioning from their IdP
  (usually alongside the `oidc` or `saml` module).
- Leaver risk is material: compliance requirements around timely access revocation, or
  user counts that make manual membership management error-prone.

Do not select it when memberships are few and owner-managed — the core invitation and
deactivation flows plus the access-review procedure already cover that. The engagement
must fund per-IdP conformance testing (Entra ID and Okta at minimum behave differently).

## Interface sketch

- SCIM 2.0 endpoints under a dedicated, versioned path (e.g. `/scim/v2/Users`,
  `/scim/v2/Groups`), served as an API surface separate from the browser application.
- Authentication: per-account, long-lived bearer credential, stored hashed, scoped to
  SCIM only and to that account's memberships — tenant-bound like all credentials in
  this starter. Rotation and revocation supported and audited.
- Mapping: SCIM `userName`/`externalId` → `Identity` + `User` membership in the
  provisioning account. Deactivation (`active: false`) deactivates the membership and
  revokes sessions (`Session.revoke_all_for`) — it does not delete or erase data
  (erasure remains a `PrivacySubject` decision under `docs/privacy/`).
- Role mapping from groups or entitlement attributes is explicit per-customer
  configuration; the default maps provisioned users to `member`, never to `owner`.
- Every provisioning change records an `AuditEvent` (actor: the SCIM credential,
  distinct from human actors).
- Rate limits, bounded pagination, stable SCIM error responses per RFC 7644.

## Conformance tests the module must add

- A SCIM credential for account A cannot read or mutate account B's users (tenant
  boundary at the credential).
- Deactivation revokes access: membership inactive, existing sessions destroyed, next
  request unauthenticated.
- Idempotency: replayed create/update requests do not duplicate identities or
  memberships.
- No privilege escalation: provisioning cannot create or promote to `owner`; role
  mapping honours the configured ceiling.
- Malformed and oversized SCIM payloads are rejected with stable errors; every change
  produces audit evidence.
- Contract fixtures for the IdPs the customer uses (Entra ID, Okta) — no live IdP in
  the test suite.
