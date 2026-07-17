# Module: Webhooks (Inbound Receipt and Outbound Delivery)

> **Not implemented in v2.0.0 — requires approved funded scope.** Selecting this module
> in `t40-manifest.yml` fails preflight by design: it requires an approved, funded
> client requirement; interface only in this release.

## Purpose

Handle event delivery across system boundaries safely, in both directions. **Inbound**:
receive webhooks from third parties (payment providers, client systems) without
trusting them — verify, record, then process asynchronously. **Outbound**: deliver this
application's events to subscriber endpoints with signatures, bounded retries, delivery
history and operator replay, so integration failures are diagnosable rather than
silent.

## Selection rules

Select this module when:

- A third party needs to push events into this application (inbound), or
- A client system needs to be notified of events here without polling (outbound).

Do not select it for internal work (Solid Queue jobs cover that) or where scheduled
polling of an authoritative API is simpler and the latency is acceptable. Bidirectional
synchronisation is **not** this module — that requires explicit ownership, ordering,
deletion and conflict rules and is separately scoped.

## Interface sketch

Inbound:

- One receiving endpoint per provider, **verifying the provider's documented signature
  scheme over the raw request body** — before parsing, using the exact bytes received
  (no re-serialisation), with constant-time comparison. Per-provider secrets via secret
  references.
- Replay window enforced: signed timestamp checked against a bounded tolerance, and
  provider delivery/event identifiers recorded with a uniqueness constraint so
  duplicates are acknowledged but not reprocessed.
- Receipt is recorded (`WebhookReceipt`: provider, delivery id, received_at, digest,
  status) and processing happens asynchronously in a job carrying tenant context —
  the HTTP response only confirms authenticated receipt.
- **Consumers are idempotent**: processing keyed on the provider's event identifier, so
  retries and duplicates converge on the same state.

Outbound:

- `WebhookEndpoint` per subscriber (account-scoped, URL, per-endpoint secret reference,
  active flag, disable controls) and `WebhookDelivery` history (event, attempt count,
  last status, response summary, next retry).
- Deliveries signed (HMAC over payload + timestamp, documented for subscribers), sent
  by idempotent jobs with bounded retries and exponential backoff; exhausted retries
  mark the delivery failed and alert per `docs/operations/alerts.md`.
- Operator replay re-sends the **original recorded payload** without mutating the
  original event or delivery history (replays are new attempts, audited); repeated
  failures can auto-disable an endpoint with an audit event.

## Conformance tests the module must add

- Inbound: bad signature, stale timestamp and duplicate delivery id are rejected or
  handled idempotently — the required abuse case verbatim; verification uses raw-body
  fixtures including bodies whose re-serialisation differs from the received bytes.
- Inbound: processing twice from the same event fixture produces the same final state
  (idempotent consumer proof); receipts carry tenant context into jobs.
- Outbound: signature verifiable by a reference consumer; retries bounded and backoff
  honoured; delivery history records every attempt.
- Outbound: operator replay resends the original payload and leaves the original
  delivery record intact; endpoint disable stops deliveries immediately.
- Secrets never logged; endpoint URLs validated against SSRF (no internal address
  targets).
- All provider interactions tested with local fixtures — no live third party in the
  suite.
