---
status: template
owner: ""
review_by: ""
---

# Data Flows

## How to complete this document

Record every flow of data into, out of, and within the system. Give each flow an
identifier (`DF-1`, `DF-2`, …) so the threat model and trust-boundary register can refer
to it. Mark flows that carry personal data — those rows must also appear in
`../privacy/data-inventory.md`. Replace the example rows, keep the identifiers stable,
set `status: complete` and record an owner and review date.

> This template supports evidence gathering; it does not by itself provide ISO 27001,
> SOC 2, Cyber Essentials, WCAG conformance or legal compliance.

## Flow register

| ID | Source | Destination | Data | Personal data? | Transport | Protection | Trust boundary |
|---|---|---|---|---|---|---|---|
| DF-1 | Browser | Rails application | Sign-in email address, sign-in code | Yes | HTTPS | TLS, rate limiting, anti-enumeration responses | TB-1 |
| DF-2 | Rails application | Email provider | Magic-link code, recipient address | Yes | SMTP over TLS | TLS, code expires in 15 minutes, single use | TB-3 |
| DF-3 | Rails application | PostgreSQL | All application data | Yes | Local socket / TLS | Network isolation, credentials via secret references | TB-2 |
| DF-4 | Rails application | Solid Queue (PostgreSQL) | Job payloads incl. tenant and correlation context | Possibly | Local socket / TLS | `T40::JobContext` carries account context; no secrets in payloads | TB-2 |
| DF-5 | Rails application | Error reporting backend | Error class, message, correlation IDs | Should not | HTTPS | Parameter filtering, log redaction | TB-3 |
| DF-6 | Rails application | Structured logs | Request/job metadata, account and identity IDs | Minimal | Local / log shipper | JSON formatter, `filter_parameters`, no secrets or codes | TB-4 |
| DF-7 | Operator | Hosting provider | Deploy artefacts, configuration references | No | HTTPS/SSH | MFA on provider accounts, secret references only | TB-5 |
| _DF-n_ | _Add project flows_ | | | | | | |

## Data categories

_Define the categories used above (for example: account data, identity data, audit
evidence, uploaded files, integration payloads) and their classification. Keep this
consistent with `../privacy/data-inventory.md`._

| Category | Classification | Examples |
|---|---|---|
| Identity data | Personal data | Email address, session metadata |
| Account data | Confidential | Account name, entitlements |
| Audit evidence | Confidential | Actor, action, target, redacted change summary |
| _Add categories_ | | |

## Diagram

_Add a data-flow diagram showing the flows above crossing the trust boundaries defined in
[trust-boundaries.md](trust-boundaries.md)._
