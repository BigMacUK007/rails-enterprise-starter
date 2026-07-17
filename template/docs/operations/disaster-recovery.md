---
status: template
owner: ""
review_by: ""
---

# Disaster Recovery

## How to complete this document

Backup-restore covers "the database broke". This document covers the bigger failures:
loss of the hosting environment, loss of the provider account, key compromise, loss of a
critical third party. For each scenario, write down the plan while nobody is panicking.
Keep it consistent with the RPO/RTO in `backup-restore.md` — if a scenario cannot meet
them, say so explicitly and agree the exception with the client. Set `status: complete`
with an owner and review date.

> This template supports evidence gathering; it does not by itself provide ISO 27001,
> SOC 2, Cyber Essentials, WCAG conformance or legal compliance.

## Architecture recap

One modular monolith, one PostgreSQL database (application data + Solid Queue + Solid
Cache), object storage for uploads, transactional email provider. Multi-zone or
multi-region designs are adopted only when a contracted service level funds them — record
that decision here if taken.

| Component | Provider | Region | Rebuild source |
|---|---|---|---|
| Application servers | | | Deploy pipeline from the release artefact (`RELEASE_SHA`) |
| PostgreSQL | | | Backups (see `backup-restore.md`) |
| Object storage | | | _replication/versioning policy_ |
| DNS | | | _registrar / DNS provider_ |
| Email | | | _provider + credentials in secret manager_ |
| Secrets | | | _secret manager; `config/t40/required-environment.yml` lists what must exist_ |

## Scenarios

### DR-1: Loss of the application environment (host/zone failure)

| Field | Value |
|---|---|
| Plan | _e.g. re-provision servers from infrastructure config, deploy last release artefact, attach database_ |
| Expected recovery time | _vs RTO_ |
| Data loss | None expected (database unaffected) |
| Dependencies | Provider API, deploy pipeline, secrets |

### DR-2: Loss of the database (corruption, deletion, region failure)

| Field | Value |
|---|---|
| Plan | Restore per `backup-restore.md`; cross-region copy? _yes/no_ |
| Expected recovery time | _vs RTO_ |
| Data loss | Up to RPO |

### DR-3: Loss of the hosting-provider account (compromise, lockout, billing)

| Field | Value |
|---|---|
| Plan | _who can recover the account; are backups accessible outside the account? A backup that dies with the account is not a backup_ |
| Off-account backup copy | _yes/no — location_ |
| Expected recovery time | |

### DR-4: Key or credential compromise

| Field | Value |
|---|---|
| Plan | Rotate per the containment table in `incident-response.md`; sessions invalidated by `SECRET_KEY_BASE` rotation; providers rotated at source |
| Expected recovery time | |

### DR-5: Loss of a critical third party (email provider, error reporting)

| Field | Value |
|---|---|
| Plan | _e.g. alternate SMTP provider — note: sign-in depends on email delivery, so email is availability-critical_ |
| Expected recovery time | |

### DR-n: _Project-specific scenarios (critical integrations, client systems)_

## DR test log

Exercise at least one scenario per year (tabletop counts; a real failover counts more).

| Date | Scenario | Type (tabletop/live) | Result | Gaps found | Actions | Performed by |
|---|---|---|---|---|---|---|
| | | | | | | |
