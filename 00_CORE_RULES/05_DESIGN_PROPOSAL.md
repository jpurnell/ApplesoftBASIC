# Design Proposal Phase

**Purpose:** Validate architectural approach BEFORE writing tests or code.

> **⚠️ This phase is MANDATORY for all non-trivial features.**
>
> Skipping this phase leads to wasted effort when the implementation violates
> project constraints, module boundaries, or architectural patterns.

---

## When to Use This Phase

| Situation | Design Proposal Required? |
|-----------|---------------------------|
| New feature with multiple components | ✅ Yes |
| Changes to existing architecture | ✅ Yes |
| New module or subsystem | ✅ Yes |
| Performance-critical code | ✅ Yes |
| Simple bug fix | ❌ No |
| Adding a single function with clear requirements | ❌ No |
| Documentation-only changes | ❌ No |

**Rule of thumb:** If you need to make decisions about *where* code goes or *how* components interact, write a design proposal first.

---

## Design Proposal Template

**Where to save proposals:** `02_IMPLEMENTATION_PLANS/PROPOSALS/FeatureName.md`
Proposals remain in `PROPOSALS/` until user approval, then move to `UPCOMING/`.

Before writing any tests or implementation code, create a brief proposal covering:

### 1. Objective

*What problem does this solve? Reference the Master Plan if applicable.*

```markdown
**Objective:** Add Monte Carlo simulation capability to support risk analysis.
**Master Plan Reference:** Phase 2 - Simulation & Risk Analytics
```

### 2. Proposed Architecture

*Where will the code live? What modules/files will be created or modified?*

```markdown
**New Files:**
- Sources/[Project]/Simulation/MonteCarloEngine.swift
- Sources/[Project]/Simulation/SimulationResult.swift

**Modified Files:**
- Sources/[Project]/Statistics/Distributions.swift (add sampling methods)

**Module Placement:** Simulation/ (new module)
```

### 3. API Surface

*What will the public interface look like? Show key types and functions.*

```swift
// Proposed API
public struct MonteCarloEngine<T: Real> {
    public init(iterations: Int, seed: UInt64?)
    public func simulate(_ model: () -> T) -> SimulationResult<T>
}

public struct SimulationResult<T: Real> {
    public let values: [T]
    public let statistics: SimulationStatistics<T>
}
```

### 4. MCP Schema

> **Why MCP?** In an AI-integrated development environment, every public API should
> be consumable by AI tools. Designing with machine-readable schemas from the start
> improves clarity and future-proofs the project.

*How will this API be consumed by AI models? Define the JSON schema.*

```markdown
**Tool Description:** Run Monte Carlo simulation with configurable iterations.

**REQUIRED STRUCTURE (JSON):**
```json
{
  "iterations": 10000,
  "seed": 42,
  "model": {
    "type": "normal",
    "parameters": {"mean": 100, "stdDev": 15}
  }
}
```

**Parameter Types:**
- iterations (integer): Number of simulation runs. Must be > 0.
- seed (integer): Random seed for reproducibility. Required for deterministic results.
- model (object): Distribution configuration.
  - type (string): "normal", "uniform", or "triangular"
  - parameters (object): Distribution-specific parameters
```

### 5. Constraints & Compliance

*How does this design comply with project rules?*

```markdown
**Concurrency:** SimulationResult is Sendable (immutable value type)
**Determinism:** Accepts optional seed for reproducible results
**Generics:** Generic over Real protocol per coding rules
**Safety:** No force unwraps, bounded iteration, validates inputs
**MCP Ready:** JSON schema defined, all types explicit
```

### 6. Backend Abstraction (If Compute-Intensive)

*For compute-intensive operations, define the backend protocol. Most Swift code runs on Apple platforms where Metal and Accelerate are available—design for this default.*

```markdown
**Backend Protocol:** SimulationBackend
**CPU Implementation:** Default, always available
**GPU Implementation:** Metal-accelerated for n > 10,000
**Accelerate Implementation:** SIMD-optimized for batch operations

**Auto-switching Threshold:** n > 10,000 triggers GPU backend
**Fallback:** CPU backend if Metal unavailable
```

> **Note:** This section is optional—include only for compute-intensive features.
> GPU/Accelerate backends are the default assumption for Apple platforms.
> For Linux server deployments, ensure CPU-only fallback is explicitly defined.

### 7. Dependencies

*What existing code does this depend on? Any new external dependencies?*

```markdown
**Internal Dependencies:**
- Statistics/Distributions.swift (for sampling)
- Utilities/DeterministicRNG.swift (for seeded randomness)

**External Dependencies:** None (uses swift-numerics only)
```

### 8. Test Strategy

*What categories of tests will be written? What is the source of truth for validation?*

```markdown
**Test Categories:**
- Golden path: Known distribution → expected statistics
- Edge cases: Zero iterations, single iteration, very large n
- Determinism: Same seed → identical results
- Performance: 100k iterations completes in <1s

**Reference Truth:** [Specify the validation source]
- Example: "Excel NPV() function", "scipy.stats.norm", "Equation 4.12 from Hull (2018)"
- Must be independently verifiable — no hallucinated expected values

**Validation Trace (REQUIRED):** Show specific inputs → expected outputs
- Example: "Validate futureValue against Excel's FV(0.05/12, 60, -100, 0) = 6,800.61"
- This exact value becomes the Golden Path test assertion
- Prevents LLM from "hallucinating" correctness
```

### 9. Architecture Decision Review

*Does this proposal require a new ADR or supersede an existing one?*

```markdown
**ADR Check:**
- [ ] Reviewed `06_ARCHITECTURE_DECISIONS.md` for related decisions
- [ ] Does this supersede an existing ADR? [No / Yes → ADR-NNN]
- [ ] Does this amend an existing ADR? [No / Yes → ADR-NNN]
- [ ] New ADR required? [No / Yes → draft entry below]

**New ADR Draft (if required):**
- Title: [Decision title]
- Category: [concurrency | storage | api | testing | performance | architecture]
- Key decision: [One sentence]
```

> **Why here?** Checking ADRs during design — not at session end — ensures the
> decisions log stays current and the AI doesn't re-discover rejected approaches.

### 10. Open Questions

*Anything that needs clarification before proceeding?*

```markdown
- Should SimulationResult store all values or just statistics?
- Should we support correlated random variables in v1?
```

### 11. Documentation Strategy

*Will this feature require API docs only, or a narrative article?*

```markdown
**Documentation Type:** [API Docs Only / Narrative Article Required]

**Complexity Threshold Check:**
- Does it combine 3+ APIs? [Yes/No]
- Does explanation require 50+ lines? [Yes/No]
- Does it need theory/background context? [Yes/No]

If any answer is "Yes" → Narrative Article Required (.md in .docc)

**Article Name (if required):** [FeatureName]Guide.md
(Must NOT match any Swift symbol name to avoid DocC parser conflicts)
```

---

## Proposal Review Checklist

Before proceeding to TDD, verify:

### Architecture
- [ ] **Module placement** follows existing project structure
- [ ] **API design** follows naming conventions from Coding Rules
- [ ] **Concurrency model** is Swift 6 compliant (Sendable, actor isolation)
- [ ] **Generic constraints** use appropriate protocols (Real, Comparable, etc.)
- [ ] **No forbidden patterns** in proposed implementation
- [ ] **Usage examples reviewed** — verify `02_USAGE_EXAMPLES.md` patterns are not broken

### MCP Readiness
- [ ] **MCP JSON schema** defined with REQUIRED STRUCTURE example
- [ ] **All parameter types** mapped to JSON Schema types
- [ ] **Stochastic functions** include seed parameter
- [ ] **Nested objects** fully documented with all properties
- [ ] **Enum values** listed exhaustively
- [ ] **Date formats** specified as ISO 8601

### Backend Abstraction (if compute-intensive)
- [ ] **Backend protocol** defined for CPU/GPU switching
- [ ] **Threshold** specified for auto-switching to GPU (default on Apple)
- [ ] **Fallback behavior** defined for Linux server deployments

### Testing & Dependencies
- [ ] **Test strategy** covers required categories (golden path, edge, invalid, determinism)
- [ ] **Reference truth** identified (Excel function, academic paper, external library)
- [ ] **Dependencies** are acceptable (no unapproved external packages)
- [ ] **Open questions** resolved or deferred explicitly

---

## Workflow Integration

The Design Proposal phase fits into the TDD workflow as **Step 0**:

> **Full Workflow:** See [Implementation Checklist Template](../04_IMPLEMENTATION_CHECKLISTS/TEMPLATE.md) for the complete Design-First TDD cycle.

---

## Example: Minimal Design Proposal

For smaller features, the proposal can be brief:

```markdown
# Design Proposal: Add `median()` function

**Objective:** Add median calculation to Statistics module.

**Location:** Sources/[Project]/Statistics/CentralTendency.swift

**API:**
```swift
public func median<T: Real>(_ values: [T]) -> T
```

**Compliance:**
- Generic over Real ✅
- Returns T(0) for empty arrays ✅
- No force unwraps ✅

**Tests:** Golden path, empty array, single element, even count, odd count

**Dependencies:** None

**Open Questions:** None
```

---

## Anti-Patterns

### ❌ Starting to Code Without Proposal

```
User: "Add caching to the API"
AI: [Immediately writes Cache.swift]  // Wrong!
```

### ✅ Proposing First

```
User: "Add caching to the API"
AI: "Before implementing, let me propose an approach:
     - Location: Utilities/Cache.swift
     - API: Generic Cache<Key, Value> with TTL support
     - Concurrency: Actor-based for thread safety
     - Dependencies: None

     I'll save this proposal to 02_IMPLEMENTATION_PLANS/PROPOSALS/Caching.md.
     Does this approach align with your expectations?"
```

---

## Related Documents

- [Master Plan](00_MASTER_PLAN.md) — Project vision and priorities
- [Coding Rules](01_CODING_RULES.md) — Implementation constraints
- [Implementation Checklist](../04_IMPLEMENTATION_CHECKLISTS/TEMPLATE.md) — Development workflow
- [Test-Driven Development](09_TEST_DRIVEN_DEVELOPMENT.md) — Testing requirements
