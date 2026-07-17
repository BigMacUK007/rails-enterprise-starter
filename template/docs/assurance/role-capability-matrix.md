---
status: template
owner: ""
review_by: ""
---

# Role and Capability Matrix

## How to complete this document

The starter's capabilities are pre-filled below from the installed `User::Role` concern —
verify them against the code, then add a row for **every** project capability as it is
built. A capability that is not in this matrix has not been authorised by anyone; a
capability in this matrix but not enforced by `authorize!` is a documentation error —
fix one or the other. Set `status: complete` with an owner and review date; review
whenever a capability or role is added or changed.

> This template supports evidence gathering; it does not by itself provide ISO 27001,
> SOC 2, Cyber Essentials, WCAG conformance or legal compliance.

## How authorisation works here

- Roles are **account-scoped**: a `User` (one person's membership of one account) has
  exactly one role — `owner`, `admin` or `member`. The same person (`Identity`) can hold
  different roles in different accounts.
- **Owner satisfies admin**: `admin?` returns true for owners, so every admin capability
  is automatically an owner capability. Owner-only capabilities use `owner?` directly.
- Authorisation is **default-deny and server-side**: controllers, jobs and exports assert
  capabilities with `authorize!(:capability, record)`, which raises (rendering 403 and
  recording an `authorization.denied` audit event) unless the current user's predicate
  returns true. When a record is passed, its `account_id` must match `Current.account` —
  the tenant boundary is asserted at the authorisation layer too.
- **UI visibility is a convenience, never the boundary.** Hiding a button does not
  protect the action.
- Capabilities are implemented as predicate methods on `User::Role`
  (`app/models/user/role.rb`). Add new capabilities there, add the row here, and cover
  them with negative tests (a member must fail).

## Starter capabilities

| Capability | Meaning | Owner | Admin | Member | Enforced at |
|---|---|---|---|---|---|
| `can_manage_users?` | Invite, deactivate and change roles of users in the account (owners cannot be changed by admins — see relational rules) | Yes | Yes | No | _project controllers via `authorize!`_ |
| `can_manage_account?` | Account settings, offboarding, entitlement-affecting actions | Yes | No | No | _project controllers via `authorize!`_ |
| `can_export_data?` | Bulk data export, including audit export (`AuditEvent.export`) | Yes | Yes | No | _export routes/jobs via `authorize!`_ |
| `can_view_audit_log?` | Read the account's audit history | Yes | Yes | No | _audit views via `authorize!`_ |
| `can_grant_support_access?` | Authorise a time-limited T40 support access grant | Yes | No | No | _support access flow via `authorize!`_ |

## Relational rules

Two predicates express user-to-user rules rather than plain capabilities:

| Rule | Behaviour |
|---|---|
| `can_change?(other)` | An admin may change another user unless that user is an owner; anyone may change themselves |
| `can_administer?(other)` | An admin may administer another user who is not an owner and not themselves |

Owners can therefore only be changed by themselves — demoting or removing an owner is an
account-management action for another owner.

## Project capabilities

Add every project capability. Blank rows are provided; a capability without a row here
is undocumented.

| Capability | Meaning | Owner | Admin | Member | Enforced at |
|---|---|---|---|---|---|
| | | | | | |
| | | | | | |
| | | | | | |
| | | | | | |

## High-risk actions requiring more than a role

Destructive, financial, bulk-export, support and other high-risk actions can require a
second actor or explicit approval on top of the role check. Record those decisions here:

| Action | Extra requirement | Implemented by |
|---|---|---|
| _e.g. account offboarding_ | _e.g. second owner confirmation_ | |
| _e.g. bulk export over N records_ | _e.g. named approval recorded as an audit event_ | |
