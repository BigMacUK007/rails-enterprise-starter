---
status: template
owner: ""
review_by: ""
---

# Retention Schedule

## How to complete this document

Set a retention period and disposal method for every data category in
`data-inventory.md`. "Indefinite" is not a retention period. Where retention is driven by
law or contract, cite the driver. Completing this schedule is a deferred control in the
control manifest — assign the owner there and here. Then implement the schedule: retention
that exists only in this document protects nobody. Set `status: complete` with an owner
and review date; review annually.

> This template supports evidence gathering; it does not by itself provide ISO 27001,
> SOC 2, Cyber Essentials, WCAG conformance or legal compliance.

## Principles

- Soft deletion (`SoftDeletable`, the `deleted_at` convention) is **recoverability, not
  erasure**. A soft-deleted record still exists and still counts against retention.
- Legal erasure and anonymisation run through the `PrivacySubject` interface
  (`privacy_erase!`) — see `subject-rights.md`.
- A legal hold suspends disposal for the records it covers; record holds in the table
  below and lift them explicitly.
- Backups age out on their own cycle (see `../operations/backup-restore.md`); erasure
  requests are honoured in live data immediately and fall out of backups as they expire.

## Schedule

| Data category | Retention period | Trigger (from when) | Driver | Disposal method | Implemented by | Hold? |
|---|---|---|---|---|---|---|
| Sign-in codes (`magic_links`) | 15 minutes or first use | Creation | Security | Row deletion (`MagicLink.cleanup`) | Starter (implemented) | No |
| Sessions | Inactivity 2 weeks / absolute 12 weeks | Last activity / creation | Security | Row deletion on expiry or revocation | Starter (implemented) | No |
| Identity data | _e.g. life of membership + N months_ | Account offboarding or erasure request | _contract_ | `privacy_erase!` anonymisation | _project_ | |
| Audit evidence | _e.g. 12–24 months, or contract term_ | Event time (`occurred_at`) | _contract / legitimate interests_ | Scheduled deletion job; export first if contract requires | _project_ | |
| Support access records | _e.g. 24 months_ | Grant expiry | Accountability | Scheduled deletion | _project_ | |
| Structured logs | _e.g. 30–90 days_ | Log time | Operations | Log platform retention setting | _project_ | |
| Error reports | _e.g. 90 days_ | Report time | Operations | Backend retention setting | _project_ | |
| Backups | _e.g. 35 days_ | Backup time | Recovery | Provider lifecycle policy | _project_ | |
| _Project data_ | | | | | | |

## Account offboarding

When an account leaves (`Account#offboard!` revokes access and records audit evidence),
the following are project responsibilities — record how each is done:

| Step | How | Owner | Timescale |
|---|---|---|---|
| Export account data for the client | _e.g. approved export routes incl. `AuditEvent.export(account:)`_ | | |
| Revoke all user access | `Account#offboard!` (implemented) | | Immediate |
| Apply retention to remaining data | Per schedule above | | |
| Final deletion / anonymisation | | | |

## Legal holds

| Hold reference | Scope | Reason | Placed by | Placed on | Lifted on |
|---|---|---|---|---|---|
| | | | | | |
