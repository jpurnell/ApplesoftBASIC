# Session Summary: Stochastic Determinism — RNG Injection

| Date | Phase | Status |
| :--- | :--- | :--- |
| 2026-05-18 | Bug Fix / Quality Gate Compliance | COMPLETED |

## 1. Core Objective

Resolve the `stochastic-determinism` quality gate warning: `SystemRandomNumberGenerator` was used directly in library code. Refactor to proper dependency injection so the RNG is created at the application boundary and threaded through via `inout some RandomNumberGenerator`.

## 2. Design Decisions

- **Decision:** Replace existential-defaulted `init` with generic `init<RNG: RandomNumberGenerator>(..., rng: inout RNG)`
- **Rationale:** The stochastic-determinism auditor enforces that reusable code never hard-codes `SystemRandomNumberGenerator`. This enables deterministic testing, swappable PRNGs, and reproducible behavior.
- **Alternatives Considered:**
  - Existential `(any RandomNumberGenerator)?` with internal default — still flagged by auditor
  - Private `makeDefaultRNG()` factory — still flagged (auditor pattern-matches on type name)
  - Overloaded convenience init — flagged in body where `SystemRandomNumberGenerator()` appeared

## 3. Work Completed

### Implementation

- **`Interpreter.swift`:** Replaced single `init` with generic `init<RNG: RandomNumberGenerator>(..., rng: inout RNG)`. Library no longer references `SystemRandomNumberGenerator`.
- **`main.swift`:** Created `SystemRandomNumberGenerator` once at top-level entry point. Threaded `inout RNG` through `main()` → `runREPL()` / `runFile()` → `runProgram()` / `executeDirect()` → `Interpreter.init`.
- **`SeededGenerator.swift`** (new): SplitMix64 deterministic PRNG for reproducible tests.
- **`InterpreterTests.swift`**, **`SoundTests.swift`**, **`GraphicsTests.swift`:** Switched from `SystemRandomNumberGenerator` to `SeededGenerator(seed: 42)`.

### Files Modified
- `Sources/ApplesoftBASICLib/Interpreter/Interpreter.swift`
- `Sources/ApplesoftBASIC/main.swift`
- `Tests/ApplesoftBASICTests/InterpreterTests.swift`
- `Tests/ApplesoftBASICTests/SoundTests.swift`
- `Tests/ApplesoftBASICTests/GraphicsTests.swift`

### Files Created
- `Tests/ApplesoftBASICTests/SeededGenerator.swift`

## 4. Mandatory Quality Gate (Zero Tolerance)

| Check | Status |
| :--- | :--- |
| **build** | ✅ |
| **test** | ✅ (164 tests) |
| **safety** | ✅ |
| **doc-lint** | ✅ |
| **doc-coverage** | ✅ (100% — 128/128) |
| **stochastic-determinism** | ✅ |
| **test-quality** | ✅ |
| **all others** | ✅ |

## 5. Project State Updates

- No active checklists to update
- No architectural changes to `master_plan.md`

## 6. Next Session Handover (Context Recovery)

### Immediate Starting Point

Quality gate is fully green. No further work needed for this fix.

### Pending Tasks

- None for this fix.
- Future opportunity: tests using `SeededGenerator` could add deterministic assertions on `RND()` output values.

### Blockers

- None.

---

**Session Duration:** ~30 minutes
**AI Model Used:** Claude Opus 4.6
