# Architecture Decisions Log

**Purpose:** Machine-readable log of architectural decisions. Each entry is a YAML block.

> **When to add entries:**
> - Choosing between competing approaches (actor vs struct, sync vs async)
> - Establishing conventions (error handling, naming, file structure)
> - Making tradeoffs (performance vs safety, simplicity vs flexibility)
> - Rejecting a previously considered approach

---

## How to Use

1. **Add new entries** at the bottom of this file using the YAML template below
2. **Increment the ID** sequentially (ADR-001, ADR-002, etc.)
3. **Query entries** by category, status, or keyword
4. **Supersede** old entries by updating `superseded_by` and creating a new entry

### Querying Examples

```
"Check the architecture decisions log for any decisions about concurrency
(category: concurrency). Summarize what was decided and why."
```

```
"Find ADR-001 and tell me what alternatives were rejected."
```

---

## Entry Template

Copy this template for each new decision:

```yaml
id: ADR-NNN
date: YYYY-MM-DD
status: proposed  # proposed | accepted | superseded | amended | deprecated
category: [category]  # concurrency | storage | api | testing | performance | architecture
title: [Brief title]
context: |
  [Describe the specific problem, constraints, and why a decision is needed.]
decision: |
  [Detail the chosen architectural approach or convention.]
rationale: |
  - [Reason 1]
  - [Reason 2]
consequences: |
  [Document the positive and negative impacts on the codebase,
   performance, or workflow.]
alternatives_rejected:
  - "[Alternative]: [Why rejected]"
affected_files:
  - [file path]
supersedes: null  # ADR-NNN if this completely replaces an earlier decision
amends: null  # ADR-NNN if this refines/extends an existing decision
superseded_by: null  # ADR-NNN if this was later replaced
```

### Lifecycle Management

- **`supersedes`**: Use when a new decision completely replaces an older one. Update the original entry's `status` to `superseded` and set its `superseded_by` field.
- **`amends`**: Use when a new decision refines or adds constraints to an existing one without replacing it. Update the original entry's `status` to `amended`.
- **When updating**: Always go back to the original entry and update its `status` field to reflect that it is no longer the sole authority.

---

## Decisions

*Add entries below as architectural decisions are made.*

<!-- Example entry (remove or replace with your first real decision):

```yaml
id: ADR-001
date: 2024-01-15
status: accepted
category: api
title: Return NaN for mathematically undefined, throw for invalid input
context: |
  Need a consistent error-handling strategy across all numeric functions.
  Some operations are mathematically undefined (log(-1)) while others
  receive programmatically invalid input (empty array).
decision: |
  Functions return .nan when result is mathematically undefined.
  Functions throw errors when input is programmatically invalid.
rationale: |
  - NaN propagates through calculations (IEEE 754 standard)
  - Errors force callers to handle bad input at boundaries
  - Matches behavior of standard numeric libraries
consequences: |
  + Callers get IEEE 754-compliant behavior for math functions
  + Invalid input is caught early at API boundaries
  - Callers must check for NaN in downstream results
alternatives_rejected:
  - "Return nil: Forces optional chaining everywhere, clutters call sites"
  - "Always throw: Breaks IEEE 754 conventions for math functions"
affected_files:
  - Sources/[PROJECT_NAME]/*.swift
supersedes: null
amends: null
superseded_by: null
```

-->

---

**Last Updated:** [Date]
