---
status: accepted
owner: ""
review_by: ""
---

# 0003. Solid Queue for background work

Date: 2026-07-16
Status: Accepted

## Context

Background work needs durability, retry semantics, operator visibility and tenant
context. The traditional Rails answer (Sidekiq on Redis) adds a second datastore to
provision, secure, back up, monitor and include in every disaster-recovery and assurance
conversation. Rails 8 ships Solid Queue as the default Active Job backend, storing jobs
in the relational database with supervised workers and recurring-task support.

## Decision

Use Active Job with Solid Queue on PostgreSQL as the only production queue.

- No Redis and no Sidekiq in the core baseline; one datastore holds application data,
  queue state and cache (Solid Cache).
- Every job includes `T40::JobContext`, which serialises account, identity and
  correlation context into the payload and restores it into `Current` around `perform`.
  Jobs touching tenant data declare `requires_tenant!` and fail closed — discarded, not
  retried — when context is missing.
- Each job class declares its own `retry_on` / `discard_on` behaviour; failed jobs remain
  visible in Solid Queue's failed set and readiness reporting
  (`/health/ready` checks worker heartbeats), never silently dropped.
- External network writes run through idempotent jobs and produce audit evidence.

## Consequences

- Backup, restore and disaster recovery cover the queue for free because the queue is in
  PostgreSQL; the restore-test gate in `docs/operations/backup-restore.md` therefore
  proves queue recovery too.
- Job enqueue participates in database transactions, which removes the classic
  enqueue-before-commit race.
- Queue throughput is bounded by PostgreSQL; workloads beyond roughly thousands of jobs
  per second would need a dedicated broker — that is a superseding ADR, funded by the
  workload that needs it.
- Operators watch one system: queue depth, failed jobs and worker heartbeats are rows in
  the same database, surfaced through the alerts catalogue in `docs/operations/alerts.md`.
