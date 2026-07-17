---
status: template
owner: ""
review_by: ""
---

# Support Access

## How to complete this document

Confirm the procedure below matches your contract with the client (some clients require
prior consent per access; some accept notification), name who may grant support access,
and set `status: complete` with an owner and review date. The technical control is
implemented by the starter; this document sets the human rules around it.

> This template supports evidence gathering; it does not by itself provide ISO 27001,
> SOC 2, Cyber Essentials, WCAG conformance or legal compliance.

## Principle

T40 staff have **no standing access** to client accounts. Cross-account support access is
explicit, reasoned, time-limited and audited — every grant and every use leaves audit
evidence the client can inspect.

## How the control works

- A grant is created with a named staff member, a reason and an expiry:

  ```ruby
  SupportAccessGrant.grant!(
    account: account,
    staff_identity: staff,      # must be a staff identity (identity.staff?)
    granted_by: granting_owner, # who authorised it
    reason: "Investigating ticket #1234",
    duration: 4.hours           # default; shorter is better
  )
  ```

- Access is exercised only inside the grant block, which sets the impersonation context
  and records audit events around use:

  ```ruby
  SupportAccessGrant.with_grant(grant) do
    # support work as the account, with Current.impersonator set
  end
  ```

  `with_grant` raises unless the grant is active (`!revoked? && expires_at.future?`).
- Audit events written during support access carry `impersonator_id`, so client-visible
  history distinguishes staff actions from user actions.
- Early termination: `grant.revoke!(by: revoker)`. Compromise response:
  `Session.revoke_all_for(staff_identity)` per `incident-response.md`.

## Rules

| Rule | Value |
|---|---|
| Who may authorise a grant | _e.g. account owner (client) or named T40 service owner per contract_ |
| Client consent model | _prior consent per access / standing contractual consent with notification — cite the contract clause_ |
| Maximum duration | _e.g. 4 hours (the default); anything longer needs the service owner_ |
| Reason quality | Must reference a ticket or request — "debugging" alone is not a reason |
| Prohibited under support access | _e.g. data export beyond the ticket's need, role changes, entitlement changes — list per contract_ |
| Client visibility | _e.g. audit export available on request; proactive notification for SEV1 investigations_ |

## Review

Active and recent grants are reviewed in every access review
(see `access-review.md`). Any grant that outlived its reason is a finding.
