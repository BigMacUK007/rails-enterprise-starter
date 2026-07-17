# Module: SAML (Legacy Enterprise Single Sign-On)

> **Not implemented in v2.0.0 — requires approved funded scope.** Selecting this module
> in `t40-manifest.yml` fails preflight by design: it requires an approved, funded
> client requirement; interface only in this release.

## Purpose

Support single sign-on for enterprise customers whose identity provider cannot do OIDC —
typically older ADFS, Shibboleth or bespoke SAML 2.0 deployments. SAML is deliberately a
separate paid module rather than a default: every SAML integration involves
customer-specific metadata exchange, certificate lifecycles, attribute-mapping quirks
and ongoing operating support, and SAML's XML processing surface has a long history of
signature-wrapping and parser vulnerabilities that must be owned for the life of the
contract.

## Selection rules

Select this module only when:

- A specific, contracted customer requires SSO **and** their IdP demonstrably cannot use
  OIDC (verify this — many "SAML shops" have OIDC available).
- The engagement funds the conformance work (metadata exchange, certificate rotation
  runbook, per-customer test tenancy) and the support obligation.

Prefer the `oidc` module in every other case. Do not select both speculatively.

## Interface sketch

- Reuses the `FederatedIdentity` mapping from the OIDC module's interface: keyed by
  IdP entity id + persistent `NameID` (issuer + subject in SAML terms), **never by
  email**.
- Maintained, standards-based service-provider library (e.g. `ruby-saml`); the module
  never implements XML signature handling itself and pins the library for security
  updates.
- SP-initiated flow as the default; response signature required over the assertion;
  audience, recipient, `NotBefore`/`NotOnOrAfter` and `InResponseTo` validated; replay
  cache for assertion ids.
- Per-customer configuration record: IdP metadata (URL or document), certificates with
  expiry tracking (surfaced in the alerts catalogue), attribute mapping, clock-skew
  allowance.
- Certificate rotation runbook added to `docs/operations/` — rotation failures are the
  most common SAML outage.
- Sessions, audit and membership authorisation identical to core (see the OIDC sketch):
  the IdP authenticates; this application authorises.

## Conformance tests the module must add

- Unsigned, re-signed and signature-wrapped assertions are rejected (use the library's
  attack corpus plus fixtures).
- Expired, not-yet-valid, replayed and audience-mismatched assertions are rejected and
  audited.
- NameID mapping: email attribute changes do not remap the federated identity.
- Metadata/certificate rollover: old + new certificate window works; expired certificate
  alerts fire.
- No account access without an active membership; session semantics identical to core.
- All tests run against local fixtures — no live IdP dependency.
