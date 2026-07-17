# Module: OIDC (Enterprise Single Sign-On)

> **Not implemented in v2.0.0 — requires approved funded scope.** Selecting this module
> in `t40-manifest.yml` fails preflight by design: it requires an approved, funded
> client requirement; interface only in this release.

## Purpose

Let an enterprise customer's staff sign in through their own identity provider using
OpenID Connect, instead of (or alongside) the starter's passwordless magic-link flow.
This is the first-choice enterprise SSO module: OIDC-capable providers (Entra ID, Okta,
Google Workspace, Keycloak) cover the overwhelming majority of requests, and an IdP that
enforces phishing-resistant MFA is the sanctioned way to satisfy the deferred step-up
control for privileged users.

## Selection rules

Select this module when:

- A client contract or procurement requirement names SSO, OIDC or "sign in with our
  identity provider".
- Privileged users must inherit the customer's MFA and conditional-access policy.
- Joiner/leaver risk makes customer-controlled sign-in authority desirable (pair with
  the `scim` module for automated deprovisioning).

Do not select it for convenience on a project with no enterprise IdP: the passwordless
core already avoids password risk, and every IdP integration adds a per-customer
conformance and support obligation. If the client's provider is SAML-only, see the
`saml` module instead.

## Interface sketch

- `FederatedIdentity` model: `identity_id` FK, `issuer` (string, the IdP's issuer URL),
  `subject` (string, the IdP's stable `sub` claim), unique index on
  `[issuer, subject]`. **Identity mapping is keyed by issuer + subject, never by
  email** — email addresses are mutable and reassignable and must not be identity keys.
  First sign-in links or provisions an `Identity`; subsequent email changes at the IdP
  do not change who the federated identity resolves to.
- Standards-based, maintained client library (e.g. `omniauth` + `omniauth_openid_connect`
  or an equivalent maintained OIDC client). The module does not implement OIDC
  cryptography itself.
- Authorisation Code flow with PKCE; `state` and `nonce` enforced; ID token signature,
  issuer, audience and expiry validated; clock skew bounded.
- Per-account IdP configuration (issuer, client id, secret reference) — secrets via the
  secret manager, referenced in `config/t40/required-environment.yml` conventions.
- Sessions created through the existing `start_new_session_for` path so rotation,
  expiry, revocation and audit behaviour are identical to the core flow. Sign-in and
  failure produce `AuditEvent` records.
- Account membership (`User`, role) remains authorised in this application; the IdP
  authenticates, it does not authorise.

## Conformance tests the module must add

- Issuer/subject mapping: same subject + new email resolves to the same `Identity`;
  same email + different issuer/subject does NOT.
- Token validation failures (bad signature, wrong audience, expired, replayed `nonce`,
  missing `state`) are rejected and audited without creating sessions.
- A federated sign-in for an identity with no active membership grants no account
  access.
- Session semantics identical to core: rotation on sign-in, revocation via
  `Session.revoke_all_for`, expiry honoured.
- IdP outage degrades cleanly: clear error, no enumeration, no fallback that silently
  weakens authentication.
- Provider interactions tested against a local fake/fixture IdP — no live provider in
  the test suite.
