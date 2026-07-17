---
status: template
owner: ""
review_by: ""
---

# Security Policy

## How to complete this document

Replace the placeholder contact address with a monitored mailbox (and update
`public/.well-known/security.txt` to match — including its `Expires:` date), confirm the
scope and response targets fit this project, name the security contact in
`docs/operations/ownership.md`, then remove this section and set `status: complete` in
the frontmatter with an owner and review date. Publish nothing until the contact route is
actually monitored: an unread security mailbox is worse than none.

## Reporting a vulnerability

If you believe you have found a security vulnerability in this application, please
report it to us privately:

- **Email:** security@example.com _(placeholder — replace before production)_
- Alternatively, use the contact in
  [`/.well-known/security.txt`](/.well-known/security.txt).

Please include enough detail for us to reproduce the issue: the affected URL or
component, steps to reproduce, and the impact you believe it has. Please do not include
anyone's personal data in a report; use test accounts where possible.

Please do not open a public issue for a security vulnerability, and please do not
disclose the issue publicly until we have had a reasonable opportunity to fix it.

## Scope

In scope:

- This application and its API endpoints (where present)
- Authentication, session, authorisation and tenant-isolation behaviour
- File upload and export functionality

Out of scope:

- Denial-of-service and volumetric attacks
- Social engineering, phishing and physical attacks
- Findings that require a compromised device or network position
- Third-party services we use but do not operate (report those to the provider)
- Automated scanner output without a demonstrated impact

## Our response

| Stage | Target |
|---|---|
| Acknowledgement of your report | Within 3 working days |
| Initial assessment and severity | Within 10 working days |
| Progress updates | At least every 14 days until resolution |
| Fix or mitigation for confirmed critical/high issues | Prioritised ahead of feature work; timescale communicated in the initial assessment |

We will tell you when the issue is fixed, and we are happy to credit you if you would
like (tell us the name or handle to use).

## Safe harbour

We will not pursue legal action or report you for good-faith security research that
respects this policy: act in good faith, avoid privacy violations and service
disruption, do not access or modify data beyond what is needed to demonstrate the issue,
do not exfiltrate data, and give us a reasonable time to remediate before any public
disclosure. If in doubt, ask first via the contact above.

## No bounty

This is a coordinated disclosure policy, not a bug bounty programme. We do not offer
financial rewards by default. We value and credit good-faith reports.
