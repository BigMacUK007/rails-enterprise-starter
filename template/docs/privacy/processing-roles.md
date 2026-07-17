---
status: template
owner: ""
review_by: ""
---

# Processing Roles: Controller and Processor

## How to complete this document

For each processing activity, record who decides the purposes and means (the controller)
and who processes on instruction (the processor). In a typical T40 engagement the client
organisation is the controller of its users' and customers' data, and T40 (or the hosting
arrangement) acts as processor — but this must be established per project and reflected in
the contract, not assumed. Confirm the determinations below with whoever owns the client
contract, ensure a data-processing agreement exists where required, then set
`status: complete` with an owner and review date.

> This template supports evidence gathering; it does not by itself provide ISO 27001,
> SOC 2, Cyber Essentials, WCAG conformance or legal compliance. Role determinations have
> contractual and legal consequences — confirm them with legal advice where there is any
> doubt.

## Parties

| Party | Legal entity | Role(s) | Contract / DPA reference |
|---|---|---|---|
| Client | _name_ | _e.g. controller_ | _link_ |
| T40 Digital | _entity_ | _e.g. processor_ | _link_ |
| Hosting provider | _name_ | _e.g. subprocessor_ | see `subprocessors.md` |
| Email provider | _name_ | _e.g. subprocessor_ | see `subprocessors.md` |

## Determination per processing activity

| Processing activity | Data categories (from `data-inventory.md`) | Controller | Processor(s) | Notes |
|---|---|---|---|---|
| User authentication and session management | Identity data, session data, sign-in codes | _party_ | _party_ | |
| Audit evidence recording and export | Audit evidence | _party_ | _party_ | Export only through the approved audited route |
| Support access to client accounts | Support access records, client data viewed | _party_ | _party_ | Governed by `../operations/support-access.md` |
| _Project activity_ | | | | |

## Processor obligations checklist

Where T40 acts as processor, confirm each obligation is met and evidenced:

- [ ] Written contract / DPA covering the processing (Article 28 terms)
- [ ] Processing only on documented controller instructions
- [ ] Confidentiality commitments for people with access
- [ ] Security measures documented (this assurance pack)
- [ ] Subprocessors authorised and listed in `subprocessors.md`
- [ ] Assistance with subject rights (`subject-rights.md`) agreed
- [ ] Breach notification route and timing agreed (see `../operations/incident-response.md`)
- [ ] Deletion or return of data at contract end (see account offboarding in `retention.md`)
