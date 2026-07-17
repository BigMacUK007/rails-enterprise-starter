---
status: template
owner: ""
review_by: ""
---

# Architecture Decision Records

## How to complete this document

This directory holds Architecture Decision Records (ADRs). Three are pre-filled because
the T40 Enterprise Application Starter made those decisions for you; review them and mark
them superseded only if the project genuinely departs from them. Add a new ADR for every
significant, hard-to-reverse decision: datastore choices, integration ownership, tenancy
changes, authentication changes, module adoption.

## Format

One file per decision, numbered sequentially: `NNNN-short-title.md`. Each ADR contains:

```markdown
# NNNN. Title

Date: YYYY-MM-DD
Status: Proposed | Accepted | Superseded by NNNN

## Context
Why a decision was needed. The forces at play.

## Decision
What was decided, in the active voice.

## Consequences
What becomes easier, what becomes harder, what must now be done.
```

Never edit an accepted ADR to change its meaning. Write a new ADR that supersedes it.

## Index

| ADR | Title | Status |
|---|---|---|
| [0001](0001-modular-monolith.md) | Modular monolith on Rails 8 | Accepted |
| [0002](0002-passwordless-authentication.md) | Passwordless magic-link authentication | Accepted |
| [0003](0003-solid-queue.md) | Solid Queue for background work | Accepted |
