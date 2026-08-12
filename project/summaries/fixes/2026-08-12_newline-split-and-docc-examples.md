# Newline-Split Safety Fix, DocC Example Repair & v0.1.1

**Date:** 2026-08-12
**Checkers:** safety, doc-code
**Before:** Quality Gate FAILED — 4 errors, 0 warnings
**After:** Quality Gate PASSED — 0 errors, 0 warnings

## Problem

`safety` flagged `CapturedOutput.lines` splitting on the `"\n"` literal. In Swift
`"\r\n"` is a single `Character` — one extended grapheme cluster — and
`split(separator:)` compares whole `Character`s, so it never matches. A buffer
containing CRLF came back as one element holding the entire document, and nothing
threw; the symptom would have surfaced somewhere else entirely. The adjacent
`hasSuffix("\n")` check was blind in the same way.

`doc-code` flagged the `ApplesoftBASICLib` DocC article. The checker reads an
article's Swift fences as one program, so the two blocks both declaring
`interpreter` were the same binding declared twice. Both also called
`Interpreter.init` without the required `rng:` argument — that parameter is
`inout RNG` with no default, so neither example had ever compiled.

## Changes

| Area | Change |
|------|--------|
| `IO/OutputHandler.swift` | `lines` splits with `whereSeparator: \.isNewline`; trailing-terminator check moved to `last?.isNewline` |
| `ApplesoftBASICLib.docc/ApplesoftBASICLib.md` | Both examples pass a generator; the "Testable I/O" block binds `testableIORNG` / `testableIOInterpreter` |
| `README.md` | Library example had the same missing `rng:` argument — README is outside `doc-code`'s scan, so the gate never caught it |
| `CHANGELOG.md` | `[Unreleased]` → `[0.1.1] - 2026-08-12` |
| `ApplesoftBASICLib.swift` | `version` → `"0.1.1"` |
| `.docc/Tutorial.md` | REPL banner sample updated to v0.1.1 (banner interpolates `ApplesoftBASICLib.version`) |
| `project/master_plan.md` | Dependency line now names `SwiftDeterminism` (test-only); Last Updated reconciled |

Neither DocC block was marked `<!-- docs:illustrative -->` — they compile against
the real signature. `doc-code` reports 2 fences, 2 checked, 0 exempt.

## Verification

- Full `quality-gate` — PASSED, 0 errors / 0 warnings, no overrides or exemptions.
- `swift test` — 171 tests in 7 suites passed.
- Tag `v0.1.1` created and pushed with the release commit atomically
  (`git push --atomic`), so the CHANGELOG version and the tag land together.

## Notes for Next Session

**Two sessions were live in this repo at once.** A second Claude Code session
(`session_01E1j9oWvDi8zJbMBVrajmpc`) authored
`Tests/ApplesoftBASICTests/OutputHandlerTests.swift` while this one was working,
and committed it as `b2276aa`. Mid-session that file briefly carried a `CanaryTests`
suite asserting `output.lines.count == 99`, which turned the gate red between two
otherwise-identical runs. If a gate result changes with no edit of your own to
explain it, check `git status` for a second writer before debugging the checker.

**A failing gate was committed once.** The command chained
`quality-gate | tail -4 && git commit`, and `tail`'s exit status masked the
failure, so the commit went through against a red `[test]`. Amended before push.
Pipe the gate through `tail` for *reading*, never as the `&&` guard for a commit.

## Release Ordering

The `release-readiness` failure recorded in the 2026-07-06 summary — CHANGELOG
version committed with no matching tag — was avoided here by tagging locally and
pushing commit and tag in one `--atomic` push, rather than pushing the commit and
tagging afterward.

Note the ordering this forces: the gate **cannot** be green before the release
commit, because the rule wants a tag on a commit that does not exist yet. The
actual sequence was gate-red → commit → tag → gate-green → atomic push, which
inverts the project's gate-green-then-commit rule for exactly one commit.

## Follow-On: quality-gate design proposal

Rather than absorb that inversion as ritual, the release-tag rule was audited and
a design proposal written to
`Tools/quality-gate-swift/project/plans/proposals/ReleaseTagInvariantPlacement.md`
(uncommitted; jpurnell is carrying it forward in a separate session). Three
findings, from reading `ReleaseReadinessAuditor.swift`:

1. The rule is unsatisfiable in the mandated commit order (above).
2. It is not hermetic but inherits the `.hermetic` default, so it may fail the
   gate on ref state rather than tree state — the property `HermeticityContract.md`
   exists to eliminate. A byte-identical commit is red before `git tag`, green
   after. `Hermeticity` has no case that fits: this is repo ref state, neither
   `temporal` nor `external`.
3. It under-detects. `checkVersionTagParity` tests tag-*name* membership in a
   `Set<String>` and never resolves what the tag points at, and `gitTags` reads
   local refs only — so an unpushed tag, or a tag on an unrelated commit, passes.

The `.githooks/pre-push` hook installed here in 2026-07-06 does not cover gap 3:
it delegates to the same check and so sees the same local tag list. It ran on the
v0.1.1 push and passed.
