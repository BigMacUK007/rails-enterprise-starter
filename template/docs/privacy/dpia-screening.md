---
status: template
owner: ""
review_by: ""
---

# DPIA Screening

## How to complete this document

Work through the screening questions with the data inventory open. If any answer is
"yes", a Data Protection Impact Assessment (DPIA) is likely required before the relevant
processing starts; two or more "yes" answers make one clearly advisable. Record the
decision, the decision-maker and the date in the decision block.

**Gate: a recorded screening decision is required before this application goes to
production.** The control manifest carries this as a deferred control with an owner; the
installer's report will keep listing it until the decision below is recorded.

> This template supports evidence gathering; it does not by itself provide ISO 27001,
> SOC 2, Cyber Essentials, WCAG conformance or legal compliance. Whether a DPIA is legally
> required is a judgement for the controller, informed by ICO guidance.

## Screening questions

| # | Question | Yes/No | Notes |
|---|---|---|---|
| 1 | Systematic and extensive profiling or automated decision-making with significant effects? | | |
| 2 | Large-scale processing of special category or criminal offence data? | | |
| 3 | Systematic monitoring of a publicly accessible area, or tracking of individuals' behaviour or location? | | |
| 4 | Children's data, or data of other vulnerable individuals? | | Must match `data_risk.children_data` in `t40-manifest.yml` |
| 5 | Innovative technology or novel application of existing technology (including AI features)? | | Selecting the AI module is a strong trigger |
| 6 | Processing that could result in denial of a service, benefit or contract to individuals? | | |
| 7 | Matching or combining datasets from different sources? | | |
| 8 | Invisible processing — data not obtained from the individual, where privacy information is hard to provide? | | |
| 9 | Data transferred outside the UK/EEA? | | Must match `international-transfers.md` |
| 10 | Processing that could cause physical harm if breached (safety, safeguarding, security data)? | | |

## Decision

| Field | Value |
|---|---|
| Screening outcome | _DPIA required / DPIA not required_ |
| Rationale | |
| Decided by (name, role) | |
| Date | |
| DPIA document (if required) | _link — the DPIA itself is a separate document_ |
| Review trigger | New data categories, new modules (especially AI), new transfers, or 12 months |

If a DPIA is required, it must be completed — and any high residual risk resolved or
referred to the ICO — **before** the processing begins in production.
