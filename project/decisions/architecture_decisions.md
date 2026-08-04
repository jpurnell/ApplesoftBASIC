# Architecture Decisions — ApplesoftBASIC

This project's own decision log, extracted from the v1
`development-guidelines/rules/architecture_decisions.md` during the v2 migration.
The format is documented in `development-guidelines/rules/architecture_decisions.md`.

## Decisions

*Add entries below as architectural decisions are made.*

```yaml
id: ADR-001
date: 2025-02-15
status: accepted
category: architecture
title: Design-First TDD as mandatory workflow
context: |
  AI assistants frequently jump straight to implementation, producing code
  that later needs significant rework when architectural issues surface.
  Gap analysis of early sessions showed wasted effort from wrong-direction
  implementations.
decision: |
  All features must pass through a Design Proposal phase (Phase 0) before
  any code is written. The workflow is: DESIGN → RED → GREEN → REFACTOR →
  DOCUMENT → VERIFY. Design proposals live in project/plans/proposals/.
rationale: |
  - Prevents wasted effort from wrong-direction implementations
  - Forces architecture validation before coding begins
  - Gives AI assistants explicit permission to pause and think
  - Creates a reviewable artifact before investment
consequences: |
  + Fewer rewrites and abandoned implementations
  + Clear decision trail for future sessions
  - Adds overhead for trivial changes (mitigated by skip criteria in workflow)
alternatives_rejected:
  - "Code first, refactor later: Led to significant rework in practice"
  - "Informal discussion only: No artifact for future sessions to reference"
affected_files:
  - development-guidelines/rules/design_proposal.md
  - development-guidelines/rules/session_workflow.md
  - development-guidelines/templates/checklist.md
supersedes: null
amends: null
superseded_by: null
```

```yaml
id: ADR-002
date: 2025-02-15
status: accepted
category: architecture
title: Session context recovery protocol with tiered reading order
context: |
  AI assistants lose all context between sessions. Without a structured
  recovery protocol, each session began with 10-20 minutes of the user
  manually re-explaining project state, or the AI making decisions that
  contradicted earlier architectural choices.
decision: |
  Two recovery tiers: Quick Recovery (summaries + active checklists) for
  same-day/simple work, and Full Recovery (master plan → coding rules →
  TDD contract → checklists → summaries) for new sessions or complex work.
  Session end requires a handover summary with exact next step.
rationale: |
  - Tiered approach avoids unnecessary context loading for simple tasks
  - Mandatory handover summaries create the artifact that enables recovery
  - Reading order ensures foundational rules load before task-specific state
consequences: |
  + Sessions resume in under 2 minutes instead of 10-20
  + Architectural decisions persist across sessions
  - Requires discipline to write summaries at session end
alternatives_rejected:
  - "Single flat context dump: Wastes tokens on irrelevant context for simple tasks"
  - "Rely on git history alone: Missing rationale, next steps, and blockers"
affected_files:
  - development-guidelines/rules/session_workflow.md
  - project/summaries/development-guidelines/templates/session_summary.md
supersedes: null
amends: null
superseded_by: null
```

```yaml
id: ADR-003
date: 2025-02-20
status: accepted
category: architecture
title: MCP readiness as a documentation requirement
context: |
  AI assistants need machine-readable API documentation to construct valid
  tool calls. Standard DocC documentation is human-readable but lacks the
  structured metadata (JSON schemas, parameter types) that MCP servers need.
decision: |
  All public APIs must include MCP schema requirements with Swift-to-JSON
  type mapping. Design proposals include an MCP Schema section. An Article
  vs API decision tree guides documentation format choices.
rationale: |
  - Enables AI assistants to construct valid tool calls from documentation
  - Structured schemas are verifiable and testable
  - Future-proofs APIs for MCP server exposure
consequences: |
  + APIs are immediately consumable by AI tooling
  + Documentation serves both human and machine readers
  - Additional documentation overhead per public API
alternatives_rejected:
  - "Generate schemas from code: Loses intent and constraints not expressible in types"
  - "Separate schema files: Drift risk between docs and schemas"
affected_files:
  - development-guidelines/rules/docc_guidelines.md
  - development-guidelines/rules/design_proposal.md
supersedes: null
amends: null
superseded_by: null
```

```yaml
id: ADR-004
date: 2025-03-01
status: accepted
category: architecture
title: quality-gate as single unified verification tool
context: |
  Projects had to run multiple separate commands (swift build, swift test,
  docc-lint, safety audit) before every commit. AI assistants frequently
  forgot one or more steps, and the inconsistency across documents about
  which commands to run caused confusion.
decision: |
  Replace individual verification commands with a single `quality-gate` CLI
  tool that checks build, tests, safety audit, and documentation coverage.
  All documentation references updated to use quality-gate.
rationale: |
  - Single command eliminates forgotten steps
  - Consistent interface across all documentation
  - Configurable via .quality-gate.yml per project
consequences: |
  + Zero-ambiguity verification: one command, pass or fail
  + AI assistants can't skip individual checks
  - External dependency on quality-gate tool
alternatives_rejected:
  - "Shell script wrapper: Not cross-platform, harder to configure per-project"
  - "Keep separate commands with checklist: AI assistants still forget steps"
affected_files:
  - development-guidelines/rules/session_workflow.md
  - development-guidelines/templates/checklist.md
  - development-guidelines/rules/RELEASE_CHECKLIST.md
  - DEVELOPMENT_WORKFLOW_TUTORIAL.md
supersedes: null
amends: null
superseded_by: null
```

```yaml
id: ADR-005
date: 2025-03-10
status: accepted
category: architecture
title: Structured YAML decisions log over prose-based ADRs
context: |
  Traditional Architecture Decision Records (ADRs) use prose markdown files.
  AI assistants need to query decisions by category, status, or keyword
  without reading the entire history. Long-running projects accumulate
  dozens of decisions that exceed context window budgets.
decision: |
  Use a single structured YAML-block log (architecture_decisions.md)
  with machine-queryable fields: id, category, status, supersedes/amends.
  AI can grep for specific categories without loading the full file.
rationale: |
  - YAML blocks are parseable by AI without full-file reads
  - Category and status fields enable targeted queries
  - Supersedes/amends chain tracks decision evolution
  - Single file avoids scattered ADR directories
consequences: |
  + AI can answer "what did we decide about concurrency?" with a targeted search
  + Decision lifecycle is explicit and trackable
  - Single file could grow large (mitigated by structured format enabling partial reads)
alternatives_rejected:
  - "One-file-per-ADR directory: Requires listing + reading multiple files"
  - "Prose-only records: Not machine-queryable without full reads"
affected_files:
  - development-guidelines/rules/architecture_decisions.md
  - development-guidelines/rules/session_workflow.md
supersedes: null
amends: null
superseded_by: null
```

```yaml
id: ADR-006
date: 2025-03-15
status: accepted
category: architecture
title: Per-feature implementation checklists over monolithic tracker
context: |
  A single implementation checklist file grew unwieldy as multiple features
  were in flight. Completed features cluttered the active view, and blocked
  features had no clear parking location.
decision: |
  Each feature gets its own checklist file (CURRENT_FeatureName.md) in
  project/checklists/. Completed features move to 04_99_COMPLETED/,
  blocked features to 04_99_BLOCKED/. A TEMPLATE.md provides the standard
  format.
rationale: |
  - Each feature's state is self-contained and independently readable
  - Archival structure prevents clutter in the active directory
  - AI can glob for CURRENT_* to find only active work
consequences: |
  + Active work is immediately visible via CURRENT_* glob
  + Completed/blocked features don't pollute active context
  - More files to manage (mitigated by clear naming convention)
alternatives_rejected:
  - "Single checklist with sections: Grows unwieldy, forces full-file reads"
  - "Issue tracker only: No offline/AI-readable artifact"
affected_files:
  - development-guidelines/templates/checklist.md
  - development-guidelines/rules/session_workflow.md
supersedes: null
amends: null
superseded_by: null
```

```yaml
id: ADR-007
date: 2025-03-20
status: accepted
category: architecture
title: No hardcoded domain-specific constants
context: |
  AI assistants frequently scatter magic numbers (dimensions, thresholds,
  IDs, offsets) throughout implementations. These values become invisible
  dependencies that break silently when requirements change.
decision: |
  Domain-specific values must flow from runtime configuration objects with
  named presets, not scattered numeric literals. Mathematical/universal
  constants (pi, e) and language-level values (0, 1, "") are exempt.
rationale: |
  - Named presets are self-documenting and discoverable
  - Configuration objects make dependencies explicit
  - Changing a value requires editing one location, not grep-and-pray
consequences: |
  + All domain values are centralized and named
  + Presets serve as living documentation of valid configurations
  - Slightly more boilerplate for simple cases
alternatives_rejected:
  - "Constants file: Centralizes values but lacks semantic grouping"
  - "Comments on magic numbers: Comments drift, values still scattered"
affected_files:
  - development-guidelines/rules/no_hardcoded_constants.md
supersedes: null
amends: null
superseded_by: null
```

```yaml
id: ADR-008
date: 2025-04-05
status: accepted
category: tooling
title: setup.swift generates .claude/ bridge layer for consuming projects
context: |
  Each project using development-guidelines needed manual setup of CLAUDE.md,
  rules, commands, and directory scaffolding. This was error-prone and meant
  updates to the guidelines didn't propagate to the generated artifacts.
decision: |
  A Swift script (setup.swift) auto-generates the .claude/ bridge layer
  (rules, skills, settings) and CLAUDE.md in the consuming project. Re-running
  after a git pull updates generated files while preserving user data
  (summaries, checklists, plans).
rationale: |
  - Single command setup reduces onboarding friction
  - Re-runnable design means guideline updates propagate automatically
  - User data directories are create-if-missing, never overwritten
consequences: |
  + New projects get full integration in one command
  + Guideline updates reach all projects via git pull + re-run
  - Requires Swift toolchain to run setup (acceptable for Swift projects)
alternatives_rejected:
  - "Manual setup instructions: Error-prone, diverges across projects"
  - "Git submodule hooks: Complex, fragile, not all teams use submodules"
affected_files:
  - setup.swift
  - README.md
supersedes: null
amends: null
superseded_by: null
```

```yaml
id: ADR-009
date: 2025-04-05
status: accepted
category: architecture
title: Project state directories live inside the guidelines folder
context: |
  The original setup.swift created project/plans/,
  project/checklists/, and project/summaries/ at the consuming
  project's root. These polluted the project's working tree and sat
  outside its .gitignore, duplicating the placeholder trees already
  inside the cloned guidelines folder.
decision: |
  All project-state scaffolding lives inside the development-guidelines/
  folder. Only .claude/ and CLAUDE.md are written to the project root
  (because Claude Code expects them there). Setup includes migration
  logic to move files from root-level directories into the guidelines
  folder on re-run.
rationale: |
  - Project state stays within the guidelines folder's git boundary
  - Consuming project's working tree stays clean
  - Migration handles existing projects transparently
consequences: |
  + Clean project root with no guideline-specific directories
  + State directories are co-located with the guidelines that reference them
  - Paths in skills/CLAUDE.md are slightly longer (development-guidelines/project/summaries/)
alternatives_rejected:
  - "Keep at project root with .gitignore entries: Pollutes tree, requires per-project gitignore"
  - "Separate state repo: Overcomplicated for session-level artifacts"
affected_files:
  - setup.swift
supersedes: null
amends: null
superseded_by: null
```

```yaml
id: ADR-010
date: 2025-04-09
status: accepted
category: tooling
title: Skills format (.claude/skills/) over legacy commands (.claude/commands/)
context: |
  Claude Code moved to a skills-based discovery system. The legacy
  .claude/commands/*.md format was no longer reliably discovered,
  making workflow commands like /project:recover inaccessible.
decision: |
  Generate .claude/skills/<name>/SKILL.md instead of .claude/commands/<name>.md.
  Skills use YAML frontmatter with name, description, and argument-hint fields.
  Setup includes migration logic to remove legacy command files on re-run.
  Commands are now invoked as /recover instead of /project:recover.
rationale: |
  - Skills format is the current Claude Code standard with reliable auto-discovery
  - YAML frontmatter with name field ensures consistent registration
  - Description field enables Claude to auto-suggest relevant skills
  - Migration cleans up legacy artifacts transparently
consequences: |
  + Skills are reliably discoverable in Claude Code
  + Simpler invocation (/recover vs /project:recover)
  - Breaking change for users expecting /project:* commands (mitigated by migration)
alternatives_rejected:
  - "Keep .claude/commands/ format: Not reliably discovered by current Claude Code"
  - "Both formats simultaneously: Confusing, duplicate maintenance"
affected_files:
  - setup.swift
  - README.md
supersedes: null
amends: null
superseded_by: null
```

```yaml
id: ADR-011
date: 2025-04-09
status: accepted
category: tooling
title: Automated memory generation via MemoryBuilder in quality-gate
context: |
  Claude Code's memory system requires manual curation. Most projects have
  sparse or empty memory, leading to weaker sessions. The knowledge needed
  for effective memory entries already exists in the codebase (Package.swift,
  git history, ADRs, rules files, directory structure).
decision: |
  Add a MemoryBuilder tool to quality-gate that extracts project profile,
  architecture, conventions, active work, ADR summaries, and environment
  info into .claude/memory files. Generated files are tagged with
  generated-by: memory-builder frontmatter and only overwritten on re-run;
  manual memory files are never touched. Runs as part of every quality-gate
  invocation. Auto-detects output path. Reads ~/.claude/CLAUDE.md to avoid
  duplicating global rules in project-level memory.
rationale: |
  - Knowledge already exists in Package.swift, git, ADRs, rules files
  - Automated extraction eliminates the manual curation bottleneck
  - Tagged files enable safe re-generation without destroying user content
  - Running every invocation keeps memory current as the project evolves
  - Global CLAUDE.md awareness prevents redundant project-level entries
consequences: |
  + Every session starts with rich project context automatically
  + Memory stays current as the project evolves
  - Generated memory may be less nuanced than hand-written entries
  - Adds ~1s overhead to quality-gate runs
alternatives_rejected:
  - "Manual-only memory: Already proven insufficient — most projects have 0-1 entries"
  - "Session hooks that auto-save: Would capture noise; quality-gate runs are intentional"
  - "Explicit-only invocation: Memory drifts stale if users forget to run it"
affected_files:
  - quality-gate-swift/Sources/MemoryBuilder/
  - quality-gate-swift/Package.swift
  - quality-gate-swift/Sources/QualityGateCLI/QualityGateCLI.swift
supersedes: null
amends: null
superseded_by: null
```

---

**Last Updated:** 2025-04-09
