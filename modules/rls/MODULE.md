# Module: RLS (PostgreSQL Row-Level Security)

> **Not implemented in v2.0.0 — requires approved funded scope.** Selecting this module
> in `t40-manifest.yml` fails preflight by design: it requires an approved, funded
> client requirement; interface only in this release.

## Purpose

Add a database-enforced tenant boundary beneath the application's tenant controls.
The core baseline enforces tenancy in the application layer (`AccountScoped`,
membership-resolved `Current.account`, `authorize!` record checks, negative tests). RLS
adds defence in depth: PostgreSQL policies that refuse to return or mutate another
tenant's rows even if application code has a scoping bug. **RLS never replaces
application authorisation** — it is a second net, not a substitute for the first.

## Selection rules

Select this module when:

- The deployment profile is `high_assurance`, or a client's risk assessment explicitly
  requires database-level tenant isolation in a shared database.
- Data sensitivity (special category, financial, children's data flags in the manifest)
  makes a single application-layer bug an unacceptable failure mode.
- A procurement or regulatory review names database-level segregation as a requirement
  short of database-per-tenant (which is out of scope for the starter entirely).

Do not select it by default: RLS constrains how connections, roles, migrations and
console access work, and a misconfigured RLS deployment provides false assurance —
which is worse than documented application-layer-only enforcement.

## Interface sketch

- Migration helpers that, per tenant-owned table: `ENABLE ROW LEVEL SECURITY` **and**
  `FORCE ROW LEVEL SECURITY` (so the table owner is also subject to policies), plus a
  tenant policy comparing `account_id` to a per-connection setting
  (e.g. `current_setting('t40.account_id')`).
- A dedicated runtime database role that is **not** the table owner and does **not**
  hold `BYPASSRLS` or superuser; migrations run as a separate privileged role.
- Connection lifecycle: the application sets the tenant setting when `Current.account`
  is resolved and clears it on connection checkin; jobs set it from `T40::JobContext`.
  A missing setting yields zero rows — fail closed, never fall open.
- Documented, tested procedures for the places RLS bites operators: `bin/rails console`
  access, backups/restores, analytics queries and support access
  (`SupportAccessGrant.with_grant` sets the tenant setting like any other context).
- Global (non-tenant) tables are explicitly listed and excluded, mirroring the
  "documented global" convention in the audit schema.

## Conformance tests the module must add

Runtime-role behaviour is the heart of this module — tests must run against real
PostgreSQL with the real roles:

- As the runtime role, a query without the tenant setting returns zero rows and cannot
  insert/update/delete tenant rows (fail closed).
- As the runtime role with account A's setting, rows of account B are invisible and
  immutable — including through joins and aggregate queries.
- `FORCE ROW LEVEL SECURITY` is proven: the table-owning role is also policy-bound.
- The runtime role demonstrably lacks `BYPASSRLS`; a test asserts the role attributes
  and that a `BYPASSRLS` role is not what the application connects as.
- Policies survive `db:prepare` from zero (schema round-trip includes RLS DDL).
- Application-layer negative tests still pass unchanged — RLS is additive, and removing
  it must not be what makes the tenant-isolation suite green.
