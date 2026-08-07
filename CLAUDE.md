# ApplesoftBASIC — Development Guidelines

This project follows the Design-First TDD workflow defined in `development-guidelines/`.

## Session Start

Read documents in this order for full context recovery:
1. `project/master_plan.md` — Vision and priorities
2. `development-guidelines/rules/coding_rules.md` — Forbidden patterns, safety rules
3. `development-guidelines/rules/test_driven_development.md` — Testing contract
4. `project/checklists/CURRENT_*.md` — Active tasks (if any)
5. Latest file in `project/summaries/` — Where we left off (if any)

For quick recovery (same-day, simple bug fixes), read only items 4-5.

## Development Workflow

```
0. DESIGN   → Propose architecture (design_proposal.md)
1. RED      → Write failing tests first
2. GREEN    → Minimum code to pass
3. REFACTOR → Clean up, keep tests green
4. DOCUMENT → DocC comments and examples
5. VERIFY   → Run quality-gate (zero warnings/errors)
```

## Key Rules

- No force unwraps (`!`), no `try!`, no force casts (`as!`)
- Guard clauses for all validation; early returns over nested ifs
- Division safety: always check for zero before dividing
- Swift 6 strict concurrency compliance
- All public APIs require DocC documentation

## Quality Gate

Run `quality-gate` before every commit. All checks must pass.

## References

- Full guidelines: `development-guidelines/README.md`
- Coding rules: `development-guidelines/rules/coding_rules.md`
- TDD contract: `development-guidelines/rules/test_driven_development.md`
- Session workflow: `development-guidelines/rules/session_workflow.md`