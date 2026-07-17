---
status: template
owner: ""
review_by: ""
---

# Backup and Restore

## How to complete this document

Record the recovery objectives, configure the backups to meet them, write the restore
procedure for this deployment, and then **prove it**: run a full restore test and log it
below.

**Gate: at least one successful, logged restore test is required before this application
is described as production-ready.** A green backup job is not evidence of recoverability;
only a restore is. The control manifest carries backups and restore testing as a deferred
control with an owner until this gate is met.

Set `status: complete` with an owner and review date once objectives, procedure and the
first restore test are recorded.

> This template supports evidence gathering; it does not by itself provide ISO 27001,
> SOC 2, Cyber Essentials, WCAG conformance or legal compliance.

## Recovery objectives

Agree these with the client — they drive backup frequency and architecture, and they are
promises, so do not guess them:

| Objective | Value | Agreed with | Date |
|---|---|---|---|
| RPO — recovery point objective (maximum acceptable data loss) | _e.g. 24 hours / 15 minutes_ | | |
| RTO — recovery time objective (maximum acceptable downtime to restore) | _e.g. 4 hours_ | | |

Note: Solid Queue and Solid Cache live in PostgreSQL, so database backups cover queued
jobs too — a restore also proves queue recovery.

## Backup configuration

| Item | Value |
|---|---|
| What is backed up | PostgreSQL (all application data, queue, cache), object storage (uploads) |
| Method | _e.g. provider automated snapshots + WAL / pg_dump schedule_ |
| Frequency | _must satisfy the RPO_ |
| Encryption | _at rest — provider key or customer key; in transit — TLS_ |
| Location / region | _must satisfy residency commitments in `../privacy/international-transfers.md`_ |
| Retention of backups | _e.g. 35 days — align with `../privacy/retention.md`_ |
| Access to backups | _who can list/restore/delete; deletion protection enabled?_ |
| Backup failure alert | _alert name in `alerts.md` — a silent backup failure is the worst failure_ |

## Restore procedure

_Write the actual steps for this deployment. The generic shape:_

1. Declare the incident (`incident-response.md`) and enter maintenance mode
   (`T40_MAINTENANCE=1`) so no writes race the restore.
2. Snapshot the current (broken) state before overwriting anything — it is evidence and
   a fallback.
3. Identify the restore point: latest backup satisfying the incident's needs; note the
   data loss window against the RPO.
4. Restore the database to a **new** instance/database; never restore over the only copy.
5. Verify: `bin/rails db:prepare` runs cleanly against the restored database;
   `bin/rails runner "Rails.application.eager_load!"`; application boots; spot-check
   recent records and audit events; `/health/ready` green.
6. Repoint the application (`DATABASE_URL`), restart web and worker processes.
7. Leave maintenance mode; monitor `alerts.md` closely for the next hour.
8. Log the restore below and reconcile the data-loss window with affected clients.

## Restore-test log

Run a restore test before production and then on a schedule (_e.g. every 6 months_).
A test that fails is a finding, not an embarrassment — log it and fix the procedure.

| Date | Type (test/real) | Backup used | Restored to | Time taken (vs RTO) | Data window (vs RPO) | Result | Issues found | Performed by |
|---|---|---|---|---|---|---|---|---|
| | | | | | | | | |

## Production-readiness gate

| Check | Status |
|---|---|
| RPO and RTO agreed and recorded above | |
| Backups running and alerting on failure | |
| At least one successful restore test logged above | |
| Gate signed off by | _name, date_ |
