---
status: template
owner: ""
review_by: ""
---

# Alert Catalogue

## How to complete this document

Every alert needs four things before it exists: a threshold, an owner, a response route
and a runbook link. An alert with any of these missing is noise, and noise trains people
to ignore alerts. Review the pre-filled catalogue, wire each alert into your monitoring
backend, delete anything you genuinely will not act on, and add project-specific alerts
(integrations, business-critical jobs). Set `status: complete` with an owner and review
date; re-review after every incident — "did we detect this ourselves?" is a standing
post-incident question.

> This template supports evidence gathering; it does not by itself provide ISO 27001,
> SOC 2, Cyber Essentials, WCAG conformance or legal compliance.

## Rules

- The **owner** is a person (or an on-call rotation with a named coordinator), not a team
  name or a channel.
- The **response route** says how the owner is told: page, phone, email, channel — and
  within what time a response is expected.
- The **runbook link** points at the procedure the responder follows. If no runbook
  exists, write one before enabling the alert.
- Thresholds are reviewed when they fire wrongly twice: tune or delete.

## Catalogue

| Alert | Threshold | Owner | Response route | Runbook |
|---|---|---|---|---|
| Readiness check failing | `/health/ready` non-200 for > 2 minutes | Named primary on-call in `ownership.md` | Page; acknowledge within 15 minutes | [incident-response.md](incident-response.md) |
| Liveness check failing | `/health/live` non-200 for > 1 minute | Named primary on-call in `ownership.md` | Page immediately | [incident-response.md](incident-response.md) |
| Error rate | > 1% of requests 5xx over 5 minutes | Named primary on-call in `ownership.md` | Page; acknowledge within 15 minutes | [incident-response.md](incident-response.md) |
| Queue worker heartbeat lost | No Solid Queue heartbeat for > 5 minutes | Named primary on-call in `ownership.md` | Page; acknowledge within 15 minutes | [incident-response.md](incident-response.md) |
| Job backlog age | Oldest ready job > 15 minutes | Named service owner in `ownership.md` | Working-hours page; 30-minute response | [incident-response.md](incident-response.md) |
| Failed jobs | Any failed job or > 5% over 1 hour | Named service owner in `ownership.md` | Notify operator route; 30-minute response | [incident-response.md](incident-response.md) |
| Backup failure | Any failure or missed schedule | Named data owner in `ownership.md` | Urgent page | [backup-restore.md](backup-restore.md) |
| Sign-in email delivery failure | > 3 delivery errors in 10 minutes | Named primary on-call in `ownership.md` | Page; acknowledge within 15 minutes | [incident-response.md](incident-response.md), [disaster-recovery.md](disaster-recovery.md) (DR-5) |
| Authentication abuse | > 100 rate-limit rejections in 10 minutes from one source | Named security owner in `ownership.md` | Security route; respond within 30 minutes | [incident-response.md](incident-response.md) |
| Database storage | > 80% of allocated storage for 15 minutes | Named data owner in `ownership.md` | Page in working hours; urgent at 90% | [incident-response.md](incident-response.md) |
| TLS certificate expiry | < 14 days to expiry | Named service owner in `ownership.md` | Daily notification, page at 7 days | [incident-response.md](incident-response.md) |
| `security.txt` expiry | < 30 days to expiry | Named security owner in `ownership.md` | Weekly notification | Update the file and redeploy |
| Feature flag past removal date | Weekly report lists an expired flag | Named service owner in `ownership.md` | Weekly notification | Remove it or extend `removal_by` deliberately |
| _Project alert_ | | | | |

## Delivery and escalation

| Item | Value |
|---|---|
| Monitoring backend | _e.g. provider monitoring, uptime service — record what actually watches these_ |
| Primary route | _e.g. paging service / phone rotation_ |
| Escalation if unacknowledged | _e.g. after 15 minutes, escalate to service owner per [ownership.md](ownership.md)_ |
| Quiet hours policy | _which alerts page at 03:00 and which wait for morning — decide now, not at 03:00_ |
