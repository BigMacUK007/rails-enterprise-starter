---
status: template
owner: ""
review_by: ""
---

# Threat Model (STRIDE-lite)

## How to complete this document

This is a lightweight STRIDE threat model keyed to the trust boundaries in
[trust-boundaries.md](trust-boundaries.md). For each boundary, consider the six STRIDE
categories (Spoofing, Tampering, Repudiation, Information disclosure, Denial of service,
Elevation of privilege) and record the threats that matter, the control that addresses
each, and any gap with an owner and date. The starter's standard threats are pre-filled —
verify them against your deployment, then add project-specific threats (integrations,
uploads, exports, payment flows). Revisit after every incident and every significant
architecture change; the post-incident review checklist in
[../operations/incident-response.md](../operations/incident-response.md) requires it.

> This template supports evidence gathering; it does not by itself provide ISO 27001,
> SOC 2, Cyber Essentials, WCAG conformance or legal compliance.

## Scope and assumptions

- _State what is in scope (the generated application and its deployment) and out of scope
  (client devices, third-party provider internals)._
- _State assumptions (for example: hosting provider account is MFA-protected; TLS is
  terminated at a trusted edge)._

## Threat register

| ID | Boundary | STRIDE | Threat | Existing control | Gap / action | Owner | Status |
|---|---|---|---|---|---|---|---|
| T-1 | TB-1 | S | Attacker requests sign-in codes for guessed addresses to enumerate accounts | Identical response for known and unknown addresses (`SessionsController`); verified by `spec/requests/authentication_flow_spec.rb` | | | Mitigated |
| T-2 | TB-1 | S | Brute-forcing the 6-character sign-in code | Codes are single-use, expire after 15 minutes, generated with `SecureRandom`; verification rate-limited | | | Mitigated |
| T-3 | TB-1 | D | Automated sign-in requests exhaust email quota or lock out users | `rate_limit` on sign-in endpoints; no attacker-triggered permanent lockout | Confirm provider-level throttling | | Open |
| T-4 | TB-1 | T | Stolen or fixated session cookie | Session rotation on sign-in (`reset_session`), Secure/HttpOnly/SameSite cookies, inactivity and absolute expiry, per-session and global revocation | | | Mitigated |
| T-5 | TB-6 | E, I | A user reads or mutates another account's data | Membership-resolved `Current.account`, `AccountScoped`, `authorize!` tenant assertion; negative tests in `spec/requests/tenant_isolation_spec.rb` | Consider RLS module for high-risk deployments | | Mitigated |
| T-6 | TB-7 | E | A member invokes an owner/admin capability | Default-deny `authorize!`; denied attempts recorded as `authorization.denied` audit events | | | Mitigated |
| T-7 | TB-2 | R | An actor disputes an administrative action | Append-only `AuditEvent` with actor, tenant, action, target, correlation ID; critical events written in the business transaction | | | Mitigated |
| T-8 | TB-4 | I | Secrets, codes or tokens leak into logs or audit exports | `filter_parameters` additions, `AuditEvent::Redactor`, JSON log schema; verified by parameter-filtering and redactor specs | | | Mitigated |
| T-9 | TB-3 | T | Compromised third-party dependency ships malicious code | Lockfiles, Dependabot, `bundler-audit`, Brakeman and secret scanning in CI, SBOM per release | Review CI findings weekly | | Mitigated |
| T-10 | TB-5 | E | Untrusted pull request reaches secrets or trusted runners | CI runs untrusted PRs without secrets; no `pull_request_target` with head checkout; branch protection (deferred — see control manifest) | Enable branch protection on the hosting repository | | Open |
| T-11 | TB-5 | E | Support staff access outlives its purpose | `SupportAccessGrant` requires reason and expiry (default 4 hours), revocable, every use audited | | | Mitigated |
| T-12 | TB-1 | I | Malicious upload executes or becomes public | `has_secure_attachment` validates declared and detected type and size; private storage; signed, expiring download URLs | | | Mitigated |
| T-13 | TB-2 | D | Background jobs run without tenant context and touch the wrong data | `T40::JobContext` carries account context; `requires_tenant!` fails closed without retry | | | Mitigated |
| T-14 | TB-1 | D | Traffic spike or incident forces degraded operation | Maintenance and read-only modes (`T40::Runtime`), health/readiness endpoints, alerts with owners | Define capacity thresholds in `operations/alerts.md` | | Open |
| _T-n_ | | | _Add project threats_ | | | | |

## Risk acceptance

Record any threat consciously accepted without mitigation. Each acceptance needs an
owner, a rationale, a compensating control where possible, and an expiry date after which
it must be reviewed.

| Threat ID | Rationale | Compensating control | Owner | Expires |
|---|---|---|---|---|
| | | | | |
