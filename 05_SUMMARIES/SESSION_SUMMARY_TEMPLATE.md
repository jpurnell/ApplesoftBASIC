# Session Summary Template

**Usage:** Copy this template to create a new session summary.
**Filename Format:** `YYYY-MM-DD_TaskName.md`
**Location:** `05_SUMMARIES/` or `05_SUMMARIES/05_01_FIX_SUMMARIES/` for bug fixes

---

# Session Summary: [Task Name]

| Date | Phase | Status |
| :--- | :--- | :--- |
| YYYY-MM-DD | e.g., Phase 1: Core Analytics | COMPLETED / PARTIAL / BLOCKED |

## 1. Core Objective

*Briefly describe the primary goal of this session based on the Master Plan.*

> Example: Implement Monte Carlo simulation engine for risk analysis (Phase 2, Feature 3)

## 2. Design Decisions

*Document any architectural decisions made during this session.*

- **Decision:** [What was decided]
- **Rationale:** [Why this approach was chosen]
- **Alternatives Considered:** [Other options that were rejected]

## 3. Work Completed

*Document work using the Design-First TDD workflow.*

### Design Proposal
- [ ] Architecture proposed and approved
- [ ] API surface defined
- [ ] Constraints compliance verified

### Tests Written (RED phase)
- [ ] Golden path tests: [List specific test cases]
- [ ] Edge case tests: [List specific test cases]
- [ ] Invalid input tests: [List specific test cases]
- [ ] Deterministic seeds used: [List seeds, e.g., `seed: 42, 12345`]

### Implementation (GREEN phase)
- [ ] Files created: [List new files]
- [ ] Files modified: [List modified files]

### Documentation
- [ ] DocC comments added to: [List files/functions]
- [ ] Usage examples created: [List examples]
- [ ] Playground-ready: [Yes/No]

## 4. Mandatory Quality Gate (Zero Tolerance)

*Run `quality-gate` and verify all checks pass before ending the session.*

```bash
quality-gate
```

| Check | Status |
| :--- | :--- |
| **build** | ✅/❌ |
| **test** | ✅/❌ |
| **safety** | ✅/❌ |
| **doc-lint** | ✅/❌ |
| **doc-coverage** | ✅/❌ |

### If Any Check Failed

- **Which check:** [Name]
- **Error/Warning:** [Copy exact message]
- **Root cause:** [Analysis]
- **Resolution status:** [Fixed / Deferred / Blocked]

## 5. Project State Updates

*Confirm these files were updated:*

- [ ] Active checklist in `04_IMPLEMENTATION_CHECKLISTS/CURRENT_*.md`: Updated
- [ ] If feature shipped: Moved to `04_IMPLEMENTATION_CHECKLISTS/04_99_COMPLETED/`
- [ ] `00_MASTER_PLAN.md`: Updated if architectural changes were made

## 6. Next Session Handover (Context Recovery)

### Immediate Starting Point

*Where should the next session begin? Be specific.*

> Example: "Continue with SimulationResult formatting. Tests are written and passing.
> Next step is to add the `formattedDescription` computed property."

### Pending Tasks

*What remains to be done for this feature?*

- [ ] [Task 1]
- [ ] [Task 2]

### Blockers

*Are there unresolved issues preventing progress?*

- **Blocker:** [Description]
- **Dependency:** [What this is waiting on]
- **Workaround:** [If any]

### Context Loss Warning

*Note anything the next session might misunderstand or forget.*

> Example: "The `SimulationEngine` uses an actor for thread safety. Do not
> refactor to a struct—this was an intentional design decision per Gap #4
> in the architecture review."

---

## Metrics (Optional)

| Metric | Before | After |
|--------|--------|-------|
| Test count | | |
| Test coverage % | | |
| Build time (s) | | |
| Documentation % | | |

---

**Session Duration:** [X hours]
**AI Model Used:** [e.g., Claude Opus 4.5]
