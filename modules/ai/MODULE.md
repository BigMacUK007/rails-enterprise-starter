# Module: AI (Gated AI Capability)

> **Not implemented in v2.0.0 — requires approved funded scope.** Selecting this module
> in `t40-manifest.yml` fails preflight by design: it requires an approved, funded
> client requirement; interface only in this release.

## Purpose

Add AI features to an application under explicit control: one internal gateway, policy
code that authorises every proposed action, versioned and evaluated prompts and tools,
hard limits, and a kill switch. The governing rule of the whole module: **the model
proposes, deterministic policy code authorises, and a constrained executor performs.**
A model is never the final security boundary. Applications that do not select this
module install no AI dependency at all — ordinary applications must not inherit AI
risk.

## Selection rules

Select this module when a client requirement funds a specific AI capability
(summarisation, drafting, extraction, assisted workflows) whose value justifies its
control surface. Selecting it triggers the DPIA screening question on innovative
technology (`docs/privacy/dpia-screening.md`) — expect a DPIA for anything touching
personal data.

Do not select it speculatively. Out of scope regardless of selection: long-term AI
memory, autonomous write agents, multi-agent delegation, fine-tuning on client data and
self-modifying tools.

## Interface sketch

- **Gateway** (`T40::AI::Gateway` seam): the single route for every model call. Holds
  the approved provider, model, region, data-retention position, budget, timeout and
  fallback policy. No other code path may call a provider SDK; feature code addresses
  the gateway by capability, not by vendor.
- **Versioning**: prompts, tool definitions, model configuration, retrieval
  configuration and evaluation sets are versioned artefacts; a material AI result can
  be reproduced from its recorded versions. Runs record account, actor and correlation
  context like any other audited work.
- **Tenant isolation**: retrieval and any stored context are account-scoped
  (`AccountScoped` like everything else) and subject to retention rules from
  `docs/privacy/retention.md`.
- **Structured outputs**: model output is validated against a schema before it enters
  deterministic application logic; invalid output is a handled failure, not an input.
- **Tools**: typed, allowlisted, least-privilege and **read-only by default**. A tool
  invocation outside the allowlist or its declared parameter schema is denied by policy
  code — the model cannot invent or expand its own authority. Write-capable tools run
  through the same `authorize!` capability layer as human actions.
- **Bound approvals**: where a human approves an AI-proposed action, the approval is
  short-lived and cryptographically bound to the exact action and parameters; changing
  either invalidates it. Approvals and executions produce `AuditEvent` records.
- **Limits**: every run carries maximum steps, wall time, spend, retries and recursion
  depth; breach aborts the run safely and audibly.
- **Kill switch**: a `T40::Flags` flag gates the whole capability (missing flag ⇒ off,
  matching the flags safe default) plus human override and correction paths in the UI.
- **Assurance records**: the module generates model, prompt, tool, evaluation and
  human-control records into `docs/` for the assurance pack.

## Conformance tests the module must add

- A tool request outside the allowlist, or with parameters outside the approved schema,
  is denied by deterministic policy — the required abuse case verbatim.
- An approval replayed against a different action or mutated parameters is rejected;
  expired approvals are rejected.
- Step, time, spend and recursion limits abort runs and record the abort.
- Retrieval for account A never returns account B's content (tenant isolation at the
  retrieval layer, tested adversarially).
- Malformed or schema-violating model output never reaches application logic.
- Kill switch verified: with the flag off (or absent), no provider call is possible.
- Evaluation fixtures run quality, safety, refusal and abuse cases; model, prompt or
  provider changes fail CI when evaluations regress. Providers are faked locally — no
  live model calls in the test suite.
