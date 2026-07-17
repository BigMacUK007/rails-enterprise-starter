# 07 — Generate assurance records from one control catalogue

**What to build:** Give developers and reviewers one consistent set of control identifiers and descriptions across machine records, human assurance documents and reports.

**Blocked by:** 05 — Make single-account mode a genuine installation variant; 06 — Make data risk and deployment profile drive gates.

**Status:** completed

- [x] The generated control manifest and assurance matrix contain the same applicable control identifiers.
- [x] Control names, categories, statuses and references are derived from one authoritative catalogue.
- [x] Generation fails when a control reference or claimed automated test does not exist.
- [x] Module-disabled controls are recorded as not applicable with a reason rather than omitted ambiguously.
- [x] Catalogue validation detects duplicate, obsolete and unexplained assurance-matrix identifiers.
