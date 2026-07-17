---
status: template
owner: ""
review_by: ""
---

# Data-Protection Complaint Workflow

## How to complete this document

Name the contact route, the complaint owner and the deputy, confirm the workflow below
fits the project, and publish the contact route somewhere a data subject can find it
(privacy notice, application footer). Set `status: complete` with an owner and review
date. Every complaint received must be entered in the log, whatever its merit.

> This template supports evidence gathering; it does not by itself provide ISO 27001,
> SOC 2, Cyber Essentials, WCAG conformance or legal compliance.

## Contacts

| Role | Name | Route |
|---|---|---|
| Complaint owner | | _email/route_ |
| Deputy | | |
| Public contact route | | _e.g. privacy@example.com, published in the privacy notice_ |

## Workflow

Complaints move through these states, in order. Record every transition in the log.

1. **Receipt.** The complaint arrives by any route and is logged the same working day
   with a reference. If it is also a subject-rights request, additionally run
   `subject-rights.md` — the statutory clock for that request starts now.
2. **Acknowledgement — within 30 days of receipt, without exception.** Send the
   complainant an acknowledgement naming the reference, the owner and the expected
   next update. Sooner is better; 30 days is the ceiling, not the target.
3. **Investigation.** The owner establishes the facts: what data, what processing, what
   went wrong, whether a personal-data breach is involved. If a breach is suspected,
   invoke `../operations/incident-response.md` immediately — the ICO 72-hour assessment
   window runs from awareness, not from the end of the complaint process.
4. **Progress updates.** Update the complainant at least every _e.g. 14 days_ until
   resolution. Resolve without undue delay.
5. **Outcome.** Tell the complainant what was found, what has been changed, and their
   right to complain to the Information Commissioner's Office (ico.org.uk) and to seek a
   judicial remedy if they remain dissatisfied. Record remedial actions and feed
   systemic causes into the post-incident/improvement process.

## Escalation

- Suspected personal-data breach → `../operations/incident-response.md` (immediately).
- Complaint implicates the controller/processor boundary → the client contact in
  `processing-roles.md`.
- Complainant approaches the ICO directly → the complaint owner coordinates the response
  and preserves all records.

## Complaint log

| Ref | Received | Acknowledged (≤30 days) | Complainant | Summary | State | Updates sent | Outcome | Closed |
|---|---|---|---|---|---|---|---|---|
| | | | | | | | | |
