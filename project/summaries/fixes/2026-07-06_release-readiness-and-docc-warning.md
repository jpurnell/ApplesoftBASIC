# Release-Readiness Gate & DocC Build Warning Fixes

**Date:** 2026-07-06
**Checkers:** release-readiness, build (SwiftPM unhandled-files)
**Before:** Quality Gate FAILED — 1 error, 2 warnings
**After:** Quality Gate PASSED — 0 errors, 0 warnings

## Problem

The `release-readiness` gate failed because `CHANGELOG.md` documents version
`0.1.0` but no matching git tag existed, so consumers could not resolve the
release. Separately, the `build` stage emitted a warning: the
`ApplesoftBASICLib.docc` documentation catalog was flagged as an unhandled file
because it was neither declared as a resource nor excluded from the target.

## Changes

| Area | Change |
|------|--------|
| Git tags | Created annotated tag `v0.1.0` (pointing at the docc-fix commit) matching the documented CHANGELOG release |
| Package.swift | Added `exclude: ["ApplesoftBASICLib.docc"]` to the `ApplesoftBASICLib` target |
| CHANGELOG.md | Folded the docc-exclusion fix into the `[0.1.0]` release (re-dated 2026-07-06, the actual tag date) |

## Verification

- `swift build` — clean, no unhandled-file warning.
- `swift package generate-documentation --target ApplesoftBASICLib` — still
  produces `ApplesoftBASICLib.doccarchive`; the Swift-DocC plugin reads the
  catalog from source independent of target resource handling.
- Full `quality-gate` — 27/27 stages PASSED, 0 errors / 0 warnings.

## Sibling Project

`ApplesoftBASICApp` had the same release-readiness failure (CHANGELOG `1.0.0`,
no tag). Resolved by creating annotated tag `v1.0.0`. That project had no
build warnings.
