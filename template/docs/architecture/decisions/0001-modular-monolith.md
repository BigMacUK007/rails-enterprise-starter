---
status: accepted
owner: ""
review_by: ""
---

# 0001. Modular monolith on Rails 8

Date: 2026-07-16
Status: Accepted

## Context

T40 client applications are CRUD-heavy business tools operated by small teams. They need
enterprise controls (tenancy, authorisation, audit, privacy, observability) far more than
they need independent deployability. Microservices, Rails Engines, event brokers and
generic service layers each add operational surface, failure modes and assurance scope
that a small delivery team must then own for the life of the contract. At the same time,
an unstructured monolith degrades into controller callbacks and generic service objects
that hide the domain.

## Decision

Build one modular monolith on Rails 8 with PostgreSQL, Hotwire and Solid Queue.

- Domain logic lives in domain-named modules and model concerns with intentional public
  entry points (for example `AuditEvent.record!`, `SupportAccessGrant.grant!`,
  `T40::Privacy.export_for`), not in generic `Service` classes.
- External providers (email, error reporting, storage, future identity providers and AI
  providers) sit behind small adapters so they can be replaced without touching domain
  code.
- One deployable artefact serves web and background work; Solid Queue runs in the same
  PostgreSQL database.
- Microservices, Rails Engines, event brokers and workflow engines are not introduced
  without a demonstrated reuse, isolation or scaling need — recorded as a superseding ADR.

## Consequences

- One codebase, one test suite, one deployment pipeline: the acceptance seam (a generated
  application that installs, migrates, boots and passes its suite) stays honest and cheap.
- Tenancy, audit and authorisation controls are enforced in one process, which keeps the
  assurance matrix small and verifiable.
- Vertical scaling and read replicas are the first scaling levers; genuine extraction of
  a hot component is deliberately deferred until evidence demands it.
- Module boundaries are disciplinary rather than physical; code review must defend them
  because the framework will not.
