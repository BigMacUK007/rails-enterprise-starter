---
status: template
owner: ""
review_by: ""
---

# Subprocessor Register

## How to complete this document

List every third party that processes personal data on behalf of this application:
hosting, database, email, error reporting, log platforms, backup storage, and any
project integrations. Clients and their procurement teams will ask for exactly this
table — keep it current and dated. Confirm each subprocessor is authorised under the
relevant contract or DPA, then set `status: complete` with an owner and review date.
Review on every new integration and at least annually.

> This template supports evidence gathering; it does not by itself provide ISO 27001,
> SOC 2, Cyber Essentials, WCAG conformance or legal compliance.

## Register

| Subprocessor | Service | Data categories processed | Processing location(s) | Transfer safeguard (if outside UK/EEA) | Contract / DPA | Added | Removed |
|---|---|---|---|---|---|---|---|
| _Hosting provider_ | Compute, managed PostgreSQL | All application data | _region_ | _see `international-transfers.md`_ | _link_ | _date_ | |
| _Email provider_ | Transactional email | Email addresses, sign-in codes in transit | _region_ | | _link_ | _date_ | |
| _Backup storage_ | Encrypted backups | All application data (encrypted) | _region_ | | _link_ | _date_ | |
| _Error reporting backend_ | Exception reporting | Redacted error metadata, correlation IDs | _region_ | | _link_ | _date_ | (deferred until backend selected) |
| _Project integration_ | | | | | | | |

## Change management

- New subprocessors require approval by _role_ before any personal data flows.
- Where the client contract requires notice of subprocessor changes, the notice route is
  _route_ and the notice period is _period_.
- Removal: record the removal date above and confirm data deletion or return with the
  subprocessor; keep the confirmation with the contract records.
