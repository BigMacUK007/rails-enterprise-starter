---
status: template
owner: ""
review_by: ""
---

# Maintenance and Read-Only Modes

## How to complete this document

Confirm how each switch is set in **your** deployment (environment variable via the
hosting provider, or the marker file on the host), test both modes in staging, record who
may invoke them, and set `status: complete` with an owner and review date. These modes
are containment tools — the people named in
[incident-response.md](incident-response.md) must be able to use them without looking
anything up.

> This template supports evidence gathering; it does not by itself provide ISO 27001,
> SOC 2, Cyber Essentials, WCAG conformance or legal compliance.

## The two modes

Both are implemented by the starter (`T40::Runtime`, enforced by the `MaintenanceMode`
controller concern) and require no code change to activate.

| Mode | Effect | When to use |
|---|---|---|
| **Maintenance** | Every request except the health endpoints receives the maintenance page with HTTP 503 | Active compromise, data-integrity risk, restores, risky migrations — anything where continued traffic causes damage |
| **Read-only** | GET and HEAD requests are served normally; every other request is refused with HTTP 503 | Integrity doubt where reads are safe: investigating suspected bad writes, replication catch-up, pre-restore freeze |

Health endpoints (`/health/live`, `/health/ready`) stay up in both modes so the platform
does not kill or reroute the very instances you are trying to control.

## Switching

| Action | How |
|---|---|
| Enter maintenance mode | Set `T40_MAINTENANCE=1` and restart/redeploy, **or** `touch tmp/maintenance.txt` on every running host (takes effect without restart) |
| Leave maintenance mode | Unset `T40_MAINTENANCE` / remove `tmp/maintenance.txt` on every host |
| Enter read-only mode | Set `T40_READ_ONLY=1` and restart/redeploy |
| Leave read-only mode | Unset `T40_READ_ONLY` |

Record the concrete steps for this deployment (provider console path, CLI command, host
list):

| Step | Command / console path | Verified in staging on |
|---|---|---|
| Set environment variable in production | | |
| Touch/remove the marker file on all hosts | | |

Note: the marker file must be handled on **every** host; a forgotten host serves normal
traffic. The environment-variable route is preferred where the platform applies it to all
instances atomically.

## Rules

| Item | Value |
|---|---|
| Who may invoke either mode | _e.g. incident lead or technical lead per [incident-response.md](incident-response.md); on-call may invoke unilaterally for SEV1_ |
| Who confirms exit | Technical lead confirms integrity before leaving either mode |
| Client communication | _e.g. maintenance longer than 15 minutes triggers the client holding statement in [incident-response.md](incident-response.md)_ |
| Audit trail | Record entry and exit times and the reason in the incident timeline; planned maintenance is logged below |
| Background jobs | Workers keep running in both modes — pause or scale down workers separately if jobs must also stop (record how: _e.g. stop the worker service_) |

## Planned maintenance log

| Date | Window | Mode | Reason | Invoked by | Exited |
|---|---|---|---|---|---|
| | | | | | |
