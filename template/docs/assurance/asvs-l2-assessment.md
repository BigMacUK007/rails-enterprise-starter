---
status: template
owner: ""
review_by: ""
---

# ASVS Level 2 Assessment (Risk-Tailored)

## How to complete this document

Every production release of this application requires a risk-tailored assessment against
OWASP ASVS Level 2. "Risk-tailored" means you assess the chapters that apply to this
application's actual attack surface, and you record every exclusion with a reason and,
where risk remains, a compensating control with an owner and expiry. Work chapter by
chapter against the current published ASVS 5.0 requirements (verify the chapter list
below against the version you assess with, and record that version), record the outcome,
then complete the sign-off block. This assessment is a deferred control in the control
manifest until first completed. Set `status: complete` with an owner and review date;
repeat for each major release or annually, whichever comes first.

> This template supports evidence gathering; it does not by itself provide ISO 27001,
> SOC 2, Cyber Essentials, WCAG conformance or legal compliance. A self-assessment is
> not an independent verification; state clearly which this is when sharing it.

## Assessment record

| Field | Value |
|---|---|
| ASVS version assessed against | _e.g. 5.0.0_ |
| Target level | Level 2, risk-tailored |
| Application release assessed | _`RELEASE_SHA` / version_ |
| Assessor (name, role) | |
| Assessment type | _self-assessment / independent_ |
| Date | |

## Starter baseline

The T40 Enterprise Application Starter implements applicable ASVS Level 1 controls plus
selected enterprise Level 2 controls out of the box (authentication, session management,
authorisation, tenancy, audit, logging, headers, uploads, job context — see
[assurance-matrix.md](assurance-matrix.md) for the control-by-control mapping). That
baseline is the starting point of this assessment, not its conclusion: project code,
integrations and deployment choices must be assessed on their own merits.

## Chapter-by-chapter outcome

For each chapter: **Applicable?** (yes/no with reason), **Outcome** (pass / findings /
excluded), and a link to notes or findings. Chapters follow ASVS 5.0 — confirm against
the published version you assess with.

| Chapter | Area | Applicable? | Outcome | Notes / findings |
|---|---|---|---|---|
| V1 | Encoding and Sanitisation | | | |
| V2 | Validation and Business Logic | | | |
| V3 | Web Frontend Security | | | |
| V4 | API and Web Service | _yes if the API module or any JSON endpoints are exposed_ | | |
| V5 | File Handling | | | _`has_secure_attachment` covers the baseline; assess project upload flows_ |
| V6 | Authentication | | | _passwordless magic-link; see ADR 0002_ |
| V7 | Session Management | | | |
| V8 | Authorization | | | _capability predicates + `authorize!`; include tenant boundary_ |
| V9 | Self-contained Tokens | _usually no — sessions are server-side records_ | | |
| V10 | OAuth and OIDC | _yes only if the OIDC module is installed_ | | |
| V11 | Cryptography | | | _starter invents no cryptography; assess any project use_ |
| V12 | Secure Communication | | | _TLS/HSTS enforced in production_ |
| V13 | Configuration | | | _boot validation, secret references, flags_ |
| V14 | Data Protection | | | _cross-reference the privacy set_ |
| V15 | Secure Coding and Architecture | | | |
| V16 | Security Logging and Error Handling | | | _structured logs, audit events, redaction_ |
| V17 | WebRTC | _usually no_ | | |

## Exclusions and compensating controls

Every "no" in the Applicable column and every requirement consciously not met belongs
here. An exclusion without a reason is a gap, not a decision.

| Ref (chapter/requirement) | Exclusion or finding | Reason | Compensating control | Owner | Expires / re-review |
|---|---|---|---|---|---|
| | | | | | |

## Findings and actions

| Finding | Severity | Action | Owner | Due | Done |
|---|---|---|---|---|---|
| | | | | | |

## Sign-off

| Field | Value |
|---|---|
| Overall outcome | _pass / pass with recorded exceptions / fail_ |
| Signed off by (name, role) | |
| Date | |
| Next assessment due | |
