# Module: API (Versioned Public API)

> **Not implemented in v2.0.0 — requires approved funded scope.** Selecting this module
> in `t40-manifest.yml` fails preflight by design: it requires an approved, funded
> client requirement; interface only in this release.

## Purpose

Expose a deliberate, versioned public API for machine consumers — client systems,
integration partners, scripted access — with an explicit compatibility policy and an
OpenAPI description. The core baseline exposes no public API on purpose: unused default
endpoints are attack surface and procurement questions. This module makes the external
contract explicit and testable when a paying integration actually needs one.

## Selection rules

Select this module when:

- A client or partner integration needs programmatic access that the browser
  application cannot serve.
- A contract names an API deliverable, or a data-exchange requirement exceeds what
  operator-run exports cover.

Do not select it for internal Hotwire needs (Turbo covers those), for a single one-off
export (use the audited export routes), or "for the future". Every public endpoint
carries a compatibility promise, a security surface and documentation burden from the
day it ships.

## Interface sketch

- Versioned path namespace (`/api/v1/...`); a version is only bumped for breaking
  changes, per a written compatibility policy published with the OpenAPI document.
  **Active Record models are never the external contract** — explicit serializers map
  domain objects to documented response shapes.
- Credentials: scoped, tenant-bound API tokens — stored hashed, bound to one `Account`,
  carrying named scopes (least privilege, read-only scopes by default), individually
  revocable, with last-used tracking. Creation, rotation and revocation are audited.
  Requests authenticate via `Authorization: Bearer` — never cookies, so CSRF and session
  semantics stay browser-only.
- Authorisation reuses the core capability layer: token scopes gate coarse access, and
  `authorize!`-style checks with the token's account enforce record-level and tenant
  boundaries. `Current.account` resolves from the token, never from parameters.
- Bounded pagination (cursor-based, hard maximum page size), stable structured errors
  (machine-readable code, human message, correlation `request_id`), rate limits per
  token and per account, request identifiers on every response.
- OpenAPI 3.x description generated or verified from request specs so the document
  cannot drift from behaviour; published with the version policy.

## Conformance tests the module must add

- A token bound to account A cannot read, mutate, enumerate or infer account B's data —
  including via ids in URLs, filters, includes and pagination cursors.
- Scope enforcement: a read-only token cannot mutate; an unscoped route does not exist
  (default deny at the routing/controller layer).
- Revoked and expired tokens fail immediately; token values never appear in logs or
  audit events (redaction covers `Authorization`).
- Pagination bounds hold under hostile parameters (huge page sizes, forged cursors).
- Error responses are stable shapes with correlation ids and leak no internals.
- Rate limits return the documented status and headers; the OpenAPI document validates
  against real responses in CI.
