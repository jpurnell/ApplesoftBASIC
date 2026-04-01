# Implementation Checklist for [PROJECT_NAME]

**Purpose:** Track implementation progress and ensure completeness during active development.

> **📋 Checklist Hierarchy**
>
> | Checklist | When to Use | Scope |
> |-----------|-------------|-------|
> | **Implementation Checklist** (this file) | During active development | Per-feature |
> | **[Release Checklist](../00_CORE_RULES/RELEASE_CHECKLIST.md)** | Before tagging a release | Verification only |
>
> The Implementation Checklist ensures each feature is built correctly.
> The Release Checklist verifies the entire project is release-ready.
> **Do not duplicate work** — if you follow this checklist rigorously, the Release Checklist becomes a quick verification pass.

---

## Development Workflow

This checklist follows a **Design-First TDD** approach:

```
┌─────────────────────────────────────────────────────────────┐
│                 DEVELOPMENT WORKFLOW                         │
│                                                              │
│   0. DESIGN   → Propose architecture, get approval           │
│   1. RED      → Write failing tests                          │
│   2. GREEN    → Write minimum code to pass                   │
│   3. REFACTOR → Improve code, keep tests green               │
│   4. DOCUMENT → Add DocC comments and examples               │
│   5. VERIFY   → Zero warnings/errors gate                    │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

**Key Documents:**
- [Design Proposal Phase](../00_CORE_RULES/05_DESIGN_PROPOSAL.md) — Step 0 requirements
- [Test-Driven Development](../00_CORE_RULES/09_TEST_DRIVEN_DEVELOPMENT.md) — Steps 1-3 requirements

---

## Current Phase: [Phase Name]

### In Progress
- [ ] [Task 1]
- [ ] [Task 2]

### Completed
- [x] [Completed task 1]
- [x] [Completed task 2]

### Blocked
- [ ] [Blocked task] - *Reason: [explanation]*

---

## Feature Checklist Template (Design-First TDD)

Use this template when implementing new features. **The order matters** — design and tests come before implementation.

### 0. Design Proposal ⚠️ REQUIRED FOR NON-TRIVIAL FEATURES

> **See [Design Proposal Phase](../00_CORE_RULES/05_DESIGN_PROPOSAL.md) for full template.**

Before writing any code, propose and validate your approach:

- [ ] **Objective** documented (what problem does this solve?)
- [ ] **Architecture** proposed (where will code live, what files?)
- [ ] **API surface** sketched (key types and functions)
- [ ] **Constraints compliance** verified (concurrency, generics, safety)
- [ ] **Dependencies** identified (internal and external)
- [ ] **Test strategy** outlined (categories of tests needed)
- [ ] **Open questions** resolved or explicitly deferred
- [ ] **Proposal approved** by user before proceeding

```markdown
# Quick Design Proposal: [Feature Name]
**Objective:** [One sentence]
**Location:** [File paths]
**API:** [Key function signatures]
**Compliance:** Sendable ✅ | Generic ✅ | No force unwrap ✅
**Tests:** [Categories]
```

### 1. Testing (Write Tests FIRST)

> **Write failing tests before writing any implementation code.**

- [ ] **Golden path tests** — Expected behavior with valid inputs
- [ ] **Edge case tests** — Boundary conditions, empty inputs, extremes
- [ ] **Invalid input tests** — Error handling, validation failures
- [ ] **Property-based tests** — Mathematical invariants (where applicable)
- [ ] **Numerical stability tests** — Very small/large values, underflow/overflow
- [ ] **Stress tests** — Large n, time limits
- [ ] **Deterministic seeds** — All stochastic tests use explicit seeds

```bash
# Run tests to verify they FAIL (red phase)
swift test --filter "NewFeatureTests"
```

### 2. Implementation (Make Tests Pass)

> **Write the minimum code needed to make tests pass.**

- [ ] Core functionality implemented
- [ ] Error handling added
- [ ] Guard clauses for invalid inputs
- [ ] Division safety (check for zero)
- [ ] Iteration limits (bounded loops)
- [ ] Collection bounds checking

```bash
# Run tests to verify they PASS (green phase)
swift test --filter "NewFeatureTests"
```

### 3. Refactoring (Clean Up)

> **Improve code quality while keeping tests green.**

- [ ] Remove duplication
- [ ] Improve naming
- [ ] Simplify logic
- [ ] Performance optimizations (if needed)
- [ ] All tests still pass after refactoring
- [ ] **Safety Audit performed** — search for forbidden patterns BEFORE presenting code
- [ ] **Hygiene Audit:** `zzz In Process/` cleared — temporary test fixtures,
      playground scraps, and draft implementations either integrated into
      Sources/ and Tests/ or deleted

**LLM Safety Audit (perform during refactoring, not review):**
> "Searched for: `!`, `as!`, `try!`, `fatalError`, `while true` — none found in new code."

### 4. Documentation

- [ ] DocC comments added (triple-slash `///`)
- [ ] Usage examples provided (playground-ready, with seeds for stochastic code)
- [ ] Parameters, returns, throws documented
- [ ] Edge cases documented
- [ ] Mathematical formulas included (where applicable)
- [ ] Excel equivalent noted (for financial functions)

### 5. Zero Warnings/Errors Gate ⚠️ MANDATORY

**No feature is complete until it passes all quality checks with ZERO warnings or errors.**

#### Run Quality Gate

```bash
# Run all checks with a single command
quality-gate

# Or run specific checks
quality-gate --check build --check test --check safety

# For CI/CD with JSON output
quality-gate --format json

# For GitHub Code Scanning
quality-gate --format sarif > results.sarif
```

Expected output:

```
==========================================
  Quality Gate Results
==========================================

✓ [build] PASSED
✓ [test] PASSED
✓ [safety] PASSED
✓ [doc-coverage] PASSED

==========================================
✅ Quality Gate: PASSED
==========================================
```

#### Quality Checklist
- [ ] `quality-gate` shows all checks **PASSED**
- [ ] No force unwraps (`!`), force casts (`as!`), or `try!` in production code (verified by safety check)

#### What Quality Gate Checks

| Check | What It Verifies |
|-------|------------------|
| `build` | `swift build` with zero warnings |
| `test` | `swift test` with zero failures |
| `safety` | No forbidden patterns (`!`, `as!`, `try!`, `fatalError`, etc.) |
| `doc-lint` | DocC documentation builds without errors |
| `doc-coverage` | Public APIs are documented |

#### MCP Readiness Checklist

> **Why MCP?** In an AI-integrated development environment, every public API should be
> consumable by AI tools. Designing APIs with machine-readable schemas improves clarity
> and future-proofs the project, even if MCP integration isn't immediate.

- [ ] All public APIs have `## MCP Schema` section in docs
- [ ] JSON schema examples use correct types (see DocC Guidelines §9)
- [ ] Stochastic functions document `seed` parameter
- [ ] Nested objects fully documented with all properties
- [ ] Could an AI construct a valid call from the documentation alone?

#### Validation Block (Recommended)

After completing a feature, the LLM should provide a **single, self-contained code block** combining implementation, tests, and usage example when feasible. For features with complex module dependencies, this may not be practical — in that case, provide separate runnable examples instead.

```swift
// === VALIDATION BLOCK: [Feature Name] ===
// Copy this entire block into a Playground to verify

import Foundation
// ... imports ...

// MARK: - Implementation
// [Feature code here]

// MARK: - Tests
// [Test code here]

// MARK: - Usage Example
// [Example with expected output as comments]
```

### 6. Final Review

- [ ] Code self-reviewed
- [ ] All tests pass
- [ ] All quality gates passed (zero warnings/errors)
- [ ] Documentation complete and builds
- [ ] Ready for merge

---

## Quality Gate Setup

Install the `quality-gate` CLI tool to automate all quality checks:

```bash
# Clone and build
git clone https://github.com/jpurnell/quality-gate-swift.git
cd quality-gate-swift
swift build -c release
sudo cp .build/release/quality-gate /usr/local/bin/

# Verify installation
quality-gate --help
```

Or add as an SPM plugin to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/jpurnell/quality-gate-swift.git", from: "1.0.0"),
]
```

Then run via: `swift package plugin quality-gate`

### Manual Fallback (Without quality-gate)

If the `quality-gate` CLI is not installed, run checks individually:

```bash
# Build check (zero warnings)
swift build 2>&1 | grep -c "warning:"

# Test check (zero failures)
swift test

# Safety audit (partial — check for forbidden patterns)
grep -rn 'try!\|as!\|\.first!\|fatalError\|precondition(' --include='*.swift' Sources/

# Doc build
swift package generate-documentation --target [PROJECT_NAME]
```

### Configuration

Create `.quality-gate.yml` in your project root to customize:

```yaml
# Parallel test workers (default: 80% of CPU cores)
parallelWorkers: 8

# Files/directories to exclude from safety checks
excludePatterns:
  - "**/Generated/**"
  - "**/Vendor/**"

# Comment pattern that suppresses safety warnings
safetyExemptions:
  - "// SAFETY:"

# Minimum doc coverage % (nil = strict mode, any gap fails)
docCoverageThreshold: 100
```

---

## Module Status

| Module | Status | Tests | Docs | Warnings |
|--------|--------|-------|------|----------|
| [Module 1] | [Complete/In Progress/Planned] | [Yes/Partial/No] | [Yes/Partial/No] | [0/N] |
| [Module 2] | | | | |
| [Module 3] | | | | |

---

## Quality Gates

Before marking any feature complete, run:

```bash
quality-gate
```

### Required Checks (MANDATORY - Zero Tolerance)

| Check | Requirement |
|-------|-------------|
| `build` | ZERO compiler warnings |
| `test` | ZERO test failures |
| `safety` | ZERO forbidden patterns |
| `doc-lint` | ZERO documentation errors |
| `doc-coverage` | All public APIs documented |

### Coverage & Completeness
- [ ] `quality-gate` shows all checks **PASSED**
- [ ] All edge cases tested
- [ ] All error paths tested
- [ ] Performance acceptable

### Safety Audit
> **Full list of forbidden patterns:** See [Coding Rules](../00_CORE_RULES/01_CODING_RULES.md#forbidden-patterns-mandatory)

Key checks:
- [ ] No force unwraps (`!`), force casts (`as!`), or `try!` in production code
- [ ] All divisions check for zero
- [ ] All loops have iteration limits
- [ ] All array access is bounds-checked

---

## Backlog

### High Priority
- [ ] [Task]
- [ ] [Task]

### Medium Priority
- [ ] [Task]

### Low Priority / Nice to Have
- [ ] [Task]

---

## Design-First TDD Quick Reference

```
┌─────────────────────────────────────────────────────────────┐
│               DESIGN-FIRST TDD CYCLE                         │
│                                                              │
│   0. DESIGN   → Propose architecture, get approval           │
│   ─────────────────────────────────────────────────────────  │
│   1. RED      → Write a failing test                         │
│   2. GREEN    → Write minimum code to pass                   │
│   3. REFACTOR → Improve code, keep tests green               │
│   ─────────────────────────────────────────────────────────  │
│   4. DOCUMENT → DocC comments, examples                      │
│   5. VERIFY   → Zero warnings/errors gate                    │
│                                                              │
│   Repeat steps 1-3 for each behavior within the feature      │
└─────────────────────────────────────────────────────────────┘
```

**Remember:** Design validates direction. Tests drive implementation.

---

## Notes

[Add implementation notes, decisions, or context here]

---

**Last Updated:** [Date]
