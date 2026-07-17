# Upgrade notes

Guidance for moving between starter releases. From v2 onwards every generated
application records its `starter_version` in `config/t40/control-manifest.yml`,
so you can always identify which starter release produced an application and
whether an upgrade note applies to it.

> This template supports evidence gathering; it does not by itself provide
> ISO 27001, SOC 2, Cyber Essentials, WCAG conformance or legal compliance.

## v1 → v2 (2.0.0)

v2 replaces the copy-by-hand v1 template with a manifest-driven installer
(`bin/setup-enterprise`) and an acceptance harness (`bin/acceptance`). There
is no automated in-place v1 → v2 migration: the v2 installer targets a fresh
Rails application. Applications generated from v1 should adopt the changes
below selectively, guided by their own test suites.

### Migration renumbering

The v1 migration set could not apply against an empty database because
foreign keys referenced tables created by later migrations. v2 renumbers the
set so `bin/rails db:migrate` succeeds from zero, in this order:

1. `create_accounts` (now includes `entitlements` jsonb, default `{}`)
2. `create_identities`
3. `create_users`
4. `create_sessions`
5. `create_magic_links`
6. `create_audit_events` (new in v2)
7. `create_support_access_grants` (new in v2)
8. `create_privacy_cases` (new in v2)
9. `create_active_storage_tables` (new in v2, with tenant binding)
10. `create_t40_job_executions` (new in v2)

The installer assigns fresh timestamps at install time and skips any
migration whose name already exists in `db/migrate/`, so re-applying never
duplicates a migration. **Do not re-run the renumbered migrations against an
existing v1 database.** Instead, diff your `db/schema.rb` against a fresh v2
application and write your own additive migrations for what is missing —
typically `accounts.entitlements`, the `audit_events`, `support_access_grants`,
`privacy_cases` and `t40_job_executions` tables, plus the tenant-bound Active
Storage schema.

### Managed-file upgrades

Every v2 install records source and installed hashes in
`config/t40/managed-files.yml`. On a later starter release, the installer uses
those hashes as a three-way merge boundary:

- a project-owned local change is preserved when the starter copy is unchanged;
- an untouched managed file is updated when only the starter copy changed; and
- competing project and starter edits fail closed as a conflict.

Marked edits remain bounded by their `t40:starter` markers. Review the plan
before applying an upgrade and commit the application first so any accepted
change has a project-level rollback path. Control evidence, owners and recorded
decisions are reconciled by control ID and retained when they remain valid.

Optional-module descriptors are now schema-versioned and must declare both a
conformance contract and required checks. An invalid or interface-only selected
module fails preflight.

### `Auditable` → `AuditEvent`

The v1 `Auditable` model concern referenced an `AuditLog` model that was
never shipped, and silently rescued audit failures. It has been removed.

Replace `include Auditable` with explicit event writing:

- `AuditEvent.record!(action:, target:, changes:)` — inside the business
  transaction for critical actions; it raises on failure, so a critical
  action cannot succeed without its audit evidence.
- `AuditEvent.record(...)` — for non-critical evidence; it logs the error and
  returns `nil` on failure.

Change summaries pass through `AuditEvent::Redactor` (sensitive keys
filtered, long values truncated, total size capped) — never pass raw request
parameters. Audit events are append-only: updates and destroys raise
`ActiveRecord::ReadOnlyRecord`. Audit export is itself audited.

### `ActivityTracking` removal

The v1 `ActivityTracking` controller concern referenced a missing
`UserActivity` model and captured raw request parameters and search text. It
has been removed and replaced by `ActivityEvents`
(`app/controllers/concerns/activity_events.rb`), which records explicit,
minimised events only: `record_activity(action, subject:, metadata:)` with
allowlisted metadata keys and a documented purpose and retention expectation.
Review any code that relied on automatic parameter capture and re-express it
as explicit events — broad capture of parameters and search queries is no
longer supported.

### Devise path removed

v1 documentation and the generated project guidance described Devise and
Pundit even though the implementation was passwordless. v2 removes every
trace of that path:

- `authentication.mode: passwordless` is the only valid core value in the
  manifest — there is no Devise option.
- Authorisation uses server-side default-deny capability predicates on
  `User::Role` (for example `can_manage_users?`), not Pundit policies.
- The generated `CLAUDE.md` is now derived from the manifest, so project
  guidance always matches the installed architecture.

If a project added Devise on top of v1, it is outside the starter's supported
path and its authentication controls are its own responsibility.

### Control manifest introduction

v2 records `config/t40/control-manifest.yml` in every generated application:
the starter version, the SHA-256 of the manifest that drove the install, the
install timestamp, and every core control with a status of `enabled`,
`verified`, `deferred` (always with an owner) or `not_applicable` (always
with a reason). Inspect it with `bin/rails t40:controls`.

Existing v1 applications have no control manifest. To adopt one, either run
the v2 installer against a fresh application and port your code onto the
result, or copy the catalogue from `lib/t40_starter/controls.yml` into
`config/t40/control-manifest.yml` and record each control's real status by
hand. The acceptance harness treats an invalid control manifest as a failure.

### Other v2 changes worth reviewing

- `config/routes_passwordless.rb` is gone. Session, magic-link and health
  routes are installed as a marked edit inside `config/routes.rb` between
  `# >>> t40:starter routes >>>` markers.
- Session lifetimes are now enforced: two weeks of inactivity or twelve weeks
  absolute lifetime ends a session on next resumption.
- Jobs gain tenant, actor and correlation context via `T40::JobContext`
  (installed into `ApplicationJob` by a marked edit); jobs that must not run
  without a tenant declare `requires_tenant!` and fail closed.
- Uploads use tenant-bound Active Storage records and private, expiring signed
  download routes. Existing public attachment URLs must be replaced.
- Privacy requests are durable `PrivacyCase` workflows; deletion and account
  offboarding must discharge their recorded retention and export obligations.
- Production releases use `t40:release_evidence` to generate an SPDX 2.3 SBOM
  and evidence record. Open high or critical findings block release unless an
  exact, owned, reasoned and unexpired exception exists in
  `config/t40/security-exceptions.yml`.
- Production boot now validates required configuration and fails fast with a
  pointer to `config/t40/required-environment.yml` — populate your secret
  references before deploying.
