---
status: template
owner: ""
review_by: ""
---

# International Transfer Register

## How to complete this document

Record every case where personal data leaves the UK (or EEA, where EU data is in scope):
the destination, the receiving party, and the legal safeguard relied on. Cross-check
against `subprocessors.md` — every subprocessor outside the UK/EEA needs a row here. If
there are no transfers, say so explicitly in the declaration below; "we haven't checked"
is not the same as "no transfers". Set `status: complete` with an owner and review date;
review on every new subprocessor, region change or integration.

> This template supports evidence gathering; it does not by itself provide ISO 27001,
> SOC 2, Cyber Essentials, WCAG conformance or legal compliance. Transfer mechanisms and
> adequacy decisions change; verify the current position when completing this register.

## Declaration

| Question | Answer |
|---|---|
| Does any personal data leave the UK? | _yes / no_ |
| Does any EEA-origin personal data leave the EEA? | _yes / no / not in scope_ |
| Verified by | _name, role_ |
| Date | |

## Transfer register

| Ref | Data categories | From | To (country) | Recipient | Mechanism | Risk assessment (TRA) done? | Evidence |
|---|---|---|---|---|---|---|---|
| TR-1 | _e.g. error metadata_ | UK | _country_ | _subprocessor_ | _UK adequacy / IDTA / EU SCCs + UK Addendum_ | _yes/no + link_ | _contract link_ |
| | | | | | | | |

## Mechanisms reference

- **UK adequacy regulations** — transfers to countries the UK has deemed adequate need no
  further safeguard, but record the reliance here.
- **IDTA** (International Data Transfer Agreement) or **EU SCCs with the UK Addendum** —
  contractual safeguards; a transfer risk assessment (TRA) should accompany them.
- **Derogations** (explicit consent, contract necessity) — narrow; record the reasoning
  if relied on.

## Hosting-region commitments

Record any contractual commitment to keep data in a specific region, and how the
deployment honours it (provider region settings, backup location, log platform region):

| Commitment | Source (contract clause) | How honoured | Verified |
|---|---|---|---|
| | | | |
