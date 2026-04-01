# [PROJECT_NAME] Test-Driven Development & Evaluation Directive
### Swift Testing Framework • Deterministic • Auditable • Playground-Executable

---

# Purpose

This document defines the **mandatory Test-Driven Development (TDD) and evaluation standard** for all analytical, statistical, modeling, optimization, and financial functionality in this project.

It is designed to:

- ✅ Enforce deterministic, auditable testing  
- ✅ Guarantee statistical and numerical robustness  
- ✅ Prevent stochastic flakiness  
- ✅ Ensure examples compile in Playgrounds  
- ✅ Ensure documentation examples are executable  
- ✅ Enable LLM-driven, machine-actionable evaluation  
- ✅ Protect against numerical instability and adversarial inputs  

This document stands as the **authoritative testing contract** for this repository.

---

# Core Principles

> No analytical code is complete without deterministic, reproducible, adversarially validated tests.

> Every example in documentation must compile and execute.

> Every stochastic function must be seed-controlled and auditable.

> A statistical library is only as reliable as its worst numerical edge case.

---

# Required Framework

All tests must use:

```swift
import Testing
```

Never use XCTest.

Required constructs:

- `@Suite`
- `@Test`
- `@Test(arguments:)`
- `#expect`
- `#expect(throws:)`
- `.timeLimit(...)`
- `@Suite(.serialized)` when necessary

---

# Deterministic Randomness Standard (MANDATORY)

All stochastic functions must:

1. Accept an explicit seed parameter.
2. Default to deterministic behavior in tests.
3. Never rely on implicit randomness during testing.
4. Produce auditable results.

---

## Required Seeded Generator

All tests must use the same canonical deterministic generator:

```swift
public struct DeterministicRNG: RandomNumberGenerator {
    private var state: UInt64

    public init(seed: UInt64) {
        self.state = seed
    }

    public mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1
        return state
    }
}
```

---

## Mandatory Rule

Every stochastic test must:

- Use a fixed seed
- Use sufficient sample size
- Compute tolerance from theory
- Never assert exact equality on Monte Carlo results

---

## Example (Playground-Executable)

```swift
import Testing
@testable import [PROJECT_NAME]

@Suite("Monte Carlo Tests")
struct MonteCarloTests {

    @Test("Deterministic integration of x^2")
    func integrateXSquared() {
        func f(_ x: Double) -> Double { x * x }

        var rng = DeterministicRNG(seed: 42)
        let result = integrate(f, iterations: 50_000, using: &rng)

        let expected = 1.0 / 3.0
        let tolerance = 0.01

        #expect(abs(result - expected) < tolerance)
    }
}
```

This example must compile in:

- Xcode test target
- Swift Playgrounds
- Documentation builds

---

# Documentation Executability Requirement

All code examples in documentation must:

- Compile without modification
- Include necessary imports
- Use deterministic seeds
- Avoid pseudocode
- Avoid ellipses (`...`)
- Avoid placeholders

If documentation cannot compile, it is invalid.

---

# Floating Point Safety (MANDATORY)

Never use direct equality for `Double`.

❌ Forbidden:

```swift
#expect(result == 0.3989)
```

✅ Required:

```swift
#expect(abs(result - 0.3989) < 1e-6)
```

---

## Recommended Helper

```swift
public func approxEqual(
    _ a: Double,
    _ b: Double,
    tolerance: Double = 1e-6
) -> Bool {
    abs(a - b) <= tolerance
}
```

---

# Required Test Coverage Per Function

Every public function must include:

---

## 1️⃣ Golden Path Test

Validate expected behavior with known values.

---

## 2️⃣ Edge Case Tests

### Distributions
- x below support
- x above support
- x = 0
- p = 0
- p = 1
- n = 0
- n = 1
- very large parameters
- very small parameters

### Correlation
- Perfect positive correlation
- Perfect negative correlation
- Constant vector
- Unequal length arrays
- Empty arrays
- NaN input
- Infinity input

### Confidence Intervals
- CI = 0
- CI = 1
- n = 1
- n extremely large
- stdDev = 0
- population < sample
- negative population

---

## 3️⃣ Invalid Input Tests

All public APIs must explicitly reject:

- Empty arrays
- NaN
- Infinity
- Negative sizes
- Probabilities outside [0, 1]
- Dimension mismatch
- Invalid statistical parameters

Example:

```swift
@Test("Reject negative stdDev")
func rejectNegativeStdDev() {
    #expect(throws: StatisticsError.invalidStandardDeviation.self) {
        _ = normalPDF(x: 0, mean: 0, stdDev: -1)
    }
}
```

---

## 4️⃣ Property-Based Tests

Where mathematically applicable:

- CDF monotonicity
- Symmetry
- Normalization
- Variance ≥ 0
- Correlation ∈ [-1, 1]

Example:

```swift
@Test("Normal CDF monotonicity")
func normalCDFMonotonicity() {
    for x in stride(from: -4.0, to: 4.0, by: 0.1) {
        #expect(normalCDF(x) <= normalCDF(x + 0.1))
    }
}
```

---

## 5️⃣ Numerical Stability Tests

Must test:

- Very small inputs (1e-12)
- Very large inputs (1e12)
- Underflow risk
- Overflow risk
- Catastrophic cancellation scenarios

---

## 6️⃣ Stress Tests

For large n:

```swift
@Test(.timeLimit(.seconds(2)))
func largeInputPerformance() {
    let values = Array(repeating: 1.0, count: 1_000_000)
    #expect(mean(values) == 1.0)
}
```

---

# Security & Adversarial Safeguards

Tests must guard against:

- Integer overflow
- Memory exhaustion
- Infinite loops
- Non-convergence
- log(0)
- sqrt(negative)
- exp(large)
- division by zero

Iterative algorithms must include:

```swift
@Test(.timeLimit(.seconds(2)))
func convergenceTest() {
    let result = optimize(...)
    #expect(result.converged)
}
```

---

# Parameterized Tests (Preferred)

Avoid duplication:

```swift
@Test("NPV scenarios",
      arguments: [
        (0.05, 297.59),
        (0.10, 146.87),
        (0.15, 20.42)
      ])
func npvScenarios(rate: Double, expected: Double) {
    let flows = [-1000.0, 300.0, 300.0, 300.0, 300.0]
    let result = npv(discountRate: rate, cashFlows: flows)
    #expect(abs(result - expected) < 0.01)
}
```

---

# Required Global Test Types

Each module must include:

- ✅ Golden path tests
- ✅ Edge case tests
- ✅ Invalid input tests
- ✅ Property tests
- ✅ Deterministic Monte Carlo tests
- ✅ Numerical stability tests
- ✅ Stress tests
- ✅ Regression tests
- ✅ Reference validation (Excel or analytic formula)

---

# Integration Testing Patterns

Unit tests verify individual functions. Integration tests verify that **multiple components produce consistent results** when combined.

---

## When to Write Integration Tests

- Two or more components derive the same value independently (e.g., round-trip encode/decode)
- A pipeline transforms data through multiple stages
- Outputs from one module feed into another

---

## Pattern: Cross-Component Consistency

```swift
import Testing

@Suite struct RoundTripIntegrationTests {
    @Test func encodedDataDecodesIdentically() throws {
        let original = SampleModel(name: "Test", value: 42.5)

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(SampleModel.self, from: encoded)

        #expect(decoded == original)
    }

    @Test func derivedValueMatchesDirect() throws {
        let dataA = computeViaPathA(input)
        let dataB = computeViaPathB(input)

        #expect(dataA.result.isApproximatelyEqual(to: dataB.result, absoluteTolerance: 0.01))
    }
}
```

---

# Golden Master / Regression Testing

Detect **unintended changes** to computation outputs by comparing against a stored reference ("golden master").

---

## Pattern

1. Compute the result.
2. Compare against a previously approved snapshot.
3. Fail if different.

```swift
@Test func goldenMasterProjection() throws {
    let result = model.compute(input: knownInput)

    let goldenMaster = try loadGoldenMaster("projection_v1")

    #expect(result == goldenMaster, "Regression detected — output changed from approved baseline")
}
```

**Updating golden masters:** Only update when the output change is intentional. Require explicit approval (code review or design sign-off) before overwriting a golden master file.

---

# Test Data Management

Organize test fixtures and generators consistently across projects.

---

## Directory Convention

```
Tests/
  Fixtures/
    <category>/
      sample_input.json
      known_output.json
  TestHelpers/
    DataGenerator.swift
    TestConstants.swift
  <ModuleName>Tests/
    ...
```

---

## Guidelines

- **Generators** for deterministic synthetic data — use seeded RNGs, parameterize key values
- **Fixtures** for real-world samples — keep files small, anonymize sensitive data
- **Load fixtures** via `Bundle.module.url(forResource:withExtension:)` in SPM test targets
- **Golden master files** live in `Fixtures/` alongside their category

```swift
struct TestDataGenerator {
    static func generateSample(
        count: Int = 10,
        seed: UInt64 = 42
    ) -> [SampleModel] {
        var rng = DeterministicRNG(seed: seed)
        return (0..<count).map { i in
            SampleModel(
                name: "Item \(i)",
                value: Double.random(in: 0...1000, using: &rng)
            )
        }
    }
}
```

---

# Anti-Patterns (Forbidden)

- `try!`
- Direct equality for floating point
- Unseeded randomness
- Tests asserting only `!= 0`
- Rounding before comparison
- Duplicate test names
- Missing NaN tests
- Missing stress tests
- Non-compiling documentation examples

---

# Machine-Readable Evaluation Contract

All test suite evaluations must produce:

```json
{
  "summary": {
    "overall_quality_score": 0,
    "coverage_score": 0,
    "edge_case_score": 0,
    "invalid_input_score": 0,
    "security_score": 0,
    "systemic_risks": [],
    "high_priority_gaps": []
  },
  "per_test_analysis": [],
  "missing_global_tests": {},
  "systematic_improvement_actions": []
}
```

---

# LLM Implementation Contract

When generating code, an LLM must:

1. Write tests first.
2. Include deterministic seeds for stochastic code.
3. Include golden path + edge + invalid tests.
4. Use floating-point tolerances.
5. Include property-based tests where applicable.
6. Ensure examples compile in Playground.
7. Avoid pseudocode.
8. Avoid anti-patterns.
9. Mirror directory structure.
10. Ensure documentation examples are executable.
11. Verify `swift-tools-version` compatibility — no Swift 6.0-only syntax without explicit approval.

---

# Final Guiding Rule

> Determinism enables auditability.  
> Auditability enables trust.  
> Trust requires adversarial validation.

No analytical function is production-ready until it is:

- Deterministic
- Statistically validated
- Numerically stable
- Edge-case hardened
- Adversarially tested
- Fully executable in documentation

---
