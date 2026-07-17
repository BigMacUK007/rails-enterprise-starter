---
status: template
owner: ""
review_by: ""
---

# Release Evidence

## How to complete this document

Keep one evidence record per production release, newest first. The point is simple: any
deployment can be linked, months later, to the exact code, tests, approvals, scans and
software bill of materials that shipped it. Most of the evidence is produced
automatically — CI runs on every pull request, and the release workflow attaches an SPDX
SBOM to each published release — so a record is mostly links. Fill in the release
checklist and the record for every release; set `status: complete` with an owner and
review date once the process is being followed.

> This template supports evidence gathering; it does not by itself provide ISO 27001,
> SOC 2, Cyber Essentials, WCAG conformance or legal compliance.

## What counts as release evidence

| Evidence | Source |
|---|---|
| Release identifier | Git tag / release and its commit SHA (`RELEASE_SHA` at runtime) |
| Test results | CI `test` job for the released commit (artifact uploaded per run) |
| Static analysis | CI `lint` (RuboCop) and `security_static` (Brakeman) jobs |
| Dependency and secret scans | CI `security_static` job (bundler-audit, gitleaks) |
| Migration check | CI `migrations` job (migrates from zero against PostgreSQL) |
| SBOM | SPDX document attached to the GitHub release by the release workflow |
| Review and approval | Pull request review(s) merged into the release |
| Control state | `config/t40/control-manifest.yml` at the released commit |
| Rollback plan | Named previous release plus data considerations |

## Release checklist

Run for every production release:

- [ ] CI green on the released commit (tests, lint, security, migrations)
- [ ] No unapproved critical or high finding open (Brakeman, bundler-audit; exceptions
      need an owner, rationale, compensating control and expiry)
- [ ] Migrations reviewed for safety on production data (locks, backfills, reversibility)
- [ ] Control manifest reviewed — no deferred control silently blocking this release
      (`bin/rails t40:controls`)
- [ ] SBOM generated and attached to the release
- [ ] Rollback plan named (previous release + data considerations)
- [ ] Release record added below

## Release records

### Release _vX.Y.Z / identifier_

| Field | Value |
|---|---|
| Date deployed | |
| Release SHA | |
| Deployed by | |
| Approved by (PR reviews) | _links_ |
| CI run | _link_ |
| Test summary | _e.g. rspec: N examples, 0 failures_ |
| Scans | _Brakeman / bundler-audit / gitleaks outcomes_ |
| Security exceptions | _none, or exact finding / owner / reason / expiry from `config/t40/security-exceptions.yml`_ |
| SBOM | _link to release asset_ |
| Migrations included | _list or none_ |
| Rollback plan | _previous release; any migration/data caveats_ |
| Notes | |

_Copy this block for each release, newest first._
