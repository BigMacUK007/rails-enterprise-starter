---
status: template
owner: ""
review_by: ""
---

# Trust Boundaries

## How to complete this document

A trust boundary is any point where the level of trust changes: between the internet and
the application, between the application and its datastore, between tenants, between the
application and third parties. Give each boundary a stable identifier (`TB-1`, `TB-2`, …);
the threat model in [threat-model.md](threat-model.md) is keyed to these identifiers.
Review the pre-filled boundaries, add project-specific ones, set `status: complete` and
record an owner and review date.

> This template supports evidence gathering; it does not by itself provide ISO 27001,
> SOC 2, Cyber Essentials, WCAG conformance or legal compliance.

## Boundary register

| ID | Boundary | Untrusted side | Trusted side | Controls at the boundary |
|---|---|---|---|---|
| TB-1 | Internet ↔ application | Any browser or client | Rails application | TLS/HSTS, CSP and safe headers, authentication, rate limiting, anti-enumeration, CSRF protection |
| TB-2 | Application ↔ datastore | Application code (may contain bugs) | PostgreSQL data | Foreign keys, `AccountScoped` validation, account-scoped queries, append-only audit constraints |
| TB-3 | Application ↔ third parties | Email provider, error reporting, integrations | Rails application | TLS, secret references only, parameter filtering, adapters at the boundary |
| TB-4 | Application ↔ operational telemetry | Logs, metrics readable by operators | Application data | Structured log schema, `filter_parameters`, audit redaction, no codes/tokens/secrets in logs |
| TB-5 | Operator ↔ production | Human operators and CI | Production environment | Provider MFA, branch protection and CI checks, secret manager, audited support access |
| TB-6 | Tenant ↔ tenant | Every other account | An account's data | Membership-resolved `Current.account`, `AccountScoped`, `authorize!` record checks, negative tenant tests |
| TB-7 | User ↔ privileged action | Member-level user | Owner/admin capabilities | Default-deny `authorize!`, capability predicates, denied attempts audited |
| _TB-n_ | _Add project boundaries_ | | | |

## Notes

- Pre-authentication requests (sign-in, health endpoints) cross TB-1 without an identity;
  they are rate-limited and produce non-enumerating responses.
- Support access crosses TB-6 deliberately: it requires an active `SupportAccessGrant`
  with a reason and expiry, and every use is audited (see
  [../operations/support-access.md](../operations/support-access.md)).
- If the PostgreSQL RLS module is later funded and installed, TB-6 gains a database-level
  enforcement layer. Until then, TB-6 is enforced in the application layer only, which is
  a deliberate, documented decision.
