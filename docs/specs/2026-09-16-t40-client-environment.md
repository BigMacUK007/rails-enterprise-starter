# T40 Client Environment — specification

- Status: agreed, ready to build
- Date: 2026-09-16
- Owner: Ben Macdonald
- Supersedes: nothing. Extends `rails-enterprise-starter` v2.0.0.

## 1. What this is

A T40 Client Environment is a self-contained system for one client, running on
their own server. The server is a VPS or a machine in the client's office.

The environment is the product. Tools are what gets installed into it.

The T40 software factory takes in client problems — AI, automation, systems —
and turns out environments that hold the solutions. When a new client signs,
you deploy an environment first, then run scoping sessions, then build tools
into the environment that is already live and secure.

### Naming

| Thing | Name |
| --- | --- |
| The concept | T40 Client Environment |
| The manifest | `manifests/client-environment.yml` |
| A client's repo | `<client>-environment` |

Do not use "engine". A Rails engine is a different thing, and this design
explicitly rejects engines for tools (see section 5.3).

## 2. Where things stand today

Three repositories were reviewed. None of them is ready to be the starting
point, and each is wrong in a different way.

### 2.1 `mini-tools-portal-template` — live, do not touch

Node.js and Express 4. One `server.js` of about 460 lines. No database —
users and client configuration are flat JSON files on disk. Authentication is
username and password over cookie sessions. There is no magic link, no
password reset, and no way for a user to change their own password.

It does have a working user management screen, a tool registry
(`tools/index.js` plus a `register(ctx)` contract), and a tested tenant
isolation suite.

This repository and its two tools — `hpi-processor` and
`pipedrive-reporting` — are in production. **They stay exactly as they are.**
Add one line to the README pointing new client work at the Rails path, so
nobody starts a new client from the wrong repo.

### 2.2 `rails-enterprise-starter` — the foundation

Not a Rails application. A Ruby CLI installer that injects an enterprise
baseline into a freshly generated Rails 8.1 app:

```
rails new my-app -d postgresql --skip-ci
bin/setup-enterprise --target ../my-app --manifest manifests/core.yml --yes
```

What it already gives you:

- Magic link sign-in. Six-character code, 15-minute expiry, single use
  enforced with a row lock, rate limited, decoy codes for unknown addresses
  so users cannot be enumerated.
- Multi-tenancy with no `default_scope`, resolved only from active
  memberships.
- An audit log that is append-only at the database level, enforced by a
  PL/pgSQL trigger.
- Role-based authorisation — owner, admin, member — with capability
  predicates and default deny.
- RSpec, FactoryBot, 12 request specs, a system spec, and an acceptance
  harness (`bin/acceptance`) that generates a real app, installs, reinstalls
  to prove idempotency, and races two concurrent magic-link consumers to
  prove single use.
- A SHA-256 file ledger so a later upgrade can tell the difference between
  "you edited this", "safe to upgrade", and "both changed".
- 46 named controls tracked per install.

What it is missing:

- **No settings, profile, or user management UI at all.** Adding a user to a
  client app today needs the Rails console or a rake task.
- **No deployment configuration.** No Dockerfile, no Compose file, no Kamal.
- `design-tokens.css` — 2,487 lines copied wholesale from a different project
  ("SSP Compliance Tracker"), still carrying that app's page CSS. Nothing
  links it, so the Phlex components render unstyled.

### 2.3 `t40-systems-design-system` — tokens only

A well-built React product UI system. 28 components, 146 exports: DataTable,
Sidebar shell, Dialog, DropdownMenu, Toast, Form, Breadcrumb, Pagination,
EmptyState. Tokens are checked against WCAG 2.2 on every build by a script
that fails CI.

It is React, Radix and Tailwind v4. Its own README says a Rails project takes
the core and stops there. **Rails gets the tokens and none of the
components.**

Two other facts:

- It has never been branded. `--primary` is `#030213`, stock shadcn
  near-black. There is no brand layer and no logo concept.
- Nothing is published and `dist/` is gitignored, so a fresh clone has no
  built CSS until `npm run build` runs.

### 2.4 Unrelated, but worth fixing

`t40-design-system-2026` — the T40 Associates marketing brand — has its entire
contents untracked in git with no remote. One `git clean -fd` erases it.

## 3. Architecture decisions

| # | Area | Decision |
| --- | --- | --- |
| 1 | Stack | Rails 8.1, PostgreSQL, Phlex. Python where it earns its place. |
| 2 | Repo | One repo. `rails-enterprise-starter` keeps `manifests/core.yml` for general projects; a new `manifests/client-environment.yml` adds the product layer. No fork, no second installer. |
| 3 | Deployment | One environment per client. Docker Compose, identical on a VPS or a local box. VPS adds a reverse proxy and TLS. Local boxes join Tailscale. |
| 4 | Auth | The starter's magic link, unchanged. |
| 5 | Email | AWS SES. One T40 sending domain for every environment. Per-client sending built separately if a client asks. |
| 6 | T40 access | A seeded T40 super-admin account per environment, plus Tailscale for local boxes. Move to the starter's time-boxed `SupportAccessGrant` before signing a client who would object to standing access. |
| 7 | User management | Built into the client-environment manifest. |
| 8 | Tools | Plain namespaced Rails under `app/tools/<name>/`, plus a registry table. No engines. |
| 9 | Design | Vendor `tokens.css` from the design system. Build about 15 Phlex components, plus 8 dashboard widgets. |
| 10 | Branding | `config/t40/branding.yml` per client — colour and logo. Rails renders a style block overriding the tokens. No rebuild needed to change it. |
| 11 | Rails vs React | They share tokens and nothing else. Drift below the token layer is accepted. |
| 12 | AI | Build out the starter's `ai` module properly. Off by default, on per client. |
| 13 | Pi harness | A separate module. Install written and tested, off by default. |
| 14 | Backups | Nightly encrypted Postgres dump plus files to the T40 S3 bucket. Identical on VPS and local. With a tested restore command. |
| 15 | Onboarding | A script does the mechanical work. A thin skill wraps it for judgement calls. Server, DNS and email provisioning is a separate second step. |
| 16 | Reporting | Built in-house — Apache ECharts and Phlex widgets, rendered in the app. Blazer mounted for T40 SQL work. Metabase is a documented escape hatch, not a default. |

## 4. Why one repo, not two

The instinct to give client environments their own starter repo is
reasonable, and it was considered. It loses.

A fork means every security fix to the auth, tenancy or audit code has to be
applied twice, by hand, forever — and it will not be. A second installer
layered on top means two upgrade ledgers and a standing question about which
layer owns a given file.

The starter was built around a manifest system so that one codebase can
produce different flavours of app. `manifests/core.yml` stays exactly as it
is for general projects. `manifests/client-environment.yml` adds the product
layer. Physical separation buys nothing here.

## 5. What gets built

### 5.1 User management and settings

The largest gap. Goes into the client-environment manifest so general
projects do not inherit it.

- Account settings: a user changes their own name and sees their role and
  account.
- Active sessions already exist in the starter. Link them from settings.
- User management for admins and owners: list, invite by email, change role,
  deactivate. Invite sends a magic link, so there is no password to set.
- Every change writes an audit event. The starter's `Authorization` concern
  already carries `can_manage_users?`.

The Express portal's version is the reference for the shape. Do not copy the
code — copy the screens.

### 5.2 Design layer

- Delete `design-tokens.css` from the starter.
- Un-ignore `packages/tokens/dist/` in the design system so the built CSS is
  committed and there is a stable file to copy from.
- The installer vendors `tokens.css` into `app/assets/stylesheets/` and links
  it from the layout.
- Build 15 Phlex components against those tokens, plus the 8 dashboard
  widgets in 5.10: button, input, card,
  table, badge, alert, sidebar shell, breadcrumb, dropdown menu, dialog, form
  field with error states, empty state, toast, pagination, tabs, avatar.
- Follow the design system's own rules: semantic tokens only, no raw palette
  values, no arbitrary sizes.
- Light and dark both work. Dark is a `.dark` class on `<html>`; with no
  class the page follows the operating system.

### 5.3 Tool registry

A tool is a namespaced controller, model and set of Phlex views under
`app/tools/<name>/`, plus a row in a `tools` table.

The table drives navigation, per-role visibility, and a beta flag so a tool
under construction is visible to T40 super-admins only. This is the one idea
worth carrying over wholesale from the Express portal, where it worked well.

Rails engines were rejected. Every environment is separate by design and
every tool is bespoke to one client's problem, so engine portability buys
nothing and costs ceremony on every tool. If the same tool gets built three
times, extract an engine then.

### 5.4 Branding

`config/t40/branding.yml`, written by the onboarding script:

```yaml
client:
  name: Acme Ltd
  short_name: Acme
brand:
  primary: "#1F6FEB"
  logo: app/assets/images/client-logo.svg
```

Rails reads it at boot and renders a small style block overriding `--primary`
and its related tokens. Changing a colour means editing a file and
restarting, not a rebuild and redeploy. It is in version control, so you can
see what a client's environment looks like without logging in.

A super-admin UI for this can come later on top of the same tokens.

### 5.5 Deployment

Docker Compose, one setup for both shapes.

- Base: Rails app, PostgreSQL, Solid Queue worker.
- VPS: adds a reverse proxy and TLS, real domain.
- Local box: no proxy, joins Tailscale for T40 access.

The local option exists for a reason — some clients will want their data on a
machine they can see, and that is a cyber-security position worth supporting
rather than arguing with.

### 5.6 Email

AWS SES, the existing T40 account. One sending domain for all environments.
DNS records done once. The onboarding script writes credentials into the
environment.

Codes arrive from T40, not from the client. That is honest — it is a T40
system. A client who wants their own sending domain gets it built as paid
setup work.

### 5.7 Backups

A nightly job in every environment: Postgres dump plus Active Storage files,
encrypted, pushed to the T40 S3 bucket. Identical on a VPS and a local box.

Ship a restore command and test it. A backup nobody has restored is not a
backup.

### 5.8 AI module

Build out the starter's `ai` module, currently `interface_only`. Off by
default, enabled per client.

The shared plumbing is the point: where the API key lives, how client data
reaches a model without crossing tenants, how the audit log records that a
model touched a record, what happens on a timeout, and what a call costs.

### 5.9 Pi harness module

A separate module from 5.8. The AI module is the app talking to a model with
client data. Pi is a coding agent with shell access. Two capabilities, two
toggles.

Install steps written and tested, off by default.

**Open risk.** The research brief dated 2026-09-16 recommends piloting Pi as
a specialist worker before building a platform on it, and advises against
speculative Pi work before 30 September. Building the module is cheap and
reversible, so it is safe to write — but it must not become the reason the
pilot never runs.

Putting a shell-capable agent inside a client's system, sometimes on a
machine in their office, sits at the opposite end of the spectrum from the
append-only audit log and default-deny authorisation the rest of this design
rests on. Off by default is what makes that acceptable.

### 5.10 Reporting

**Build it in-house.** Reporting renders in the Rails app, from Phlex
components, against the client's own PostgreSQL.

#### Why not Metabase

Metabase was evaluated properly and rejected as a default. Its core product is
a query builder for people who cannot write SQL. In the T40 model, T40 builds
every dashboard and every chart; the client filters and reads. That removes
the one thing Metabase is for.

What remained did not justify the cost:

| Metabase gives | Already covered |
| --- | --- |
| Visual query builder | Blazer, for T40 use |
| Chart rendering | ECharts |
| Dashboard layout UI | Only matters if someone drags things. Nobody does. |
| Filter widgets | Rails params and a form |
| CSV export | A few lines of Rails |
| Scheduled email | Solid Queue and a mailer — already proven in `pipedrive-reporting` |

And the costs were real:

- Guest embeds are an iframe. Metabase styles the inside, so it never matches
  the design system exactly. White-labelling is a paid tier, so "Powered by
  Metabase" can appear under a client's dashboard.
- Anything a user does inside Metabase is outside the append-only audit log
  that the rest of this design rests on.
- It is a JVM service and would be the largest memory consumer in every
  environment, forcing a larger server for every client.
- It is a second admin surface to configure, patch and upgrade per
  environment, in a language T40 does not work in.

Embedding with single sign-on, interactivity and white-labelling sits in
Metabase's Pro tier at roughly $575 per month per client — more than the Power
BI licences this is meant to replace.

#### Why in-house wins here

Because T40 builds the reports, a new report is a code change: written as a
query and a Phlex view, drafted quickly with an agent, reviewed, tested,
versioned per client, and deployed like everything else. That is better than
clicking through a GUI when you are the provider — it is reproducible, it is
in git, and it is in the audit trail.

It also keeps the freedom to build whatever a client asks for, rather than
whatever the tool supports.

#### Charting library

**Apache ECharts**, Apache 2.0 licensed. Free for commercial use and free to
redistribute into client-hosted environments.

Alternatives were considered:

| Library | Licence | Verdict |
| --- | --- | --- |
| **Apache ECharts** | Apache 2.0 | Chosen — every chart type needed, no licence risk |
| Chart.js | MIT | Lighter, but only eight core types; the rest are third-party plugins |
| ApexCharts | MIT | Credible, lower ceiling |
| Highcharts | Commercial | **Rejected.** One licence per developer, and deploying into client-hosted environments needs an OEM licence on top. Typical commercial cost is $1,500–$5,000 per year. |
| AG Charts | Split | **Rejected.** The useful chart types sit behind the paid enterprise tier. |
| Plotly | MIT | Overkill, very large |

The deciding argument is switching cost. A client will eventually ask for a
funnel, a gauge or a map, and changing charting library across several
deployed client environments is expensive. Choose the highest ceiling once.

**Chartkick is not used.** It only drives Chart.js, Google Charts and
Highcharts, so it cannot render ECharts — and it is not needed. Once
`Widgets::LineChart` exists in Phlex, that is the Ruby API, and it is not
capped at Chartkick's eight types.

**Groupdate is used.** It is a separate gem and remains the right tool for
`group_by_day` style time bucketing in Ruby.

#### What gets built

**Eight widgets**, on top of the fifteen components in 5.2:

| # | Widget | What it answers |
| --- | --- | --- |
| 1 | Stat tile — number, delta, sparkline | What is it now, and is it up? |
| 2 | Line | Trend over time |
| 3 | Stacked area | Composition over time |
| 4 | Column | Compare categories |
| 5 | Horizontal bar | Rankings, and anything with long labels |
| 6 | Stacked or grouped bar | Composition across categories |
| 7 | Donut | Share of total — five slices maximum, else use a table |
| 8 | Data table — sortable, exportable | The most-used widget in any dashboard |

Plus a filter bar, a date range picker and a CSV export control, which are
controls rather than charts.

**Built on demand**, when a client asks: combo bar and line (volume against a
rate), gauge or bullet (progress to target), funnel (pipeline drop-off),
heatmap (activity by day and hour), waterfall (what moved the number from X to
Y), geographic map (by region or postcode).

**Rarely worth building** unless named in scoping: scatter, bubble, treemap,
sankey, box plot, candlestick, radar.

ECharts renders all of these natively. Waterfall is a stacked-bar recipe in
the ECharts documentation. A sparkline is a line chart with axes and grid
switched off.

Do not build all twenty. Build the eight.

#### Implementation rules

- **One ECharts theme, registered once**, reading `chart-1` to `chart-5` from
  the design system's CSS custom properties through `getComputedStyle`. Every
  chart then follows the client's branding and light or dark mode
  automatically, with no per-chart colour decisions. These tokens are already
  contrast-checked. Do not invent a chart palette.
- **Vendor the JavaScript. Do not use a CDN.** Some environments run on a
  machine in an office behind a domestic connection, and a client's dashboard
  must not depend on a third-party host. Pin through importmap or place the
  file in `vendor/`.
- **Use a tree-shaken build.** Import only the chart types and components in
  use. The full ECharts bundle is large and it ships to every client.
- A dashboard is a Phlex view composed of widgets. Filters are Rails params.
  Scheduled delivery is a Solid Queue job and a mailer.
- Every report is scoped by the same tenancy and authorisation rules as the
  rest of the app, and appears in the audit log.

#### Blazer stays

Mount Blazer for T40 use only, restricted to super-admins:

```ruby
mount Blazer::Engine, at: "blazer"
```

MIT licensed, uses the magic-link session, no second container. It is the SQL
workbench where a query gets written and checked before it becomes a
dashboard. Its data checks can email or Slack when numbers look wrong.

#### Metabase as an escape hatch

Keep a commented-out Metabase service in the Compose file, with notes. If a
client genuinely wants to explore their own data rather than read what T40
built, uncomment it, point it at the same PostgreSQL with a read-only role,
and accept the second login. That is a short job when it is needed, not a tax
on every environment.

Flag it during scoping if a client asks for **pivot tables, geographic maps or
funnel charts** — those are painful to build by hand and are the strongest
reason to reach for the escape hatch.

#### What answers the brief

Every option here queries the client's PostgreSQL inside their own
environment. No dataset is copied to a vendor's cloud and there are no
per-seat licences. That is the real argument against Power BI — not that it is
cheaper, but that the data never leaves the box.

#### Open question

Whether an environment keeps **historical snapshots** is not yet decided. A
source system that only knows today's state cannot answer "how did this change
over six months" unless something took a nightly snapshot. A small daily table
in the environment's own PostgreSQL costs almost nothing and is already
covered by the backup job — but it only starts from the day it is switched on.
Decide this per client, early, because the cost of deciding late is lost
history.

### 5.11 Onboarding script and skill

**Step one — the script.** `bin/new-client-environment`. Mechanical,
deterministic, testable on its own:

1. Create the repo from the template, rename, initialise git.
2. Run `bin/setup-enterprise` with `manifests/client-environment.yml`.
3. Write `config/t40/branding.yml` from the client's name, colour and logo.
4. Vendor `tokens.css`.
5. Seed the first client owner and the T40 super-admin.
6. Write `CLAUDE.md` and `CONTEXT.md` for the environment.

**Step two — provisioning.** Separate, behind its own explicit go-ahead,
because it touches credentials and does things that are hard to undo: server,
DNS, TLS, SES credentials, Tailscale, backup bucket.

**The skill.** A thin wrapper that handles the judgement: which modules this
client needs, what goes in `CONTEXT.md`, whether the brand colour passes the
contrast check. It calls the script; it does not reimplement it.

No Basecamp project is created. That stays manual.

## 6. Build order

All of it before the first client environment is deployed. Within that,
dependencies give a natural order:

1. Remove `design-tokens.css`. Commit the design system's `dist/`.
2. Phlex component set against the vendored tokens.
3. User management and settings, built on those components.
4. Tool registry.
5. Branding config.
6. Docker Compose, both shapes.
7. Backups and restore.
8. Reporting — ECharts widget set, Blazer mounted for T40.
9. AI module.
10. Pi harness module.
11. Onboarding script, then the skill.

Keep `bin/acceptance` green throughout. It is the real contract — it proves
the idempotency, tenant isolation and single-use-code guarantees the rest of
this design rests on.

## 7. Things to watch

- The starter's generated `CLAUDE.md` says "do not add Tailwind, shadcn,
  ViewComponent or a React layer". The Phlex decision keeps faith with that.
  Update the wording so the tokens-only relationship with the design system is
  explicit, rather than leaving a future agent to guess.
- Standing T40 super-admin access to every client environment is the thing a
  security-minded client will ask about. `SupportAccessGrant` is already
  built. Switch before it is asked, not after.
- The design system has never been branded. That is fine here — every
  environment wears the client's colour — but it means there is no T40 default
  look to fall back on.
