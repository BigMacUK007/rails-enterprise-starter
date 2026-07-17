---
status: template
owner: ""
review_by: ""
---

# Incident Response Runbook

## How to complete this document

Fill in the names, contact routes and escalation numbers before the first production
deployment — a runbook completed during an incident is not a runbook. Verify each
containment hook works in staging. Walk the team through the runbook once (a 30-minute
tabletop is enough to start). Set `status: complete` with an owner and review date;
re-verify the hooks after significant changes.

> This template supports evidence gathering; it does not by itself provide ISO 27001,
> SOC 2, Cyber Essentials, WCAG conformance or legal compliance.

## Roles

Fill in a name and a deputy for each role. One person may hold several roles in a small
team, but every role must have a holder during an incident.

| Role | Responsibility | Name | Deputy | Contact |
|---|---|---|---|---|
| Incident lead | Owns the incident, decides severity, directs response | | | |
| Technical lead | Hands on keyboard: containment, diagnosis, recovery | | | |
| Communications | Client, user and internal updates | | | |
| Scribe | Timeline and evidence log (timestamps everything) | | | |
| Privacy decision-maker | Personal-data breach assessment and ICO decision | | | |

## Severity levels

| Level | Definition | Response | Update cadence |
|---|---|---|---|
| SEV1 | Confirmed data breach, full outage, or active compromise | All roles engaged immediately, client informed | Hourly |
| SEV2 | Partial outage, suspected compromise, data integrity doubt | Incident lead + technical lead now | Every 4 hours |
| SEV3 | Degraded service, contained fault, no data at risk | Business hours | Daily |

## Triage (first 30 minutes)

1. Declare the incident: name an incident lead, open a timeline document, timestamp it.
2. Assign severity (above). When in doubt, choose the higher level.
3. Establish what is known: alerts firing (`alerts.md`), `/health/ready` output, error
   reports, recent deploys, recent audit events (`bin/rails t40:controls` for control
   state; audit via console).
4. Ask the breach question early: **could personal data be involved?** If yes or unknown,
   start the personal-data breach decision tree below in parallel — the 72-hour ICO
   window runs from awareness, not from confirmation.
5. Decide immediate containment (below). Prefer reversible actions first.

## Containment hooks

All hooks are pre-installed by the starter. Commands run in the production console or
environment.

| Action | When | How |
|---|---|---|
| Revoke all sessions for one identity | Suspected account compromise | `Session.revoke_all_for(identity)` in `bin/rails console` — destroys every session for the identity and records a `session.revoke_all` audit event |
| Revoke a support access grant | Suspicious or finished support access | `grant.revoke!(by: revoking_identity)` |
| Kill a risky feature | A feature or integration is misbehaving | Set the flag's `default: false` in `config/t40/feature-flags.yml` and redeploy/restart; `T40::Flags.enabled?` fails safe (false) for missing flags. Check state with `bin/rails t40:flags:report` |
| Maintenance mode (full stop) | Active compromise or data-integrity risk | Set `T40_MAINTENANCE=1` (or `touch tmp/maintenance.txt` on the host); app serves 503 maintenance page, health endpoints stay up. See `maintenance-mode.md` |
| Read-only mode (degrade writes) | Integrity doubt but reads are safe | Set `T40_READ_ONLY=1`; non-GET/HEAD requests are refused with 503 |
| Rotate application secrets | Secret exposure suspected | Rotate `SECRET_KEY_BASE` via `bin/rails credentials:edit` (invalidates all cookies/sessions), rotate `DATABASE_URL` credentials and SMTP credentials at the providers, redeploy. `config/t40/required-environment.yml` lists every secret reference |
| Block a tenant | One account is the source or target | Deactivate its users (`account.users.update!(active: false)`) — reversible; record the reason as an audit event |
| Restore from backup | Data loss or corruption | Follow `backup-restore.md` — do not improvise a restore |

## Evidence preservation

Do this **before** destructive recovery actions:

- Scribe keeps the timeline: every action, decision and observation, timestamped.
- Snapshot logs for the incident window (structured logs carry `request_id`,
  `account_id`, `identity_id` correlation).
- Export relevant audit evidence: `AuditEvent.export(account: affected_account)` —
  the export itself is audited.
- Take a database snapshot before restoring or mutating data.
- Preserve the compromised artefact (container image digest, `RELEASE_SHA`) rather than
  deleting it.

## Personal-data breach decision tree

Work through this with the privacy decision-maker. Document every answer and its time —
the assessment is evidence even when the answer is "no".

1. **Is personal data involved — accessed, disclosed, altered, lost or destroyed?**
   - No, confirmed → record the reasoning and return to the main runbook.
   - Yes or unknown → continue. **The 72-hour ICO assessment window started when anyone
     in the organisation became aware of the incident.** Note that time now.
2. **Establish scope:** whose data, what categories (check `../privacy/data-inventory.md`),
   how many subjects, what happened to it.
3. **Assess risk to individuals' rights and freedoms** (identity theft, financial loss,
   discrimination, distress, physical harm):
   - Risk unlikely → no ICO notification required, but **document the breach and the
     reasoning internally** — this record is mandatory.
   - Risk likely → **notify the ICO within 72 hours of awareness**, even if details are
     incomplete (a phased notification is acceptable). ico.org.uk, 0303 123 1113.
   - High risk to individuals → **also inform the affected individuals without undue
     delay**, in clear language: what happened, likely consequences, what they should do,
     who to contact.
4. **Controller/processor split:** if this application is operated as a processor, notify
   the controller (the client) without undue delay per `../privacy/processing-roles.md`
   and the contract — the controller owns the ICO decision in that case.
5. Record the final decision, decision-maker and time in the incident timeline.

## Recovery

- Restore service through the smallest safe step: fix forward, roll back the release, or
  restore data per `backup-restore.md`.
- Leave maintenance/read-only mode only when the technical lead confirms integrity.
- Rotate any credential that was, or may have been, exposed.
- Communications closes the loop with clients and users.

## Communication templates

_Prepare short skeletons here so nobody drafts from scratch at 3 a.m.:_

- **Internal declaration:** severity, what is known, roles, next update time.
- **Client holding statement:** what happened at a high level, what we are doing, when we
  will update next. No speculation, no premature root cause.
- **Individual breach notice (if high risk):** what happened, data involved, likely
  consequences, steps taken, steps they should take, contact point.

## Post-incident review

Hold the review within _e.g. 5 working days_ of closure. Blameless, written, actioned.
The review is not complete until each applicable item below has a merged change or a
ticket with an owner and date:

- [ ] Timeline agreed and stored with the incident record
- [ ] Root cause(s) identified — technical and process
- [ ] **Code** changes made (fixes, guard rails, new containment hooks)
- [ ] **Tests** added reproducing the failure (regression tests, abuse cases)
- [ ] **Threat model** updated (`../architecture/threat-model.md` — new threat rows or
      revised mitigations)
- [ ] **Runbooks** updated (this document, `alerts.md`, `backup-restore.md`)
- [ ] Alerts reviewed: did we detect this ourselves? If not, add the alert
- [ ] Retention/privacy documents updated if data handling changed
- [ ] Training or handover updated where a knowledge gap contributed
- [ ] Client follow-up commitments tracked to completion

## Incident log

| Ref | Opened | Severity | Summary | Breach assessment | ICO notified? | Closed | Review done |
|---|---|---|---|---|---|---|---|
| | | | | | | | |
