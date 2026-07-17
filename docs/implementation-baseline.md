# Implementation baseline

The existing uncommitted passwordless authentication and installer work was
adopted as the protected T40 Enterprise Application Starter v2 baseline on
2026-07-17. It was preserved without reset, checkout or cleanup.

The baseline installer suite passed on Ruby 3.4.5 with 64 runs, 651 assertions,
zero failures and zero errors before ticket implementation began.

The v2 compatibility contract is Ruby 3.4 or newer, Rails 8.1 and PostgreSQL.
The authoritative acceptance environment runs PostgreSQL 17. A successful
installer verification proves `installation_verified`; it does not by itself
make a generated client application `production_ready`.
