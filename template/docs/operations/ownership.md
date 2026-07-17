---
status: template
owner: ""
review_by: ""
---

# Service Ownership

## How to complete this document

Every system, control and escalation route needs a named owner — a person, not a team.
Fill in the tables, confirm each named person knows they hold the role, and set
`status: complete` with an owner and review date. Review whenever people join or leave,
and at least annually. Deferred controls in `config/t40/control-manifest.yml` name owners
too — keep them consistent with this document.

> This template supports evidence gathering; it does not by itself provide ISO 27001,
> SOC 2, Cyber Essentials, WCAG conformance or legal compliance.

## Service roles

| Role | Responsibility | Name | Deputy |
|---|---|---|---|
| Service owner | Accountable for the service and the client relationship | | |
| Technical owner | Architecture, code, deployments | | |
| Security contact | Receives reports via `SECURITY.md` / `security.txt`; owns triage | | |
| Privacy contact | Subject rights, complaints, breach assessment | | |
| Operations / on-call | Alerts, incidents, maintenance windows | | |

## System ownership

| System | Owner | Access held by | Notes |
|---|---|---|---|
| Production hosting account | | | MFA required |
| Production database | | | |
| DNS and domains | | | |
| Email provider account | | | Sign-in depends on it |
| Error reporting backend | | | Deferred until backend selected |
| Source repository and CI | | | Branch protection owner |
| Secret manager | | | `config/t40/required-environment.yml` lists required references |

## Deferred-control owners

Copy the deferred controls from `config/t40/control-manifest.yml` (or run
`bin/rails t40:controls`) and confirm each has a live owner:

| Control | Owner | Target date |
|---|---|---|
| _e.g. step-up authentication_ | | |
| _e.g. error reporting backend selection_ | | |
| _e.g. backups + restore test_ | | |
| _e.g. branch protection_ | | |
| _e.g. DPIA screening decision_ | | |

## Escalation

| Situation | First contact | Escalation |
|---|---|---|
| Security report received | Security contact | Service owner |
| Suspected breach | Incident lead per `incident-response.md` | Privacy contact + client |
| Client-impacting outage | On-call | Service owner |
