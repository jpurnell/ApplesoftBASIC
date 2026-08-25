# 2026-08-25 — Concurrency Auditor Justification Fix

## What happened

The quality gate failed at the `[concurrency]` checker:

```
error: @unchecked Sendable requires a justification comment explaining why this is safe
  → Tests/ApplesoftBASICTests/SoundTests.swift:6:1
```

`SpySoundHandler`, the test spy for BEEP/SOUND coverage, is declared
`final class SpySoundHandler: SoundHandler, @unchecked Sendable` with mutable
stored properties (`beepCount`, `tones`), so the compiler cannot verify
Sendable and the ConcurrencyAuditor demands a `// Justification:` comment on
the line directly above the declaration. The consistency checker also flagged
the same gap as a `ViolationCluster` warning (score 0.75).

## The fix

Added the single-line justification directly above the class declaration:

```swift
// Justification: Test-only spy; each test creates its own instance and accesses it from a single task, so no concurrent mutation occurs.
```

This is the auditor's designed mechanism, not a suppression — the annotation
is genuinely safe because every test constructs its own spy and drives it
synchronously from one task.

## Verification

- `quality-gate --no-cache`: PASSED, 40 of 45 checkers, 0 errors / 0 warnings.
  Consistency score recovered from 0.75 to 1.00.
- `swift test`: 171 tests in 7 suites, all passing.

## Notes

No production code changed; the edit is a comment in a test file. CHANGELOG
gained an Unreleased entry recording the fix.
