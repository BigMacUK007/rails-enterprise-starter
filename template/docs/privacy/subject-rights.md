---
status: template
owner: ""
review_by: ""
---

# Subject Rights Handling

## How to complete this document

Record how this application fulfils each data-subject right: who receives requests, how
identity is verified, which code paths produce the data or perform the change, and the
timescale. The starter provides the technical hooks; the project must wire every model
holding personal data into them and name the humans in the process. Set
`status: complete` with an owner and review date.

> This template supports evidence gathering; it does not by itself provide ISO 27001,
> SOC 2, Cyber Essentials, WCAG conformance or legal compliance. Statutory response
> deadlines apply from receipt of a request — under UK GDPR, generally one calendar
> month, extendable for complex requests.

## Technical hooks provided by the starter

- Models holding personal data `include PrivacySubject` and implement `privacy_export`
  (returns a hash) and `privacy_erase!` (irreversible, records an audit event).
  `PrivacySubject.registered_models` lists everything wired in.
- `T40::Privacy.export_for(identity)` aggregates exports for an identity;
  `T40::Privacy.erasure_candidate?(identity)` supports the erasure decision.
- `Identity` ships with a real implementation: export covers email and session metadata;
  erasure anonymises the email address, destroys sessions and magic links, and records an
  audit event.
- Soft deletion (`SoftDeletable`) is recoverability, **not** erasure. Only
  `privacy_erase!` counts as erasure.
- Erasure and export actions are themselves audited (`AuditEvent`), so rights handling
  produces its own evidence.

**Project obligation:** every new model that stores personal data must `include
PrivacySubject` and implement both methods. List them here as they are added:

| Model | privacy_export covers | privacy_erase! behaviour |
|---|---|---|
| `Identity` | Email address, session metadata | Anonymises email, destroys sessions and magic links, audited |
| _Project model_ | | |

## Rights procedures

| Right | How fulfilled | Code path / route | Responsible | Timescale |
|---|---|---|---|---|
| Access / portability (export) | Compile export for the identity | `T40::Privacy.export_for(identity)` via console or admin action | _name/role_ | One month |
| Rectification | Correct the data at source | Standard edit routes; audited where critical | _name/role_ | One month |
| Erasure | Assess, then erase irreversibly | `T40::Privacy.erasure_candidate?` then `privacy_erase!` per model | _name/role_ | One month |
| Restriction | Suspend processing for the subject | _project mechanism — e.g. deactivate `User` memberships, flag record_ | _name/role_ | One month |
| Objection | Assess and stop the contested processing | _project mechanism_ | _name/role_ | One month |
| Not to be subject to automated decisions | _state whether any solely automated decisions exist_ | _n/a or project mechanism_ | _name/role_ | |

## Process

1. **Receive.** Requests arrive at _contact route_. Log the request below.
2. **Verify identity.** _State the method — e.g. request must come from, or be confirmed
   via, the registered email address (a magic-link round trip verifies control of it)._
3. **Assess.** Confirm scope, check for exemptions and legal holds
   (see `retention.md`), decide the action. Erasure requests: check
   `erasure_candidate?` and record the reasoning, including handling of audit evidence
   (audit rows may be retained where a legal basis exists — record the basis).
4. **Act.** Execute through the code paths above. Never hand-edit production data.
5. **Respond.** Confirm the outcome to the subject within the statutory window.
6. **Evidence.** The audit trail plus the log below is the evidence.

## Request log

| Ref | Received | Subject | Right | Verified | Outcome | Completed | Handled by |
|---|---|---|---|---|---|---|---|
| | | | | | | | |
