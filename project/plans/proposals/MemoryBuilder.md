# Design Proposal: MemoryBuilder

## 1. Objective

**Objective:** Add a MemoryBuilder tool to quality-gate that automatically generates and updates `.claude/projects/*/memory/` files by analyzing the project's codebase, git history, and configuration — so every Claude Code session starts with rich project context without manual effort.

**Problem:** Claude Code's memory system is powerful but requires manual curation. Users who don't actively build memory get weaker sessions. The knowledge needed for good memory entries already exists in the codebase — it just needs extraction.

**Master Plan Reference:** Development Guidelines — closing the gap between sophisticated and average Claude Code usage.

## 2. Proposed Architecture

**New Files:**
- `Sources/MemoryBuilder/MemoryBuilder.swift` — Main `QualityChecker` implementation
- `Sources/MemoryBuilder/MemoryAnalyzer.swift` — Analysis engine
- `Sources/MemoryBuilder/Extractors/` — Pluggable extraction modules
- `Sources/MemoryBuilder/MemoryWriter.swift` — Renders memory file markdown with frontmatter
- `Tests/MemoryBuilderTests/` — Test suite

**Modified Files:**
- `Package.swift` — New target and test target
- `Sources/QualityGateCLI/QualityGateCLI.swift` — Register MemoryBuilder in allCheckers
- `Sources/QualityGateCore/Configuration.swift` — Add `memoryBuilder` config section

**Module Boundary:**
- MemoryBuilder depends on `QualityGateCore` (for `QualityChecker`, `Diagnostic`, etc.)
- Does NOT depend on `SwiftSyntax` — this is not an AST auditor. It reads structured files, git output, and configuration.
- Uses `Foundation` for file I/O and process execution (git commands).

## 3. What Gets Extracted

Each extractor is a standalone module that produces zero or more memory file candidates:

### 3.1 ProjectProfileExtractor (→ `project` memory)
- **Source:** Package.swift, .quality-gate.yml, README.md
- **Extracts:** Project name, Swift tools version, targets/modules list, enabled quality-gate checkers, key dependencies
- **Output:** `project_profile.md` — one-time snapshot, updated when Package.swift changes

### 3.2 ConventionExtractor (→ `feedback` memory)
- **Source:** .claude/rules/*.md, CLAUDE.md, development-guidelines/rules/coding_rules.md
- **Extracts:** Key rules and constraints that should persist across sessions (forbidden patterns, required conventions)
- **Output:** `feedback_conventions.md` — rules that Claude should follow without being told each session

### 3.3 ArchitectureExtractor (→ `project` memory)
- **Source:** Sources/ directory structure, module dependency graph from Package.swift
- **Extracts:** Module map (which targets depend on which), approximate module sizes, public API surface area
- **Output:** `project_architecture.md` — module layout and dependency relationships

### 3.4 ActiveWorkExtractor (→ `project` memory)
- **Source:** development-guidelines/project/checklists/CURRENT_*.md, git log --oneline -20, git branch
- **Extracts:** Active features in progress, current branch, recent commit themes
- **Output:** `project_active_work.md` — what's in flight right now

### 3.5 ADRExtractor (→ `project` memory)
- **Source:** development-guidelines/rules/architecture_decisions.md
- **Extracts:** Summary of accepted ADRs (id + title + one-line decision), count
- **Output:** `project_decisions.md` — quick reference so Claude can query the full ADR log when relevant

### 3.6 EnvironmentExtractor (→ `reference` memory)
- **Source:** Shell commands (swift --version, uname), .quality-gate.yml
- **Extracts:** Swift version, platform, key toolchain info
- **Output:** `reference_environment.md` — prevents Swift version mismatch surprises

## 4. What Does NOT Get Extracted

- **User preferences** — these are personal and must remain manually curated
- **Feedback from corrections** — only the user knows what was surprising; can't be inferred
- **External references** (Slack channels, Linear projects) — not discoverable from code
- **Debugging solutions** — the fix is in the code; memory shouldn't duplicate it

## 5. Merge Strategy

MemoryBuilder must not destroy manually-written memory files. Strategy:

1. **Generated files get a frontmatter tag:** `generated-by: memory-builder`
2. **On re-run:** Only overwrite files with that tag. Never touch files without it.
3. **MEMORY.md index:** Append new entries, never remove existing ones. Generated entries get a `<!-- generated -->` comment so they can be updated in place.
4. **Staleness:** If a generated file's source data hasn't changed (hash check), skip regeneration.

## 6. Integration with quality-gate

MemoryBuilder implements `QualityChecker` but behaves differently from auditors:

- **check() behavior:** Runs all extractors, generates/updates memory files, returns `.passed` with note-level diagnostics listing what was updated.
- **Never fails the gate:** Memory generation is advisory, not blocking. Status is always `.passed` or `.warning` (if it couldn't read a source).
- **CLI usage:** `quality-gate --check memory-builder` or as part of the full suite.
- **Standalone usage:** Can also run as a standalone command for projects not using quality-gate.

## 7. Configuration (.quality-gate.yml)

```yaml
memoryBuilder:
  enabled: true
  outputPath: null  # auto-detect from .claude/ project path
  extractors:
    - projectProfile
    - conventions
    - architecture
    - activeWork
    - adrSummary
    - environment
  guidelinesPath: development-guidelines  # relative to project root
```

## 8. Error Handling Strategy

- Missing sources (no Package.swift, no development-guidelines/) → skip that extractor, emit `.note` diagnostic
- Git not available → skip ActiveWorkExtractor, emit `.warning`
- Malformed ADR YAML → skip entry, emit `.warning` with location
- No `.claude/` directory → create it, or emit `.warning` if no write permission

## 9. Testing Strategy

- **Unit tests per extractor:** Feed known input, verify output markdown and frontmatter
- **Integration test:** Run against a fixture project with known structure, verify all memory files generated
- **Merge test:** Pre-populate memory dir with manual + generated files, run builder, verify manual files untouched
- **Idempotency test:** Run twice, verify no unnecessary changes on second run

**Reference truth sources:** The fixture project's Package.swift, directory structure, and git history are the truth. Tests verify extracted content against known values.

## 10. Architecture Decision Review

**ADR Check:**
- [x] Reviewed `architecture_decisions.md` for related decisions
- ADR-005 (YAML decisions log) — MemoryBuilder reads this format, doesn't change it
- ADR-008 (setup.swift bridge layer) — MemoryBuilder complements setup.swift; setup creates the .claude/ structure, MemoryBuilder populates memory within it
- [ ] New ADR required? Yes → ADR-011: Automated memory generation via MemoryBuilder

**New ADR Draft:**
```yaml
id: ADR-011
date: 2025-04-09
status: proposed
category: tooling
title: Automated memory generation via MemoryBuilder in quality-gate
context: |
  Claude Code's memory system requires manual curation. Most projects have
  sparse or empty memory, leading to weaker sessions. The knowledge needed
  for effective memory entries already exists in the codebase.
decision: |
  Add a MemoryBuilder tool to quality-gate that extracts project profile,
  architecture, conventions, active work, ADR summaries, and environment
  info into .claude/memory files. Generated files are tagged and only
  overwritten on re-run; manual memory files are never touched.
rationale: |
  - Knowledge already exists in Package.swift, git, ADRs, rules files
  - Automated extraction eliminates the manual curation bottleneck
  - Tagged files enable safe re-generation without destroying user content
consequences: |
  + Every session starts with rich project context automatically
  + Memory stays current as the project evolves (run with quality-gate)
  - Generated memory may be less nuanced than hand-written entries
  - Adds a dependency on .claude/ directory structure conventions
alternatives_rejected:
  - "Manual-only memory: Already proven insufficient — most projects have 0-1 entries"
  - "Session hooks that auto-save: Would capture noise; quality-gate runs are intentional"
affected_files:
  - Sources/MemoryBuilder/
  - Package.swift
  - Sources/QualityGateCLI/QualityGateCLI.swift
supersedes: null
amends: null
superseded_by: null
```

## 11. Implementation Phases

1. **Phase 1 (RED):** Tests for ProjectProfileExtractor, ArchitectureExtractor, MemoryWriter, merge logic
2. **Phase 2 (GREEN):** Implement extractors to pass tests
3. **Phase 3:** ConventionExtractor, ActiveWorkExtractor, ADRExtractor, EnvironmentExtractor
4. **Phase 4:** CLI integration, configuration, documentation
5. **Phase 5:** Headless CI validation (run `claude -p` to verify memory quality)

## 12. Resolved Questions

1. **Output path detection:** Auto-detect from `$CLAUDE_PROJECT_DIR` or by walking up from cwd to find `.claude/`. Config override available but not required.
2. **Frequency:** Runs every `quality-gate` invocation as part of the standard suite. The ~1s overhead is acceptable to keep memory current.
3. **Cross-project memory:** Yes — reads `~/.claude/CLAUDE.md` and skips extracting rules/conventions that are already covered globally, avoiding duplication in project-level memory.
