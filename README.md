# T40 Enterprise Application Starter

**Version 2.0.0** — a manifest-driven installer that turns a fresh Rails 8.1 application into an enterprise baseline: passwordless authentication, multi-account tenancy, default-deny authorisation, append-only audit evidence, security headers, health endpoints, an operations and privacy documentation pack, CI pipelines and a recorded control manifest.

This is an enterprise baseline that must prove itself through its acceptance suite. Every claim in this README is backed by a check in `bin/acceptance` or the generated application's test suite — nothing here is asserted on trust.

> **What this starter does not claim.** This template supports evidence gathering; it does not by itself provide ISO 27001, SOC 2, Cyber Essentials, WCAG conformance or legal compliance. Certification and legal compliance require client-specific governance, contracts, operation and independent assessment. Generated documentation is a set of templates that each project must complete and own.

## Requirements

- Ruby 3.4+ and Rails 8.1 (`gem install rails`)
- PostgreSQL (the acceptance suite runs against PostgreSQL 17)

## Quick start

```bash
# 1. Get the starter
gh repo clone BigMacUK007/rails-enterprise-starter

# 2. Create a fresh Rails application
#    --skip-ci matters: the starter installs its own CI workflows, and the
#    installer never overwrites existing files.
rails new my-app -d postgresql --skip-ci

# 3. Run the installer interactively (asks project name, tenancy, modules,
#    data-risk questions, then writes t40-manifest.yml into the app)
cd rails-enterprise-starter
bin/setup-enterprise --target ../my-app

# Or non-interactively, from an existing manifest (agents, CI):
bin/setup-enterprise --target ../my-app --manifest manifests/core.yml --yes
```

After installation:

```bash
cd ../my-app
bin/rails db:prepare
ADMIN_EMAIL=you@example.com ACCOUNT_NAME="My Account" bin/rails t40:bootstrap
bin/rails server
```

## The installer

`bin/setup-enterprise [STAGE] [options]` runs one user-facing workflow in five stages. With no stage argument it runs the whole workflow (preflight → plan → confirm → apply → verify → report).

| Stage | What it does |
|-------|--------------|
| `preflight` | Non-destructive checks: Rails ≥ 8.1, PostgreSQL adapter, Ruby ≥ 3.4, Bundler present, conflict scan, marked-edit anchors exist, selected modules installable. A dirty git worktree is a warning, not a failure. |
| `plan` | Prints every intended action (`create`, `skip`, `edit`, `project_owned`, `noop`, `conflict`) and applies nothing. |
| `apply` | Copies template files, renders manifest-derived files, applies marked edits, runs `bundle install`. All-or-nothing: any conflict aborts before a single write. |
| `verify` | In the target app: `db:prepare`, eager load, RSpec, RuboCop, Brakeman, bundler-audit. |
| `report` | Human summary: changed capabilities, verification evidence, deferred decisions with owners, required human follow-up. |

Options: `--manifest PATH`, `--target DIR`, `--json` (machine-readable stage output), `--yes` (skip confirmation), `--version`.

Exit codes: `0` success · `1` usage or manifest error · `2` preflight failure · `3` apply conflict · `4` verify failure · `5` incomplete apply.

Guarantees:

- **Idempotent** — re-running apply with the same manifest makes zero changes and says so.
- **Project-safe upgrades** — a managed-file hash ledger preserves project-owned
  changes, updates untouched starter-owned files, and reports competing edits as
  conflicts before writing anything.
- **No secrets** — the installer writes secret *references* only (`config/t40/required-environment.yml`). It never writes credentials.

Apply records `installed_unverified` in the generated installation state. Only a
successful verify stage advances that state to `installation_verified`. Neither
state claims the client application is production-ready: deferred governance,
backup, identity and release gates must be discharged separately.

## The manifest

Installation is driven by a versioned manifest (`t40-manifest.yml`). Interactive runs write it for you; agents and CI supply one. `manifests/core.yml` is the default core manifest and `manifests/example-full.yml` is a documented example.

```yaml
manifest_version: 1
project:
  name: "My App"
  identifier: "my-app"
tenancy:
  mode: multi_account        # multi_account | single_account
authentication:
  mode: passwordless         # the only core mode in v2
modules:                     # all default false; all interface-only in v2.0.0
  oidc: false
  saml: false
  scim: false
  rls: false
  api: false
  webhooks: false
  ai: false
data_risk:                   # all required — they drive the control manifest
  personal_data: true
  special_category_data: false
  children_data: false
  financial_data: false
deployment:
  profile: standard          # standard | high_assurance
```

Unknown keys and unknown module names fail validation — the installer fails closed rather than guessing.

## The control manifest

Every install records `config/t40/control-manifest.yml` in the generated application: the starter version, the SHA-256 of the manifest that drove the install, the install timestamp, and every core control with its status:

| Status | Meaning |
|--------|---------|
| `enabled` | Installed and active by default |
| `verified` | Confirmed by the verify stage, with evidence |
| `deferred` | Requires a project decision — always has a named owner |
| `not_applicable` | Excluded, always with a recorded reason |

Inspect it with `bin/rails t40:controls`. The acceptance harness fails if any control has an invalid status or a deferred control has no owner.

### Core controls (summary)

| Category | Examples |
|----------|----------|
| Authentication | Short-lived single-use codes, anti-enumeration, rate limits, step-up (deferred) |
| Sessions | Rotation on sign-in, individual and global revocation, inactivity + absolute lifetimes, secure cookie flags |
| Tenancy | Account foreign keys and indexes, tenant context in jobs, time-boxed audited support access |
| Authorisation | Server-side default-deny capability predicates, cross-account record checks, negative tests |
| Audit | Append-only `AuditEvent`, redacted change summaries, critical audit in transaction, audited export |
| Privacy | Parameter filtering, subject-rights extension points, DPIA screening (deferred), data inventory and retention (deferred) |
| Uploads | Private storage, declared + detected type validation, size limits, signed URLs |
| Headers | CSP with report-only rollout, HSTS, frame denial, nosniff, referrer and permissions policies |
| Jobs | Tenant/actor/correlation context propagation, fail-closed missing tenant, failed-job visibility |
| Observability | Structured JSON production logs with correlation, `/health/live` and `/health/ready`, error-reporting adapter (deferred) |
| Backup & delivery | Backup and restore-test gate (deferred), maintenance and read-only modes, CI security checks, SBOM, branch protection (deferred) |
| Incident & accessibility | `security.txt` + vulnerability disclosure policy, incident runbook, WCAG 2.2 AA checklist, ASVS L2 assessment (deferred) |

The full catalogue lives in `lib/t40_starter/controls.yml`; the generated `docs/assurance/assurance-matrix.md` maps controls to implementation, test, owner and evidence.

## Optional modules

All modules are **interface only** in v2.0.0: each ships a `module.yml` descriptor and a `MODULE.md` defining its interface, selection rules and conformance tests. Selecting one in a manifest fails preflight with a pointer to its MODULE.md — implementation requires an approved, funded client requirement.

| Module | Status in 2.0.0 | Purpose |
|--------|-----------------|---------|
| `oidc` | interface only | Enterprise SSO — federated identities keyed by issuer + subject, never email |
| `saml` | interface only | SAML SSO for customers whose IdP requires it |
| `scim` | interface only | Automated user provisioning and deprovisioning |
| `rls` | interface only | PostgreSQL row-level security as defence in depth (never replacing app authorisation) |
| `api` | interface only | Versioned public API with scoped, tenant-bound credentials and an OpenAPI description |
| `webhooks` | interface only | Signed inbound/outbound webhooks with replay windows and idempotent consumers |
| `ai` | interface only | Governed AI gateway — deterministic policy authorises, typed allowlisted tools, kill switch |

## Authentication: passwordless magic links

**No passwords. No Devise. No authentication gems.** The 37signals pattern from Fizzy/Basecamp, in vanilla Rails:

1. User enters their email → receives a **6-character single-use code** (15-minute expiry).
2. User enters the code → session created with a signed, httponly cookie.
3. The code is destroyed on consumption; the session is rotated on sign-in.

### Architecture

```
Identity (global — one per person)
├── email_address (unique)
├── sessions (active sign-ins, individually and globally revocable)
├── magic_links (single-use codes)
└── users (one per account)

User (account-scoped membership)
├── account_id
├── identity_id
├── role: owner | admin | member
└── capability predicates (can_manage_users?, can_export_data?, …)
```

### Security behaviours

| Behaviour | Implementation |
|-----------|---------------|
| Anti-enumeration | Unknown emails get the same code page as known emails |
| Timing safety | `ActiveSupport::SecurityUtils.secure_compare` |
| Rate limiting | 10 requests/3 min (email), 10 attempts/15 min (code) |
| Single-use codes | `SecureRandom` generated, destroyed on consumption |
| Session fixation | `reset_session` before every new session |
| Session lifetimes | 2 weeks inactivity, 12 weeks absolute |
| Revocation | Per-session and global (`Session.revoke_all_for(identity)`), audited |
| Cookies | Signed, httponly, `same_site: :lax`, Secure in production |

### Key files (in the generated application)

```
app/models/identity.rb                                # global person
app/models/user.rb                                    # account membership
app/models/user/role.rb                               # roles + capability predicates
app/models/magic_link.rb                              # single-use codes
app/models/session.rb                                 # sessions + lifetimes + revocation
app/models/current.rb                                 # request-scoped context
app/models/audit_event.rb                             # append-only audit evidence
app/controllers/concerns/authentication.rb            # session resumption + expiry
app/controllers/concerns/account_scoping.rb           # tenant resolution from membership
app/controllers/concerns/authorization.rb             # default-deny capability checks
app/controllers/sessions_controller.rb                # email entry
app/controllers/sessions/magic_links_controller.rb    # code verification
```

## What lands in a generated application

- **Models and concerns** — `Account` (with entitlements), `AuditEvent` (append-only, redacted), `SupportAccessGrant`, `AccountScoped`, `SoftDeletable`, `PrivacySubject`, `SecureAttachments`.
- **Controllers and config** — account scoping, authorisation, maintenance/read-only modes, health endpoints, security headers, parameter filtering, structured production logging, boot validation, feature flags with owners and removal dates.
- **Jobs** — `T40::JobContext` carries tenant/actor/correlation into every job; `requires_tenant!` fails closed.
- **RSpec suite** — models, requests, jobs and system specs, biased towards abuse and failure cases (enumeration, expired/reused codes, cross-tenant access, audit append-only, redaction).
- **Documentation pack** — `docs/` templates for architecture, threat model, privacy (data inventory, DPIA screening, subject rights, complaints), operations (incident response, backup/restore, support access, alerts) and assurance (assurance matrix, role-capability matrix, ASVS L2 assessment, accessibility checklist). Each is a template the project must complete.
- **CI and supply chain** — `.github/workflows/ci.yml` (lint, Brakeman, bundler-audit, gitleaks, migrations-from-zero, tests), `release.yml` (required-check and protected-environment gate, resolved SPDX 2.3 SBOM and release evidence), Dependabot config, `SECURITY.md` and `public/.well-known/security.txt`.
- **Project guidance** — a generated `CLAUDE.md` derived from your manifest, so agent guidance always matches the installed architecture.
- **Rake tasks** — `t40:bootstrap`, `t40:controls`, `t40:flags:report` and
  `t40:release_evidence`.

## Acceptance harness

`bin/acceptance` is the authority on whether the starter works. It generates a fresh Rails app, installs the core manifest and proves the result end to end:

1. `rails new` (PostgreSQL) in `tmp/acceptance/`
2. Preflight passes
3. Plan applies nothing (file snapshot proof)
4. Apply succeeds
5. Re-apply is idempotent (second plan all noop/skip, zero file changes)
6. Databases prepare from zero
7. Two concurrent consumers can use a magic-link code at most once
8. The app eager-loads, boots, and answers `/health/live`, `/health/ready` and `/up`
9. Authentication, account/session operations, tenant isolation, audit export,
   failed-job visibility and replay pass through request/browser seams
10. The complete generated RSpec suite passes
11. RuboCop, Brakeman and bundler-audit pass
12. An SPDX 2.3 SBOM and release-evidence record are generated and validated
13. The control manifest is present and internally valid
14. Machine-readable evidence written to `tmp/acceptance/evidence.json`

```bash
bin/acceptance                    # full run (needs local PostgreSQL + rails on PATH)
bin/acceptance --fast             # skip RuboCop and Brakeman
bin/acceptance --skip-fresh --keep  # iterate against the same generated app
```

Any failure exits non-zero and keeps the generated app for inspection. The same harness runs in this repository's CI (`.github/workflows/starter-ci.yml`) against PostgreSQL 17, alongside the installer's unit tests (`ruby -Ilib -Itest test/all.rb`).

## Repository layout

```
bin/setup-enterprise            # canonical installer CLI
bin/acceptance                  # acceptance harness
lib/t40_starter/                # installer implementation + control catalogue
manifests/                      # core.yml + documented example manifest
template/                       # core baseline — mirrors a generated app root
modules/<name>/                 # module descriptors + MODULE.md interfaces
test/                           # installer unit tests (plain minitest)
docs/specs/                     # the v2 specification
docs/upgrade-notes.md           # upgrade path between starter versions
.scratch/t40-enterprise-application-starter-v2/issues/ # approved local tickets
.github/workflows/starter-ci.yml  # this repository's own CI (unit tests + acceptance)
CHANGELOG.md                    # release history
VERSION                         # current starter version (recorded in every install)
```

## Upgrading

The starter uses semantic versioning; every generated application records `starter_version` in its control manifest, so you can always tell which starter release produced an app. See [docs/upgrade-notes.md](docs/upgrade-notes.md) for the v1 → v2 changes (migration renumbering, `Auditable` → `AuditEvent`, activity-tracking replacement, removal of the Devise migration path, control manifest introduction).

## Licence

MIT — use freely for your projects.
