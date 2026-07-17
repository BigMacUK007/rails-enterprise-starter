---
date: 2026-07-14
type: implementation-spec
status: implemented
project: T40 Enterprise Application Starter v2
repository: https://github.com/BigMacUK007/rails-enterprise-starter
issue_tracker_status: pending-github-authentication
owner: Ben Macdonald
source_standard: "[[2026-07-14-t40-enterprise-application-starter-standard]]"
source_research:
  - "[[2026-07-14-enterprise-agentic-tools-applied-notes]]"
  - "[[2026-07-14-enterprise-boilerplate-security-controls-research]]"
  - "[[2026-07-14-enterprise-application-architecture-research]]"
labels:
  - implemented
  - specification
---

# T40 Enterprise Application Starter v2

## Problem Statement

T40 builds client tools that repeatedly need the same enterprise foundations: authentication, account isolation, authorisation, audit evidence, privacy controls, secure delivery, observability and operational documentation.

The current Rails Enterprise Starter contains useful authentication, account, role, audit and design patterns, but it is not a complete or verified enterprise boilerplate. Important referenced models are missing, there is no automated test suite or CI pipeline, privacy and data-lifecycle controls are absent, and the generated guidance conflicts with the current passwordless architecture. The repository also describes itself as production-ready before it can prove that claim.

Starting each application without a complete baseline creates four problems:

1. Security and compliance controls are added late, when they cost more to retrofit.
2. Client procurement questions require fresh research and manual evidence gathering.
3. Authentication, tenancy, logging and operational patterns drift between projects.
4. T40 risks over-engineering some tools while missing basic controls in others.

T40 needs one reusable Rails starter that installs the required core controls, records which optional controls were selected, verifies the generated application through a single high-level test seam and leaves client-specific legal, contractual and regulated decisions explicit.

The starter must make the safe path the easy path. It must not claim that code alone supplies ISO 27001 certification, SOC 2 assurance, Cyber Essentials certification or legal compliance.

## Solution

Evolve the existing Rails Enterprise Starter into **T40 Enterprise Application Starter v2**.

The starter will create a Rails 8 modular monolith using PostgreSQL, Hotwire, Solid Queue and the T40 Rails design system. It will support two delivery layers:

1. **Core baseline**: installed and verified for every application.
2. **Optional modules**: enabled only when the client, risk profile or paid scope requires them.

Regulated-sector requirements will use project-specific extension packs and assessments rather than being presented as universal compliance.

The primary product interface will be one idempotent setup command driven by an installation manifest. The command will:

1. inspect the target Rails application;
2. validate prerequisites and identify conflicts;
3. show the proposed changes;
4. install the selected controls and documentation;
5. run migrations, tests and security checks;
6. write a control manifest recording what is enabled, deferred or not applicable;
7. return a clear success or failure result.

The highest testing seam will be the generated application. A clean Rails application must be able to run the setup command, migrate, boot and pass the generated acceptance suite. Module-level tests will support this seam but will not replace it.

The first release will deliver the full core baseline and the extension interfaces. Enterprise identity, stronger database isolation, advanced availability, AI controls and regulated-sector modules will be installed only when selected and implemented only where there is an approved requirement.

## User Stories

1. As a T40 developer, I want to create a new enterprise-ready Rails application from one starter, so that I do not rebuild the same foundations for every client.
2. As a T40 developer, I want the starter to inspect an existing Rails application before changing it, so that client code and local decisions are not overwritten.
3. As a T40 developer, I want to preview the proposed installation, so that I can review conflicts and selected modules before files or dependencies change.
4. As a T40 developer, I want the setup process to be idempotent, so that rerunning it does not duplicate migrations, routes, dependencies or configuration.
5. As a T40 developer, I want an installation manifest, so that the selected controls can be reproduced in another environment or project.
6. As a T40 developer, I want a generated control manifest, so that I can see which enterprise controls are enabled, deferred or not applicable.
7. As a T40 developer, I want the installer to fail clearly when a prerequisite is missing, so that a partial installation is not mistaken for a secure application.
8. As a T40 developer, I want safe defaults for all security-sensitive settings, so that omission fails closed rather than weakening the application.
9. As a T40 developer, I want one modular monolith by default, so that the system remains simple to build, test, deploy and support.
10. As a T40 developer, I want domain modules with intentional interfaces, so that the application can grow without becoming a collection of controller callbacks and generic service objects.
11. As a T40 developer, I want external providers behind small adapters, so that identity, mail, storage, integrations and AI providers can change without infecting the domain model.
12. As a T40 developer, I want long-running and retried work to use background jobs, so that HTTP requests remain responsive and side effects are observable.
13. As a T40 developer, I want background jobs to be idempotent and tenant-aware, so that retries do not duplicate work or cross account boundaries.
14. As a T40 developer, I want failed jobs to be visible and actionable, so that operational failures do not disappear into logs.
15. As an application owner, I want a global identity separated from account membership, so that one person can belong to several client accounts without duplicating credentials.
16. As an account owner, I want users to have explicit account-scoped roles, so that access matches their responsibility within my organisation.
17. As an account owner, I want privileged actions to require stronger authentication, so that a compromised email account is not enough to administer the system.
18. As a user, I want passwordless sign-in with short-lived, single-use codes, so that I can access the application without maintaining another password.
19. As a user, I want active sessions to be visible and revocable, so that I can remove access from a lost or untrusted device.
20. As an administrator, I want to revoke all sessions for an identity, so that suspected account compromise can be contained quickly.
21. As a security reviewer, I want sign-in, recovery and verification endpoints rate-limited, so that automated abuse is constrained.
22. As a security reviewer, I want anti-enumeration behaviour, so that attackers cannot use authentication responses to discover valid accounts.
23. As a security reviewer, I want secure cookies, session expiry and re-authentication for sensitive actions, so that a stolen session has limited value.
24. As an enterprise customer, I want OpenID Connect available as an optional identity module, so that staff can sign in through our identity provider.
25. As an enterprise customer, I want SAML available only when required, so that the application can support older enterprise identity providers without burdening every project.
26. As an enterprise customer, I want SCIM provisioning available as a separately scoped module, so that joiner, mover and leaver changes can be automated when needed.
27. As a security reviewer, I want federated identities keyed by issuer and subject rather than email, so that mutable email addresses do not become identity keys.
28. As an account owner, I want default-deny authorisation enforced on the server, so that hidden buttons are never treated as security controls.
29. As a developer, I want reusable capability checks for controllers, jobs, exports and integrations, so that authorisation is consistent across entry points.
30. As a security reviewer, I want automated negative authorisation tests, so that forbidden record, field and tenant access is proved to fail.
31. As an enterprise customer, I want every tenant-owned record, job, cache entry, stored object and audit event associated with the correct account, so that tenant boundaries are consistent across the system.
32. As a security reviewer, I want database constraints and tenant-scoped uniqueness, so that application mistakes cannot silently create cross-account ambiguity.
33. As a security reviewer, I want PostgreSQL row-level security available as optional defence in depth, so that higher-risk shared-database deployments can add a database boundary.
34. As an operator, I want support access to be explicit, time-limited and audited, so that T40 can help a client without granting permanent unscoped access.
35. As an enterprise customer, I want an append-only audit trail of important actions, so that I can investigate changes and demonstrate control.
36. As a security reviewer, I want critical audit events written reliably with the business action or through a transactional outbox, so that failed logging cannot silently erase evidence.
37. As a privacy lead, I want secrets and sensitive payloads excluded from audit and operational logs, so that the evidence system does not create another data leak.
38. As an enterprise customer, I want audit records to include actor, tenant, action, target, result and correlation identifiers, so that an event can be reconstructed.
39. As an enterprise customer, I want audit records exportable, so that approved evidence can be supplied to our monitoring or assurance process.
40. As a privacy lead, I want each project to record its data inventory, classification, purpose, lawful basis and retention rules, so that privacy decisions are made before launch.
41. As a privacy lead, I want reusable export, correction, retention and erasure hooks, so that subject-rights workflows can be implemented without redesigning the application.
42. As a privacy lead, I want soft deletion distinguished from legal erasure, so that recoverability is not mistaken for deletion compliance.
43. As a privacy lead, I want a clear data-protection complaint workflow, so that complaints can be acknowledged within 30 days and resolved without undue delay.
44. As a privacy lead, I want DPIA screening included in project setup, so that high-risk processing is identified before production.
45. As a privacy lead, I want subprocessor, hosting-region and international-transfer records, so that client disclosures and contracts use current facts.
46. As a developer, I want secure upload defaults, so that files are private, size-limited, type-checked and unable to execute as application code.
47. As a developer, I want secrets loaded from a secret manager, so that credentials are not stored in source control, build artefacts or logs.
48. As a security reviewer, I want TLS, HSTS, Content Security Policy, safe headers and strict CORS defaults, so that browser and transport protections are present from the first deployment.
49. As a developer, I want versioned API conventions and OpenAPI support available when an API is selected, so that external contracts are explicit and testable.
50. As an integration developer, I want signed webhooks with replay protection and idempotent consumers, so that delivery retries and hostile requests are handled safely.
51. As an integration developer, I want webhook delivery history, retry limits and operator replay, so that integration failures can be diagnosed without mutating the original event.
52. As an operator, I want structured logs with request, job, tenant and release correlation, so that failures can be traced across the application.
53. As an operator, I want central error reporting, health checks, readiness checks and dependency visibility, so that incidents are detected before a client reports them.
54. As an operator, I want alerts to name an owner and response route, so that monitoring produces action rather than noise.
55. As an operator, I want encrypted backups with documented recovery objectives, so that the recovery promise is explicit.
56. As an operator, I want scheduled restore tests, so that successful backup jobs are not mistaken for proven recovery.
57. As an operator, I want safe maintenance and read-only modes, so that service can degrade without causing further damage.
58. As a developer, I want separate development, test, staging and production configuration, so that credentials and data cannot drift across environments.
59. As a developer, I want feature flags to have safe defaults, owners and removal dates, so that temporary release controls do not become permanent debris.
60. As a product owner, I want durable customer entitlements separated from release flags, so that purchased capabilities are not controlled by temporary engineering switches.
61. As a release owner, I want protected branches, peer review and non-bypassable checks, so that production changes are attributable and reviewed.
62. As a release owner, I want tests, static analysis, dependency checks, secret scanning and migration checks on every change, so that common failures are blocked before release.
63. As a release owner, I want untrusted pull requests isolated from trusted runners and secrets, so that a contribution cannot compromise the delivery pipeline.
64. As a procurement reviewer, I want a software bill of materials generated from the resolved release artefact, so that shipped dependencies are known.
65. As a procurement reviewer, I want release evidence retained with the release identifier, so that a deployment can be linked to tests, approvals and the software bill of materials.
66. As a security reviewer, I want the reusable starter to implement applicable ASVS Level 1 controls and selected enterprise Level 2 controls, so that every project begins above a documented floor.
67. As a security reviewer, I want each production project assessed against a risk-tailored ASVS Level 2 profile, so that project-specific requirements and exceptions are explicit.
68. As an incident lead, I want a monitored vulnerability-disclosure route and security contact, so that external researchers can report problems safely.
69. As an incident lead, I want session revocation, key rotation, kill switches, evidence export and restore hooks, so that common containment actions are available under pressure.
70. As a privacy lead, I want breach decision points and the applicable ICO notification window in the runbook, so that regulatory decisions are not improvised during an incident.
71. As an incident lead, I want post-incident reviews to update code, tests, threat models and runbooks, so that the system learns from failures.
72. As an accessibility reviewer, I want WCAG 2.2 AA checks and manual-test guidance, so that automated tools are not treated as proof of accessibility.
73. As a client procurement reviewer, I want a consistent assurance pack, so that architecture, privacy, security, recovery and support evidence can be reviewed efficiently.
74. As a T40 developer, I want documentation templates for threat models, data flows, DPIA screening, retention, incidents, backups and access reviews, so that evidence is created during delivery rather than after it.
75. As a T40 developer, I want generated project instructions to match the installed authentication, authorisation and module choices, so that agents do not follow stale guidance.
76. As a T40 developer, I want the starter documentation to state what code cannot certify, so that T40 does not overclaim ISO 27001, SOC 2, Cyber Essentials or legal compliance.
77. As an AI feature owner, I want AI controls absent from non-AI applications, so that ordinary applications do not inherit unnecessary dependencies or risk.
78. As an AI feature owner, I want a model gateway when AI is enabled, so that provider, model, region, budget and fallback policies are centralised.
79. As an AI feature owner, I want prompts, tools, models and evaluations versioned, so that a material AI result can be reproduced and reviewed.
80. As a security reviewer, I want AI tools allowlisted and least-privilege, so that a model cannot invent or expand its own authority.
81. As a security reviewer, I want deterministic policy code to authorise proposed AI actions, so that a model is never the final security boundary.
82. As a human approver, I want approvals bound to the exact action and parameters, so that my approval cannot be reused for a different side effect.
83. As an AI feature owner, I want maximum steps, time, spend and retry limits, so that loops and unbounded consumption fail safely.
84. As an AI feature owner, I want evaluation fixtures and regression tests, so that model, prompt and provider changes do not silently weaken the capability.
85. As a client user, I want a human override and kill switch for AI behaviour, so that automation remains subordinate to accountable human control.
86. As a developer, I want the starter to generate a working application that migrates, boots and passes its acceptance suite, so that installation success is proved rather than narrated.
87. As a developer, I want the installer to print a concise completion report with evidence, so that I can see what changed and what still needs a client decision.
88. As a maintainer, I want the starter version recorded in generated applications, so that upgrades and security notices can target affected projects.
89. As a maintainer, I want a documented upgrade path between starter releases, so that client applications can adopt fixes without being regenerated.
90. As Ben, I want the boilerplate improved through paid client delivery rather than detached platform work, so that the reusable asset grows without distracting from H2 revenue and control priorities.

## Implementation Decisions

### Product boundary

- The existing Rails Enterprise Starter repository will be evolved. A second competing starter will not be created.
- The deliverable is a reusable installer, templates, generated documentation and an acceptance harness. It is not a hosted platform or a complete client product.
- The first release delivers the complete core baseline. Optional modules have explicit interfaces and selection rules, but complex modules are implemented only when an approved requirement funds them.
- Existing uncommitted authentication work must be preserved and reconciled before implementation begins. The implementation agent must not reset or overwrite the current worktree.
- The repository description will stop using “production-ready” until the acceptance suite and release gates prove that claim.

### Primary testing seam

- The primary seam is a fresh generated Rails application after the setup command has completed.
- Acceptance is based on external behaviour: the application installs, migrates, boots, authenticates users, enforces tenant and role boundaries, records safe audit evidence, runs background work, exposes health state and passes security checks.
- The installer itself will expose preflight, plan, apply, verify and report stages, but these remain parts of one user-facing setup workflow.
- Module-level tests are permitted for complex failure behaviour, but the generated-application acceptance suite remains authoritative.

### Application architecture

- Use Rails 8 or the currently supported Rails 8 minor release, PostgreSQL, Hotwire and Solid Queue.
- Use a modular monolith with domain-named modules and intentional public entry points.
- Do not create microservices, Rails Engines, event brokers or generic abstraction layers without demonstrated reuse, isolation or scaling needs.
- Keep the client’s existing line-of-business system authoritative where applicable. Store workflow state, immutable external identifiers, synchronisation state and reconciliation evidence rather than creating an ungoverned second system of record.
- External network writes run through idempotent background jobs and produce audit evidence.
- Use the T40 Rails frontend standard: vanilla CSS, Phlex components and the approved Basecamp-inspired design system. Do not add Tailwind, shadcn or a React frontend layer by default.

### Installation model

- Provide one canonical setup command that can be run interactively by a person or non-interactively by an agent.
- Drive non-interactive installation from a versioned manifest containing project identity, tenancy mode, authentication mode, selected modules, data-risk answers and deployment profile.
- The installer performs a non-destructive preflight and reports existing files, routes, dependencies, migrations and configuration that would conflict.
- A plan or dry-run mode shows intended changes before applying them.
- Re-running the installer with the same manifest produces no duplicate resources or configuration.
- The installer records its version and the selected control set in the generated application.
- Completion output lists changed capabilities, verification results, deferred decisions and required human follow-up.
- The installer never writes credentials or secrets. It generates secret references and environment requirements only.

### Core domain and tenancy

- Retain `Identity` as the global person and `User` as the account-scoped membership to match the current T40 Rails vocabulary.
- `Account` is the tenant root. Every tenant-owned record carries a non-null account reference unless explicitly documented as global.
- Add foreign keys, account-scoped unique indexes and constraints for tenant-owned relationships.
- Resolve account context from an authenticated membership. Do not trust an unverified route, header or form parameter as tenant authority.
- Carry account context into background jobs, audit events, cache keys, object-storage paths, rate limits and structured logs.
- Cross-account support actions use an explicit support-access flow with time limit, reason and audit evidence.
- PostgreSQL row-level security is an optional module. It must test runtime roles, table ownership, bypass privileges and forced policy behaviour and must not replace application authorisation.

### Authentication and session controls

- Passwordless magic-link authentication remains the local default.
- Codes are short-lived, single-use and generated with a cryptographically secure source.
- Authentication responses resist account enumeration and timing disclosure.
- Rate limits cover login request, code verification, recovery and enrolment paths without enabling permanent attacker-triggered lockout.
- Sessions are server-verifiable, rotated on authentication, individually revocable and globally revocable by identity.
- Session cookies are Secure, HttpOnly and appropriately SameSite in production with enforced HTTPS.
- Sessions have explicit inactivity and absolute lifetimes selected by project risk.
- Sensitive and administrative actions support step-up authentication.
- Privileged users require a phishing-resistant second factor or an enterprise identity provider that enforces it. The starter uses a maintained standards-based implementation and does not invent authentication cryptography.
- OIDC is the first enterprise SSO module. External identities are keyed by issuer and subject.
- SAML and SCIM are separate paid modules because they require customer-specific conformance and operating support.

### Authorisation

- Use server-side default-deny authorisation.
- Keep the T40 role hierarchy of owner, admin and member as the default, while allowing project-specific domain capabilities.
- Do not add Pundit by default. Use explicit capability methods and domain predicates at controllers, jobs, exports and integration entry points.
- UI visibility is a convenience and never the authorisation boundary.
- Generate a role and capability matrix that projects must complete.
- Provide negative test helpers for function, record, field and tenant boundaries.
- Destructive, financial, bulk export, support and high-risk actions can require a second actor or explicit approval.

### Audit and activity evidence

- Replace the incomplete `AuditLog` callback pattern with a dedicated `AuditEvent` model and event-writing interface.
- Audit events include tenant, actor, impersonator where relevant, action, target, result, reason, time, release and correlation identifiers, plus a safe size-limited change summary.
- Normal application users cannot update or delete audit records.
- Critical actions write audit evidence in the same transaction or through a transactional outbox. Critical audit failure cannot be silently rescued while the business action succeeds.
- Audit access and export are themselves audited.
- Operational logs and business audit events remain separate because they have different audiences, retention and sensitivity.
- Remove generic capture of raw request parameters and search queries. Activity analytics use explicit minimised event schemas with a documented purpose and retention period.

### Privacy and data lifecycle

- Generate templates for data inventory, classification, controller and processor roles, lawful basis, purpose, retention, subprocessor and international-transfer decisions.
- Provide a DPIA screening workflow and require a project decision before production.
- Provide extension points and examples for export, correction, restriction, retention, legal hold, erasure and irreversible anonymisation.
- Treat soft deletion as recoverability, not proof of erasure.
- Provide a data-protection complaint workflow with receipt, acknowledgement, investigation, progress and outcome states.
- Provide account offboarding hooks for export, access revocation, retention and eventual deletion.
- Keep secrets, tokens, authentication codes, unnecessary personal data and full sensitive payloads out of logs and audit records.
- Use synthetic or approved irreversibly sanitised data outside production.

### Secure data handling and browser controls

- Enforce TLS and production HTTPS.
- Supply safe defaults for HSTS, Content Security Policy, frame restrictions, content-type protection, referrer policy and CORS.
- Roll Content Security Policy out through a report-only phase where existing integrations require tuning.
- Store uploads privately, validate declared and detected type, enforce size limits and prevent execution.
- Generate short-lived signed download URLs where direct object access is required.
- Use managed encryption at rest and purpose-built secret storage. Field-level encryption is reserved for selected high-risk values.
- Filter sensitive parameters and use explicit log schemas.

### APIs, webhooks and integrations

- Public APIs and webhook management are installable modules, not unused default endpoints.
- APIs use an explicit compatibility policy, scoped tenant-bound credentials, bounded pagination, stable errors, rate limits, request identifiers and an OpenAPI description.
- Do not expose Active Record models as the external contract.
- Webhook receivers verify the provider’s documented signature over the raw payload, enforce replay limits, record delivery identifiers and process asynchronously.
- Webhook consumers are idempotent.
- Outbound webhooks have per-endpoint secrets, bounded retries, delivery status, disable controls and operator replay.
- Bidirectional synchronisation requires explicit ownership, ordering, deletion and conflict rules and is separately scoped.

### Background work

- Use Active Job with Solid Queue as the default production queue.
- Jobs accept stable identifiers, reload state and are safe to retry.
- Jobs carry tenant, initiating actor and correlation context.
- Each job class declares timeout, retry, discard and maximum-attempt behaviour.
- Failed and blocked jobs are visible to operators, with alerts for backlog age and failure rate.
- Use a transactional outbox when a database change and external delivery must not diverge.
- Do not add a workflow engine until a paid use case proves that explicit state and jobs are insufficient.

### Observability and operations

- Emit structured logs with time, environment, release, request or job identifier, tenant, actor where justified, operation, duration, outcome and safe error class.
- Provide central exception-reporting integration behind a replaceable adapter.
- Provide liveness and dependency-aware readiness checks with guidance on what should and should not fail deployment health.
- Expose metrics for traffic, latency, errors, database calls, background jobs and external dependencies.
- Preserve OpenTelemetry-compatible correlation fields. Full exporter and collector deployment is optional until a backend is selected.
- Every alert has a threshold, owner, response route and runbook link.
- Provide safe maintenance and read-only modes for incident containment.

### Reliability, backup and recovery

- Require automated encrypted database backups and object-storage protection.
- Each generated project records its recovery point and recovery time objectives.
- Generate restore, migration recovery and disaster-recovery runbooks.
- Require a real restore test before production and on a scheduled cadence thereafter.
- External dependencies use timeouts, bounded retries and controlled fallback.
- Multi-zone or multi-region designs are selected only when a contracted service level funds them.

### Configuration, flags and entitlements

- Keep development, test, staging and production data, credentials, keys, buckets, integrations and webhooks separate.
- Validate required production configuration at startup and fail without safe secret references.
- Keep temporary feature flags separate from durable account entitlements.
- Feature flags have a safe default, owner and removal date.
- Risky integrations and AI capabilities have kill switches.
- Use an OpenFeature-compatible provider only when targeting or provider portability is required.

### Secure delivery and software supply chain

- Add a CI pipeline that runs application tests, tenant and authorisation tests, Brakeman, dependency vulnerability checks, secret scanning and migration-safety checks on every pull request.
- Add container and infrastructure scanning when those artefacts exist.
- Protect the default branch and require review and successful checks before release.
- Keep untrusted contributions away from trusted runners and secrets.
- Build one immutable release artefact and promote that artefact through environments.
- Generate an SPDX or CycloneDX software bill of materials from the resolved release artefact and retain it with release evidence.
- Keep lockfiles and automate controlled dependency updates.
- Signed artefacts, provenance and higher SLSA assurance remain optional until a customer or distribution model requires them.

### Incident and vulnerability response

- Generate a monitored vulnerability-disclosure route and standard security contact file.
- Provide incident roles, severity levels, triage, containment, evidence preservation, recovery and communication templates.
- Provide technical hooks for session revocation, credential and key rotation, integration or feature shutdown, maintenance mode and restore.
- Include personal-data-breach decision points and the applicable regulatory timing.
- Require a post-incident review that updates code, tests, threat models, runbooks and training.
- Vulnerability exceptions have an owner, rationale, compensating control and expiry date.

### Accessibility

- Target WCAG 2.2 AA.
- Include automated accessibility checks in the acceptance suite.
- Generate a manual-test checklist for keyboard, focus, zoom, contrast, screen-reader and error-message behaviour.
- Do not describe automated checks as proof of conformance.

### AI control module

- Install no AI dependency unless the AI module is selected.
- Route model calls through one internal gateway with approved provider, model, region, retention, budget, timeout and fallback policy.
- Version prompts, tools, model configuration, retrieval configuration and evaluation sets.
- Keep retrieval and memory tenant-isolated and apply retention rules.
- Validate structured outputs before they enter deterministic application logic.
- The model proposes, deterministic policy code authorises, and a constrained executor performs.
- Tools are typed, allowlisted, least-privilege and read-only by default.
- Human approval is short-lived and bound to the exact action and parameters.
- AI runs have maximum steps, wall time, spend, retries and recursion.
- Material changes run quality, safety, refusal and abuse-case evaluations.
- Human override, correction and kill switches are mandatory.
- The AI module generates model, prompt, tool, evaluation and human-control records for the assurance pack.

### Documentation and assurance

- Generate project-specific templates for architecture context, data flows, trust boundaries, threat model, security requirements and architectural decisions.
- Generate privacy templates for data inventory, processing roles, DPIA screening, retention, subject rights, subprocessors and international transfers.
- Generate operational templates for ownership, incidents, breaches, backup, restore, disaster recovery and access review.
- Generate an assurance matrix that maps applicable controls to implementation, test, owner, evidence and status.
- The reusable starter implements applicable ASVS Level 1 controls plus selected enterprise Level 2 controls.
- Every client production release completes a risk-tailored ASVS Level 2 assessment with exclusions and compensating controls recorded.
- Generated project instructions reflect the actual selected architecture. They must not mention Devise or Pundit when passwordless authentication and role predicates are installed.
- Documentation states that certification and legal compliance require client-specific governance, contracts, operation and independent assessment.

### Versioning and maintenance

- Use semantic starter releases and record the installed version in generated applications.
- Maintain upgrade notes for schema, configuration, control and dependency changes.
- Security fixes identify which starter versions and generated applications are affected.
- Reusable improvements should come from real project evidence and be folded back after client confidentiality and licensing checks.

## Testing Decisions

### Testing philosophy

- Tests assert external behaviour and security outcomes rather than private methods or incidental file structure.
- The highest seam is the generated Rails application after installation. A passing unit test cannot compensate for an installer that produces an application that does not boot.
- Security tests favour negative and abuse cases, especially tenant isolation, authorisation, authentication, export, logging and external side effects.
- The acceptance suite must produce machine-readable evidence suitable for the generated control manifest and CI.
- Tests must not depend on live paid services. Identity, email, storage, monitoring, external systems and AI providers use local fakes or contract fixtures at the boundary.

### Modules under test

- Installer preflight, plan, apply, verify and report behaviour.
- Manifest parsing, validation, safe defaults and reproducibility.
- Core identity, account, user and session behaviours.
- Passwordless login, code expiry, single use, anti-enumeration and rate limits.
- Session rotation, expiry, revocation and global sign-out.
- Role, capability, record, field and tenant authorisation.
- Tenant context in requests, jobs, caches, storage and audit events.
- Audit event creation, redaction, append-only behaviour, export and critical failure handling.
- Privacy extension points for export, retention, erasure, legal hold, complaint and offboarding.
- Upload validation and private storage behaviour.
- Security headers, CSP, CORS and sensitive parameter filtering.
- Background-job idempotency, bounded retries, dead-job visibility and tenant context.
- Structured logging, correlation, redaction, health and readiness behaviour.
- Feature-flag safe defaults, expiry metadata and separation from entitlements.
- API authentication, authorisation, rate limits, pagination and error contracts when installed.
- Webhook signature, replay, idempotency, retry and operator replay when installed.
- OIDC issuer and subject identity mapping when installed.
- PostgreSQL RLS runtime-role and bypass behaviour when installed.
- AI gateway policy, tenant isolation, schema validation, tool allowlists, approval binding, limits, evaluations and kill switches when installed.
- CI security checks, release evidence and software bill of materials generation.
- Generated documentation and control-manifest completeness.
- Accessibility checks and the generated manual-test checklist.

### Primary acceptance flow

1. Create a clean supported Rails application with PostgreSQL.
2. Run the installer in plan mode and confirm that it reports changes without applying them.
3. Apply the core manifest non-interactively.
4. Reapply the same manifest and prove idempotency.
5. Create and migrate the databases.
6. Boot the web and background-job processes.
7. Run the complete generated test suite.
8. Run linting and security scans.
9. Exercise passwordless authentication and session revocation through the browser seam.
10. Exercise account and role boundaries through request and job seams.
11. Trigger a critical audited action and verify redacted evidence.
12. Trigger a failed job and verify operator visibility.
13. Verify health, readiness, safe headers and log correlation.
14. Generate release evidence, control manifest and software bill of materials.
15. Return a non-zero result if any required control or verification step fails.

### Required abuse and failure tests

- Unknown and known authentication addresses produce non-enumerating responses.
- Expired, reused, malformed and repeatedly guessed codes fail safely.
- Revoked and expired sessions cannot be resumed.
- A member cannot perform an owner or administrator action.
- A user cannot read, mutate, export, cache, enqueue or infer another account’s data.
- A background job with missing or invalid tenant context fails closed.
- An audit-critical action cannot succeed without reliable audit evidence.
- Secrets, tokens, codes, passwords and configured sensitive fields never appear in logs or audit exports.
- A malicious upload cannot execute or become public.
- A webhook with a bad signature, stale timestamp or duplicate identifier is rejected or handled idempotently.
- An untrusted pull request cannot read trusted secrets or use a privileged release path.
- An AI tool request outside the allowlist or approved parameters is denied by deterministic policy.
- A failed backup restore exercise blocks production readiness.

### Prior art

- The current starter’s passwordless identity, magic-link, session and role implementation is the migration seed, not proof of correctness.
- 37signals Fizzy and the T40 SSP Compliance Tracker remain behavioural references for Rails architecture and user flows.
- Rails’ official security, Active Job and deployment guidance governs framework behaviour.
- The T40 Enterprise Application Starter Standard defines the control floor and release evidence.
- OWASP ASVS 5.0, OWASP SAMM 2.2, NIST SSDF 1.1, NIST incident-response guidance and the NCSC Software Security Code of Practice define the assurance references.

### Definition of ready

- A clean supported Rails application installs the core manifest without manual repair.
- Re-running installation is idempotent.
- The generated application migrates, boots and processes background jobs.
- Core system, request, job and browser tests pass.
- Tenant and authorisation negative tests pass.
- Brakeman, dependency, secret and migration checks pass with no unapproved critical or high finding.
- The generated software bill of materials matches the resolved release artefact.
- Critical actions create complete redacted audit evidence.
- Operational logs contain correlation but no prohibited sensitive fields.
- Privacy, threat-model, incident, backup and assurance templates are generated and internally consistent.
- A restore exercise is documented before any application is described as production-ready.
- Optional modules add and pass their own conformance tests when selected.
- The control manifest identifies every core control as enabled, verified, deferred with owner, or not applicable with reason.
- Generated guidance matches the installed architecture.

## Out of Scope

- Building a hosted T40 platform or internal developer portal.
- Microservices, service mesh, Kubernetes or a generic event-streaming platform.
- Multi-region active-active infrastructure without a funded contractual requirement.
- A universal multi-cloud abstraction.
- A general identity broker or support for every identity provider in the first release.
- SAML, SCIM, database-per-tenant and customer-managed encryption keys without an approved client requirement.
- A generic workflow engine, master-data-management system or bidirectional synchronisation framework.
- A bespoke SIEM, observability backend or feature-management product.
- A public API, webhook portal or partner developer portal unless the corresponding module is selected.
- Long-term AI memory, autonomous write agents, multi-agent delegation, fine-tuning on client data or self-modifying tools in the core starter.
- Local or self-hosted model infrastructure without a justified workload.
- Full automation of every data-subject request for unknown future domain models.
- A claim that generated code provides ISO 27001 certification, SOC 2 assurance, Cyber Essentials certification, WCAG conformance or legal compliance.
- Sector-specific legal conclusions for finance, health, children, payments, law enforcement, critical infrastructure or overseas jurisdictions.
- Replacing client legal, privacy, security or procurement review.
- Rewriting the starter around React, Tailwind, shadcn or another frontend stack.
- Overwriting the current uncommitted authentication work.
- Committing, pushing or releasing implementation changes as part of this specification.

## Further Notes

- **Gatekeeper verdict:** CONDITIONAL. The reusable standard is aligned because it reduces paid-delivery rework and procurement friction. Implementation must be tied to the next approved enterprise build or a tightly bounded enabling sprint. It must not become a detached platform programme.
- The expected seam is the setup command plus the externally observable generated application. This is the narrowest high-value seam and should remain authoritative unless implementation reveals a genuine boundary that cannot be tested there.
- The current repository has uncommitted authentication work that forms the protected v2 baseline. No stale Git index lock was present when implementation began; agents must still preserve the worktree without reset or cleanup.
- The current README contains an old repository owner in its quick-start command and overstates production readiness. Both are implementation defects covered by this spec.
- The current generated project guidance describes Devise and Pundit despite the passwordless and predicate-based default. Generated guidance must be derived from the selected manifest.
- The current audit and activity concerns reference missing models. The activity concern also captures broad request parameters and search text. The v2 design replaces this with explicit minimised evidence schemas.
- GitHub issue publication remains pending because GitHub CLI and browser sessions were not authenticated on the originating host. The approved issue set is tracked locally under `.scratch/t40-enterprise-application-starter-v2/issues/` and was completed against the final machine-readable acceptance run.
