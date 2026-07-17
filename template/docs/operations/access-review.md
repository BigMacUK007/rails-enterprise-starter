---
status: template
owner: ""
review_by: ""
---

# Access Review

## How to complete this document

Set the cadence and the reviewer, run the first review, and log it. An access review
answers one question: **does everyone who has access still need exactly that access?**
Set `status: complete` with an owner and review date once the procedure is agreed and the
first review is logged.

> This template supports evidence gathering; it does not by itself provide ISO 27001,
> SOC 2, Cyber Essentials, WCAG conformance or legal compliance.

## Cadence and scope

| Item | Value |
|---|---|
| Cadence | _e.g. quarterly_ |
| Reviewer | _name — must be able to challenge, not just list_ |
| Trigger reviews | Staff leaver (same day), role change, incident, client request |

## What to review

| Scope | Where to look | What good looks like |
|---|---|---|
| Application users and roles | Per-account user lists (`User` records; roles owner/admin/member) | Every membership current; role matches responsibility; no orphaned owner accounts; leavers deactivated (`active: false`) |
| Staff support access | `SupportAccessGrant` records — active and recent | No active grant without a live reason; all past grants expired or revoked; usage matches the audit trail |
| Session hygiene | `Session.active` for privileged identities | No unexpected long-lived sessions; `Session.revoke_all_for(identity)` used for leavers |
| Hosting and database access | Provider IAM / user lists | Least privilege; MFA on; no shared accounts; no leavers |
| Repository and CI | Repo collaborators, secrets access | Write access is current team only; deploy secrets scoped |
| Secret manager | Vault/manager ACLs | Access matches `ownership.md` |
| Third-party consoles | Email, error reporting, DNS | As above |

## Procedure

1. Export or list current access for each scope above.
2. For each entry ask: still needed? least privilege? attributable to one person?
3. Revoke or downgrade anything that fails — revocation is the default when the answer
   is unclear; access can be re-granted, unnoticed access cannot be un-leaked.
4. Record findings and actions in the log. Actions get owners and dates.
5. Audit evidence: role changes and support-access changes are recorded as `AuditEvent`
   rows automatically; note anything reviewed outside the application manually.

## Review log

| Date | Reviewer | Scopes covered | Findings | Actions (owner, date) | Completed |
|---|---|---|---|---|---|
| | | | | | |
