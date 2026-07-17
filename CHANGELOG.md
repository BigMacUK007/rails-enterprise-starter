# Changelog

All notable changes to the T40 Enterprise Application Starter are documented
in this file. The starter uses semantic versioning, and every generated
application records its `starter_version` in `config/t40/control-manifest.yml`
(from v2 onwards), so applications affected by any release — including
security fixes — can always be identified.

## [2.0.0] — 2026-07-16

Complete rework of the starter around a manifest-driven installer and an
acceptance harness. The authoritative seam is now a fresh generated Rails
application after `bin/setup-enterprise` has completed — the starter is an
enterprise baseline that must prove itself through its acceptance suite.

> This template supports evidence gathering; it does not by itself provide
> ISO 27001, SOC 2, Cyber Essentials, WCAG conformance or legal compliance.

### Added

- **Installer** — `bin/setup-enterprise`, one canonical setup command with
  `preflight`, `plan`, `apply`, `verify` and `report` stages; interactive and
  manifest-driven non-interactive modes; `--json` machine-readable output;
  defined exit codes; idempotent re-apply; all-or-nothing conflict handling.
  The installer never writes secrets — it records secret references only.
- **Versioned manifest** (`t40-manifest.yml`, `manifest_version: 1`) covering
  project identity, tenancy mode, authentication mode, module selections,
  data-risk answers and deployment profile. Validation fails closed on unknown
  keys and unknown module names. `manifests/core.yml` is the default core
  manifest; `manifests/example-full.yml` is a documented example.
- **Control manifest** written into every generated application
  (`config/t40/control-manifest.yml`): starter version, manifest SHA-256,
  install timestamp and every core control recorded as `enabled`, `verified`,
  `deferred` (with owner) or `not_applicable` (with reason). Catalogue lives
  in `lib/t40_starter/controls.yml`; inspect with `bin/rails t40:controls`.
- **Audit evidence** — append-only `AuditEvent` model with transactional
  `record!` for critical actions, non-critical `record`, redacted size-capped
  change summaries (`AuditEvent::Redactor`) and audited export.
- **Tenancy and authorisation baseline** — `Account` with entitlements,
  `AccountScoped` concern, account context resolved strictly from
  authenticated membership, default-deny `Authorization` concern backed by
  role capability predicates, and a time-boxed, audited `SupportAccessGrant`
  flow for cross-account support access.
- **Session controls** — inactivity and absolute lifetimes, activity touch,
  per-session and global revocation (`Session.revoke_all_for`) with audit
  evidence, and session fixation reset on sign-in.
- **Job context** — `T40::JobContext` carries tenant, actor and correlation
  context through Active Job; `requires_tenant!` fails closed when tenant
  context is missing.
- **Privacy lifecycle** — `PrivacySubject` registry with export and erasure
  contracts, `SoftDeletable` (recoverability, not legal erasure) and
  `T40::Privacy` helpers.
- **Secure defaults** — Content Security Policy with report-only rollout,
  security headers, sensitive parameter filtering, secure attachment
  validation, structured JSON production logging with correlation,
  production boot-time configuration validation, maintenance and read-only
  modes, and `/health/live` plus `/health/ready` endpoints.
- **Feature flags** — `T40::Flags` with mandatory description, owner, removal
  date and safe default for every flag, kept separate from durable account
  entitlements.
- **Documentation pack** — generated templates for architecture (context,
  data flows, trust boundaries, threat model, ADRs), privacy (data inventory,
  processing roles, DPIA screening, retention, subject rights, subprocessors,
  international transfers, complaints), operations (ownership, incident
  response, backup/restore, disaster recovery, access review, support access,
  alerts, maintenance mode) and assurance (assurance matrix, ASVS L2
  assessment, role-capability matrix, accessibility checklist, release
  evidence).
- **Generated RSpec suite** biased towards abuse and failure cases:
  enumeration resistance, expired/reused/malformed codes, session revocation,
  tenant isolation, authorisation denial, audit append-only behaviour,
  redaction, job tenant context and passwordless sign-in through the browser
  seam.
- **Generated CI and supply chain** — `.github/workflows/ci.yml` (RuboCop,
  Brakeman, bundler-audit, pinned gitleaks secret scan, migrations-from-zero,
  RSpec), `release.yml` (SPDX SBOM generated and attached to each release as
  evidence), Dependabot configuration, `SECURITY.md` vulnerability disclosure
  policy and `public/.well-known/security.txt`.
- **Optional module interfaces** — `modules/{oidc,saml,scim,rls,api,webhooks,ai}`
  each ship a descriptor and a `MODULE.md` documenting purpose, selection
  rules, interface sketch and conformance tests. All are interface-only in
  2.0.0: selecting one fails preflight until an approved, funded client
  requirement implements it.
- **Acceptance harness** — `bin/acceptance` generates a fresh Rails
  application, installs the core manifest and proves preflight, plan safety,
  apply, idempotent re-apply, migration from zero, boot and health endpoints,
  the generated test suite, static security checks and control-manifest
  validity, writing machine-readable evidence to `tmp/acceptance/evidence.json`.
- **Durable installer recovery and safe upgrades** — explicit install states,
  persisted incomplete-apply recovery, a managed-file hash ledger with
  three-way upgrade decisions, control-evidence reconciliation and
  schema-versioned module conformance descriptors.
- **Account and session operations** — account chooser, active-session listing,
  individual/global revocation, audit evidence and a step-up authentication
  hook that fails production verification until its owner records a decision.
- **Tenant-safe runtime carriers** — fail-closed cache, storage, rate-limit and
  log context, tenant-bound private Active Storage downloads and negative
  cross-account request tests.
- **Operable background work** — idempotent job executions, retry policy,
  failed-job visibility and audited replay through a replaceable Solid Queue
  operations boundary.
- **Privacy workflows and observability** — durable subject-rights cases,
  offboarding obligations, parameter/log redaction, replaceable error reporting,
  dependency-aware readiness and operator alert documentation.
- **Phlex operational UI and accessibility evidence** — Phlex components for
  authentication and operator flows, keyboard/focus structural checks and a
  representative browser path. Automated evidence is explicitly not a WCAG
  conformance claim.
- **Release policy gate** — immutable CI action/container references, protected
  release environment, required-check verification, resolved Bundler SPDX 2.3
  SBOMs and machine-readable release evidence. High and critical findings block
  release unless an exact, owned, reasoned and unexpired exception is recorded.
- **Starter repository CI** — `.github/workflows/starter-ci.yml` runs the
  installer unit tests and the full acceptance harness against PostgreSQL 17.
- **Generated project guidance** — `CLAUDE.md` in the generated application is
  derived from the manifest, so agent guidance always matches the installed
  architecture.
- **Rake tasks** — `t40:bootstrap`, `t40:controls` and `t40:flags:report`.

### Changed

- Template migrations renumbered so every foreign key resolves when migrating
  from an empty database (`accounts` → `identities` → `users` → `sessions` →
  `magic_links` → `audit_events` → `support_access_grants` → `privacy_cases` →
  tenant-bound Active Storage → `t40_job_executions`).
- README rewritten: the "production-ready" claim is removed; the starter is
  described as an enterprise baseline proven by its acceptance suite, and the
  quick-start clone URL now points at the correct repository owner.
- Passwordless authentication preserved and extended: session expiry is
  enforced on resume, session activity is touched (rate-limited), and
  `reset_session` runs before every new session.
- `Current` extended with request and impersonator context, and account
  changes re-resolve the current user.

### Removed

- `Auditable` concern — it referenced a missing `AuditLog` model and silently
  rescued audit failures. Replaced by `AuditEvent`.
- `ActivityTracking` concern — it referenced a missing `UserActivity` model
  and captured raw request parameters and search text. Replaced by the
  explicit, minimised `ActivityEvents` concern.
- Static `template/CLAUDE.md` describing Devise and Pundit — replaced by a
  manifest-derived template that reflects the installed passwordless and
  capability-predicate architecture.
- `config/routes_passwordless.rb` — superseded by the installer's marked
  route edit in `config/routes.rb`.

### Upgrading

See [docs/upgrade-notes.md](docs/upgrade-notes.md) for v1 → v2 guidance.

## [1.0.0]

Initial Rails 8 enterprise starter template: passwordless magic-link
authentication, OKLCH design tokens and the baseline project structure that
v2 builds on.
