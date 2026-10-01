# Session Summary: Fallback Checker — Unrepresentable Numbers

| Date | Phase | Status |
| :--- | :--- | :--- |
| 2026-09-30 | Maintenance (quality gate) | COMPLETED |

## 1. Core Objective

Clear the new `[fallback]` checker (4 errors, 2 warnings) without overrides:

- `Int(value)` on an unchecked `Double` in `Interpreter.evaluateToInt`, `MID$`
  (start and length) and `formatNumber`.
- `max(lo, min(x, hi))` clamps in `AudioSoundHandler.playTone` that turn a NaN
  into the lower bound.

Also cleared the one other warning the full gate carried,
`doc-lint.catalogue-excluded`, so the gate ends at 0/0.

## 2. Design Decisions

- **Decision:** One throwing helper, `BuiltInFunctions.truncatedInt(_:)`, built
  on `Int(exactly: value.rounded(.towardZero))`; failure throws
  `BASICError.illegalQuantity`.
- **Rationale:** The findings were real — `10 GOTO 1E300` killed the process,
  and BASIC programs can produce infinity and NaN (`1E300 * 1E300`, then
  `X - X`). A BASIC program must not be able to crash its interpreter.
- **Beyond what the checker flagged:** `LEFT$`, `RIGHT$` and `CHR$` had the same
  `Int(count)` trap but bind through `numericArgs.first`, which the checker did
  not trace; they use the helper too. `MID$` with a negative length trapped on
  an inverted range and now throws; its end position is computed as
  `adjustedStart + min(length, remaining)` so two huge arguments cannot overflow.
- **`formatNumber`:** `if let whole = Int(exactly: value), abs(value) < 1e15` —
  same output for every input as before (the old condition already excluded NaN
  and infinity, but only by accident of comparison semantics).
- **`playTone`:** `guard !frequency.isNaN, !duration.isNaN else { return }`. An
  infinite value is still clamped, which is what a clamp is for.
- **DocC catalogue:** removed `exclude: ["ApplesoftBASICLib.docc"]` from
  `Package.swift`. The 0.1.0 commit (`c26f1e7`) excluded it to silence an
  "unhandled files" warning on the stated belief that the plugin reads the
  catalogue regardless. It does not; and the build is warning-free without the
  exclusion.

## 3. Work Completed

### Tests Written (RED phase)
- Parameterised test over nine programs (out-of-range, infinite, NaN through
  `GOTO`, `LEFT$`, `RIGHT$`, `MID$`, `CHR$`, `DIM`) — trapped the test process
  before the fix.
- `MID$` negative length; `MID$` huge start and length; `formatNumber` on
  non-finite, whole, fractional and large values; `SOUND` with NaN arguments.

### Not tested
- The `AudioSoundHandler.playTone` NaN guard has no test: the method returns
  nothing and exercising it starts a real audio engine.

## 4. Verification

- `swift test`: 176 tests in 7 suites pass (171 before; the parameterised test
  counts once).
- `quality-gate --no-cache --strict`: 0 errors, 0 warnings.

## 5. Open Questions

- Fidelity: real Applesoft raises `?ILLEGAL QUANTITY ERROR` for out-of-range
  integer arguments, but its exact limits (e.g. 0–255 for `LEFT$` counts,
  −32767…32767 for subscripts) are narrower than `Int`. Not changed here; it
  belongs to master-plan Priority 1 and wants a reference to compare against.
