# 03 — Persist a reproducible installation manifest on apply

**What to build:** Ensure every successful installation carries the complete normalised manifest needed to reproduce its selected architecture and controls.

**Blocked by:** 02 — Make preflight and planning purely non-destructive.

**Status:** completed

- [x] Successful interactive and non-interactive applies persist the same canonical manifest shape in the generated application.
- [x] The stored manifest digest matches the digest recorded by the control manifest.
- [x] Reapplying the same manifest leaves both manifests and their original installation evidence unchanged.
- [x] Applying a materially different manifest produces a clear plan before any stored selection is replaced.
- [x] No secret value can be written through the installation manifest or its generated references.
