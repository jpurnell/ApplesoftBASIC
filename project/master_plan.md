# ApplesoftBASIC Master Plan

**Purpose:** Source of truth for project vision, architecture, and goals.

> **Provenance:** Written 2026-08-05 from README, `Package.swift`, and the source tree.

---

## Project Overview

### Mission

A faithful Applesoft BASIC interpreter written in modern Swift, celebrating Apple's 50th
birthday.

**Faithful** is the requirement, not merely the description. A program written in 1979
should behave the way it did — including the parts that were surprising then.

### Target Users
- Anyone running vintage Applesoft listings without an emulator
- `ApplesoftBASICApp`, the iPad front end
- People curious how an interpreter fits together, on a language small enough to read whole

### Key Differentiators
- **Fidelity over convenience.** Where 1979 behaviour and modern taste disagree, 1979 wins —
  including the error messages
- **A library first** (`ApplesoftBASICLib`), so the interpreter is embeddable rather than
  locked inside a terminal app
- **Apple II graphics** — `AppleIIColors`, `GraphicsRenderer`, `HPlotPoint`: lo-res and
  hi-res, not just text
- **Its own line editor** (`CLineEditor`), because the editing experience is part of the
  original one

---

## Architecture

- **Language:** Swift 6 · **Dependencies:** DocC plugin; `SwiftDeterminism` (tests only, seeded `RND`)

| Target | Role |
|---|---|
| `ApplesoftBASICLib` | the interpreter — embeddable |
| `ApplesoftBASIC` | the CLI |
| `CLineEditor` | line editing |

16 source files, 7 test files.

---

## Current Status

- [x] Interpreter, CLI, line editor, graphics types
- [x] ApplesoftBASICLib
- [x] ApplesoftBASIC

### Priorities
1. **Fidelity coverage.** The tests that matter most are real listings with known output.
   Floating-point formatting, integer coercion in `DataValue`, and `BASICError` text are
   where "close enough" quietly stops being faithful — and are invisible without a
   reference to compare against.
2. **[NEEDS INPUT]** — which Applesoft version is the reference, and whether the goal
   includes bug-compatibility or only documented behaviour. That single answer decides many
   smaller ones.

## Quality Standards

`coding_rules.md`, Swift 6 strict concurrency, zero warnings, DocC on public types.
**Fidelity is tested against known-correct output from real programs**, not against
assumptions about what BASIC ought to do.

## Roadmap

**[NEEDS INPUT]**

---

**Last Updated:** 2026-08-25 — Current Status now names the `ApplesoftBASICLib` and
`ApplesoftBASIC` targets explicitly, clearing the status checker's notes that the
Package.swift targets were undocumented here. No architectural change — the targets
were already described in the Architecture table.

Previous (2026-08-12) — reconciled for v0.1.1: dependency line now names
`SwiftDeterminism` (test-only), which the "none beyond DocC" claim had missed since it
was adopted. File counts (16 source, 7 test) still hold; the removed `SeededGenerator`
and the added `OutputHandlerTests` cancel out. Priorities and Roadmap unchanged — the
two **[NEEDS INPUT]** questions are still open and still gate the fidelity work.
