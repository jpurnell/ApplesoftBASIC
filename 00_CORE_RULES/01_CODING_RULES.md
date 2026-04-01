# Coding Rules for [PROJECT_NAME]

**Updated:** March 9, 2026
**Purpose:** Establish consistent patterns across the codebase for safety, performance, and memory efficiency

---

## 1. File Organization

### Structure
- **One primary concept per file** (function, struct, enum, or protocol)
- **Directory structure reflects conceptual hierarchy**
  ```
  Sources/[PROJECT_NAME]/
  ├── Time Series/
  │   ├── Period.swift
  │   ├── TimeSeries.swift
  │   └── TVM/
  │       ├── NPV.swift
  │       └── IRR.swift
  └── Statistics/
      └── Descriptors/
          └── Central Tendency/
              └── mean.swift
  ```
- **File naming**: camelCase for files, descriptive names
- **Work-in-progress**: Use `zzz In Process/` directory for incomplete code

### File Headers
```swift
//
//  FileName.swift
//  [PROJECT_NAME]
//
//  Created by Justin Purnell on [Date].
//

import Foundation
import Numerics
```

---

## 2. Code Style

### Generic Programming
- Use `<T: Real>` for numeric functions (from swift-numerics)
- Enables flexibility across Float, Double, Float16, etc.

```swift
public func mean<T: Real>(_ x: [T]) -> T {
    guard x.count > 0 else { return T(0) }
    return (x.reduce(T(0), +) / T(x.count))
}
```

### Function Signatures
- **Public API**: All user-facing functions/types marked `public`
- **Descriptive parameter labels**: Use external labels for clarity
  ```swift
  public func npv<T: Real>(discountRate r: T, cashFlows c: [T]) -> T
  ```
- **Default parameters**: Provide sensible defaults where appropriate
  ```swift
  public func payment<T: Real>(
      presentValue: T,
      rate: T,
      periods: Int,
      futureValue: T = T(0),
      type: AnnuityType = .ordinary
  ) -> T
  ```

### Guard Clauses & Safety Patterns

Use `guard` statements for input validation. **Never use force operations in production code.**

#### Forbidden Patterns (MANDATORY)

The following patterns are **prohibited** in production code:

| Pattern | Problem | Alternative |
|---------|---------|-------------|
| `value!` | Crashes if nil | `guard let value else { throw/return }` |
| `value as! Type` | Crashes if wrong type | `guard let typed = value as? Type else { throw }` |
| `try!` | Crashes on any error | `do { try ... } catch { ... }` |
| `array.first!` | Crashes if empty | `guard let first = array.first else { throw }` |
| `array[0]` (unchecked) | Crashes if empty | `guard !array.isEmpty else { throw }` |
| `precondition()` | Disabled in Release | `guard ... else { throw }` |
| `fatalError()` | Unrecoverable crash | `throw CustomError(...)` |

#### Why Force Operations Are Dangerous

Force operations rely on assumptions that break in production:
- Edge cases you didn't anticipate
- Malformed user input
- Concurrent modification
- Future code changes that invalidate assumptions
- Release builds disable `precondition()` entirely

#### Safe Patterns

```swift
// ❌ BAD: Force unwrap
public var firstValue: T { values.first! }

// ✅ GOOD: Safe unwrap with fallback
public var firstValue: T? { values.first }

// ✅ GOOD: Safe unwrap with error
public func firstValue() throws -> T {
    guard let first = values.first else {
        throw ProjectError.invalidInput(message: "Cannot get first value of empty collection")
    }
    return first
}
```

```swift
// ❌ BAD: Force cast
let doubleValue = value as! Double

// ✅ GOOD: Safe cast with error
guard let doubleValue = value as? Double else {
    throw ProjectError.typeMismatch(
        expected: "Double",
        actual: String(describing: type(of: value))
    )
}
```

```swift
// ❌ BAD: try! on throwing function
let result = try! riskyOperation()

// ✅ GOOD: Explicit error handling
do {
    let result = try riskyOperation()
} catch {
    throw ProjectError.operationFailed(underlying: error)
}

// ✅ ALSO GOOD: When fallback makes sense
let result = (try? riskyOperation()) ?? defaultValue
```

#### Exception: Test Code

Force unwraps are acceptable in test code only when the test is specifically verifying a value exists, and a crash is the desired behavior if the assertion fails.

#### Basic Guard Pattern

```swift
public func median<T: Real>(_ x: [T]) throws -> T {
    guard !x.isEmpty else {
        throw ProjectError.invalidInput(message: "Cannot compute median of empty array")
    }
    let sorted = x.sorted()
    // ... rest of implementation
}
```

### Division Safety

**Every division operation must check for zero denominators.**

Division by zero produces:
- `Double.infinity` or `-infinity` for floating-point
- `Double.nan` for `0.0 / 0.0`
- **Runtime crash** for integer types

All of these silently corrupt downstream calculations or crash the app.

#### Required Pattern

```swift
// ❌ BAD: Unchecked division
return numerator / denominator

// ✅ GOOD: Guard against zero
guard abs(denominator) > T.ulpOfOne else {
    throw ProjectError.divisionByZero(
        context: "Computing debt-to-equity ratio"
    )
}
return numerator / denominator
```

#### Special Cases

**Ratios where zero denominator is meaningful:**
```swift
// Current ratio with zero liabilities is actually good (debt-free)
// Don't return 0 (misleading) or crash - explain the situation
public func currentRatio<T: Real>(assets: T, liabilities: T) -> Result<T, RatioStatus> {
    guard liabilities > T.ulpOfOne else {
        return .failure(.denominatorZero(meaning: "Company has no current liabilities"))
    }
    return .success(assets / liabilities)
}
```

**Statistical measures where zero variance is undefined:**
```swift
guard stdDevX > T.ulpOfOne && stdDevY > T.ulpOfOne else {
    throw ProjectError.undefinedStatistic(
        message: "Correlation undefined: one or both variables have zero variance"
    )
}
```

#### Why `T.ulpOfOne` Instead of Zero?

Floating-point numbers have limited precision. A computation that "should" produce exactly zero might produce `0.0000000000001` instead. Using `T.ulpOfOne` (the smallest representable positive number) provides a more robust check.

### Numeric Overflow Protection

**Protect against integer overflow and floating-point extremes.**

#### Integer Overflow

Swift integers wrap on overflow by default (`Int.max + 1` becomes `Int.min`). This produces wildly incorrect results with no warning.

```swift
// ❌ BAD: Can overflow silently
let scaled = Int(doubleValue * 1_000_000)

// ✅ GOOD: Check before conversion
guard abs(doubleValue) < Double(Int.max) / 1_000_000 else {
    throw ProjectError.numericOverflow(
        context: "Value \(doubleValue) too large to scale by 1,000,000"
    )
}
let scaled = Int(doubleValue * 1_000_000)
```

#### Integer Division Truncation

Integer division discards the fractional part:
```swift
// ❌ BUG: Int(5) / Int(100) = 0, not 0.05
if ratio <= Int(5) / Int(100) { ... }  // Always true!

// ✅ CORRECT: Use floating-point for fractions
if ratio <= T(5) / T(100) { ... }
```

#### Magic Numbers

Don't return arbitrary large numbers to represent "infinity":
```swift
// ❌ BAD: Magic number that will confuse downstream code
guard hasNegativeCashFlow else {
    return 1_000_000  // "Represents infinity"
}

// ✅ GOOD: Explicit error
guard hasNegativeCashFlow else {
    throw ProjectError.undefinedStatistic(
        message: "Profitability index undefined without initial investment"
    )
}
```

### Iteration Limits

**Every loop must have a maximum iteration count.**

Unbounded loops can freeze the application indefinitely, consume all available memory, or make debugging impossible.

#### Required Pattern

```swift
// ❌ BAD: Unbounded loop
while !converged {
    // Could run forever
}

// ✅ GOOD: Bounded with informative failure
let maxIterations = 10_000
for iteration in 0..<maxIterations {
    // ... computation ...
    if converged {
        return result
    }
}
throw ProjectError.convergenceFailure(
    message: "Did not converge after \(maxIterations) iterations"
)
```

#### Recursion Limits

Convert deep recursion to iteration, or add explicit depth limits:

```swift
// ❌ BAD: Unbounded recursion (stack overflow risk)
func compute(depth: Int) -> T {
    if baseCase { return value }
    return compute(depth: depth + 1)
}

// ✅ GOOD: Iterative with limit
func compute() throws -> T {
    var state = initialState
    for _ in 0..<maxDepth {
        if state.isBaseCase { return state.value }
        state = state.next()
    }
    throw ProjectError.convergenceFailure(message: "Recursion limit exceeded")
}
```

#### Growing Collections

**Every collection that can grow must have a maximum size.**

Unbounded collections are the #1 source of memory leaks in long-running applications. This applies to:
- History/log arrays
- Caches and memoization structures
- Debug/audit trails
- Streaming buffers
- Deduplication sets

#### Required Patterns

```swift
// ❌ BAD: Unbounded history growth
var history: [Double] = []
while optimizing {
    history.append(currentValue)  // Memory grows forever
}

// ✅ GOOD: Bounded history with pruning
let maxHistorySize = 100
var history: [Double] = []
while optimizing {
    history.append(currentValue)
    if history.count > maxHistorySize {
        history.removeFirst(history.count - maxHistorySize)
    }
}

// ✅ BETTER: Use a ring buffer for O(1) operations
struct RingBuffer<T> {
    private var storage: [T?]
    private var writeIndex = 0

    init(capacity: Int) {
        storage = Array(repeating: nil, count: capacity)
    }

    mutating func append(_ value: T) {
        storage[writeIndex] = value
        writeIndex = (writeIndex + 1) % storage.count
    }
}
```

#### Deduplication Sets

When using Sets for deduplication, they must also be bounded:

```swift
// ❌ BAD: Deduplication set grows forever
var seen: Set<String> = []
for item in stream {
    if !seen.contains(item.id) {
        seen.insert(item.id)
        process(item)
    }
}

// ✅ GOOD: Bounded deduplication with LRU eviction
var seen: Set<String> = []
var seenOrder: [String] = []  // Or use Deque for O(1) removeFirst
let maxSeen = 10_000

for item in stream {
    if !seen.contains(item.id) {
        seen.insert(item.id)
        seenOrder.append(item.id)

        // Evict oldest when at capacity
        if seen.count > maxSeen {
            if let oldest = seenOrder.first {
                seenOrder.removeFirst()
                seen.remove(oldest)
            }
        }

        process(item)
    }
}
```

#### Streaming Data

**Never buffer an entire stream when windowed processing is sufficient:**

```swift
// ❌ BAD: Buffers entire stream into memory
var allValues: [Double] = []
for await value in stream {
    allValues.append(value)  // Memory grows with stream size
}
let result = analyze(allValues)

// ✅ GOOD: Process with fixed-size window
var window = RingBuffer<Double>(capacity: 1000)
for await value in stream {
    window.append(value)
    if let result = analyzeWindow(window) {
        yield result
    }
}
```

#### Public APIs for Collection-Holding Types

Any type that accumulates data must provide a clear mechanism:

```swift
// ✅ REQUIRED: Provide clear and size limit
public final class AuditTrailManager {
    private var entries: [AuditEntry] = []
    private let maxEntries: Int

    public init(maxEntries: Int = 100_000) {
        self.maxEntries = maxEntries
    }

    public func record(_ entry: AuditEntry) {
        entries.append(entry)
        if entries.count > maxEntries {
            entries.removeFirst(entries.count - maxEntries)
        }
    }

    /// Clear all recorded entries.
    public func clear() {
        entries.removeAll()
    }

    /// Current number of entries stored.
    public var count: Int { entries.count }
}
```

#### Recommended Limits

| Algorithm Type | Typical Limit | Notes |
|---------------|---------------|-------|
| Newton-Raphson | 100-1000 | Usually converges in <20 |
| Genetic/Evolutionary | 1000-10000 generations | Problem-dependent |
| Monte Carlo | 100000+ | Memory, not iterations, is limit |
| Acceptance-Rejection | 10000 | Indicates bad parameters if hit |
| Branch and Bound | 100000 nodes | Memory limit often reached first |

### Collection Safety

**Always verify collection bounds before access.**

#### Required Pattern

```swift
// ❌ BAD: Assumes array has elements
let firstRow = matrix[0]
let columnCount = matrix[0].count

// ✅ GOOD: Safe access with guard
guard let firstRow = matrix.first else {
    throw ProjectError.invalidInput(message: "Matrix cannot be empty")
}
let columnCount = firstRow.count
```

#### Multiple Index Access

When accessing multiple indices, validate all of them:

```swift
// ❌ BAD: Multiple unchecked accesses
let first = array[0]
let last = array[array.count - 1]

// ✅ GOOD: Validate once, access safely
guard array.count >= 2 else {
    throw ProjectError.insufficientData(
        message: "Need at least 2 elements, got \(array.count)"
    )
}
let first = array[0]
let last = array[array.count - 1]
```

#### Cross-Array Index Safety

When using indices from one array on another:

```swift
// ❌ BAD: Assumes arrays have same length
for i in 0..<arrayA.count {
    result.append(arrayA[i] + arrayB[i])  // Crash if arrayB shorter
}

// ✅ GOOD: Validate dimensions match
guard arrayA.count == arrayB.count else {
    throw ProjectError.dimensionMismatch(
        expected: arrayA.count,
        actual: arrayB.count
    )
}

// ✅ ALSO GOOD: Use zip for implicit safety
for (a, b) in zip(arrayA, arrayB) {
    result.append(a + b)
}
```

### Functional Patterns
- Prefer functional patterns (`reduce`, `map`, `filter`) where readable
- Balance between functional style and clarity

```swift
// Good
return (x.reduce(T(0), +) / T(x.count))

// Also good when clarity demands it
var sum = T(0)
for value in x {
    sum += value
}
return sum / T(x.count)
```

### String Formatting
**Always use Swift native string formatting instead of C-style format strings.**

Swift's `String(format:)` uses Objective-C style format specifiers (`%@`, `%d`, `%f`), but **does not support C-style width and alignment specifiers** like `%-30s` or `%8d`. These will cause runtime crashes.

#### ❌ Avoid: C-Style Format Strings
```swift
// BAD - Will crash at runtime
let output = String(format: "%-30s %8s %12s\n",
                   "Operation", "Count", "Total")

// BAD - C-style format specifiers with width
let row = String(format: "%-30s %8d %10.3fs\n",
                operationName, count, totalTime)
```

#### ✅ Prefer: Swift Native String Formatting
```swift
// GOOD - Use Swift's padding method
let opHeader = "Operation".padding(toLength: 30, withPad: " ", startingAt: 0)
let countHeader = "Count".padding(toLength: 8, withPad: " ", startingAt: 0)
let totalHeader = "Total".padding(toLength: 12, withPad: " ", startingAt: 0)

output += "\(opHeader) \(countHeader) \(totalHeader)\n"

// GOOD - Format numbers first, then pad
let opName = String(operationName.prefix(30))
    .padding(toLength: 30, withPad: " ", startingAt: 0)
let count = String(executionCount)
    .padding(toLength: 8, withPad: " ", startingAt: 0)
let total = totalTime.number(3)
    .padding(toLength: 12, withPad: " ", startingAt: 0)

output += "\(opName) \(count) \(total)\n"
```

#### Benefits of Swift Native Formatting
- **Type-safe**: Compile-time checking prevents type mismatches
- **No runtime crashes**: Invalid format strings cause compile errors, not crashes
- **More readable**: Intent is clear from method names
- **Consistent**: Works the same across all Swift platforms

#### Simple Cases: String Interpolation
For simple formatting without alignment, prefer string interpolation:

```swift
// BAD - Simple string interpolation
let message = "Total: \(count) operations in \(String(format: "%.3f", time))s"

// GOOD - Use our native Swift editors
let message = "Total: \(count) operations in \(time.number(3))s"

// GOOD - Multi-line interpolation for readability
let report = """
    Performance Report
    Total Operations: \(totalOps)
    Total Time: \(time.number(3))s
    """
```

---

## 3. Documentation (DocC Format)

> **📖 Full Reference: [DocC Guidelines](03_DOCC_GUIDELINES.md)**
>
> This section provides a quick overview. For comprehensive guidance including:
> - Article vs API documentation patterns
> - Topics vs See Also usage
> - Common pitfalls and solutions
> - MCP tool documentation standards
> - Documentation catalog structure
>
> **Always consult the full DocC Guidelines before writing documentation.**

### Quick Reference

**All public APIs must have documentation using `///`.**

#### Minimum Required Elements
```swift
/// Brief one-line summary of what the function does.
///
/// - Parameters:
///   - paramName: Description of parameter.
/// - Returns: Description of return value.
/// - Throws: Description of errors thrown (if applicable).
```

#### Recommended Additional Elements
- `## Usage Example` with executable code
- `## Excel Equivalent` for financial functions
- `- SeeAlso:` linking to related APIs
- `- Complexity:` for non-trivial algorithms

#### Key DocC Syntax
```swift
/// Link to symbol: ``TimeSeries``
/// Link to article: <doc:GettingStarted>
/// Callouts: - Note: / - Important: / - Warning: / - Tip:
```

#### Critical Rules (from full guide)
1. **Blank line after headings** — DocC parsing is whitespace-sensitive
2. **Use `## Topics` only in API docs** — Never in narrative articles
3. **End tutorials with `## Next Steps` + `## See Also`** — Not "Related Documentation"

---

## 4. Types & Protocols

### Protocols
- Define behavior contracts
- Use associated types for generic flexibility
- Document requirements clearly

```swift
/// A type that can generate random numbers from a distribution.
public protocol DistributionRandom {
    associatedtype T: Real

    /// Generate the next random value from this distribution.
    func next() -> T
}
```

### Structs
- **Prefer structs over classes** for value semantics
- Make them immutable when possible
- Conform to standard protocols: `Equatable`, `Hashable`, `Codable`

```swift
public struct Period: Hashable, Comparable, Codable {
    public let type: PeriodType
    public let date: Date
}
```

### Enums
- Use for configuration options and variants
- Add `String` raw values for serialization when appropriate
- Include computed properties and methods as needed

```swift
public enum Population: String {
    case population
    case sample
}

public enum PeriodType: String, Codable, Comparable {
    case daily
    case weekly
    case monthly
    case quarterly
    case annual

    var daysApproximate: Int {
        switch self {
        case .daily: return 1
        case .weekly: return 7
        case .monthly: return 30
        case .quarterly: return 91
        case .annual: return 365
        }
    }
}
```

---

## 5. Error Handling

### Custom Error Types
- Create dedicated error enums within the 'ProjectError' superdomain
- Place in separate files if used across multiple modules
- Use descriptive case names

```swift
/// Errors that can occur during goal seek operations.
enum GoalSeekError: Error {
    /// Function derivative is zero, causing division by zero.
    case divisionByZero

    /// Method failed to converge within maximum iterations.
    case convergenceFailed
}
```

### Throwing Functions
- Use `throws` for operations that can legitimately fail
- Document what errors can be thrown
- Provide clear context in error cases

```swift
/// Calculate IRR for a series of cash flows.
///
/// - Throws:
///   - `IRRError.allPositiveFlows`: When all cash flows are positive.
///   - `IRRError.allNegativeFlows`: When all cash flows are negative.
///   - `IRRError.convergenceFailed`: When iteration doesn't converge.
public func irr<T: Real>(
    cashFlows: [T],
    guess: T = T(0.1)
) throws -> T {
    // Implementation
}
```

### Mathematical Correctness and Invalid Inputs
**Never use default values that mask mathematically undefined operations.**

When a mathematical operation is undefined or invalid, return `NaN` or throw an error. Do not silently substitute default values that could hide bugs or produce incorrect results. If a value should be infinity, give the value .infinity

```swift
// Good - Returns NaN for mathematically undefined input
public func distributionChiSquared<T: Real>(degreesOfFreedom: Int, seeds: [Double]? = nil) -> T {
    guard degreesOfFreedom > 0 else {
        // Chi-squared distribution is undefined for df ≤ 0
        return T.nan
    }
    // ... implementation
}

// Bad - Silently uses default value, masking the error
public func distributionChiSquared<T: Real>(degreesOfFreedom: Int, seeds: [Double]? = nil) -> T {
    let df = max(1, degreesOfFreedom)  // Silently fixes invalid input
    // ... implementation
    // User never knows they passed invalid input!
}

// Also good - Throws error for invalid input (when appropriate)
public func distributionChiSquaredThrowing<T: Real>(degreesOfFreedom: Int, seeds: [Double]? = nil) throws -> T {
    guard degreesOfFreedom > 0 else {
        throw DistributionError.invalidDegreesOfFreedom(degreesOfFreedom)
    }
    return distributionChiSquared(degreesOfFreedom: degreesOfFreedom, seeds: seeds)
}
```

#### Guidelines for Invalid Inputs

1. **Return NaN** when:
   - The operation is mathematically undefined
   - You want to allow computations to continue (NaN propagates through calculations)
   - The function is used in numerical computations or simulations

2. **Throw an error** when:
   - The invalid input represents a programming error
   - The operation cannot proceed meaningfully
   - The caller needs to handle the error explicitly

3. **Never silently substitute defaults** when:
   - The default would produce mathematically incorrect results
   - The user needs to know their input was invalid
   - The default could mask bugs in calling code

4. **Document behavior clearly**:
   - State in documentation what inputs are invalid
   - Document what happens with invalid inputs (NaN, error, etc.)
   - Provide examples showing the behavior

```swift
/// Generates a random value from a Chi-squared distribution.
///
/// - Parameters:
///   - degreesOfFreedom: The degrees of freedom parameter (df > 0)
/// - Returns: A random value from χ²(df), or NaN if df ≤ 0
///
/// ## Example
///
/// ```swift
/// let valid: Double = distributionChiSquared(degreesOfFreedom: 10)
/// print(valid)  // e.g., 8.342
///
/// let invalid: Double = distributionChiSquared(degreesOfFreedom: 0)
/// print(invalid.isNaN)  // true - user is alerted to the error
/// ```
```

#### Testing Invalid Inputs

Always test that invalid inputs are handled correctly:

```swift
@Test("Chi-squared parameter validation")
func chiSquaredParameterValidation() {
    // Test that invalid degrees of freedom return NaN
    let invalidCases: [(df: Int, description: String)] = [
        (0, "zero degrees of freedom"),
        (-1, "negative degrees of freedom"),
        (-10, "large negative degrees of freedom")
    ]

    for testCase in invalidCases {
        let sample: Double = distributionChiSquared(degreesOfFreedom: testCase.df, seeds: [0.5])
        #expect(sample.isNaN, "Should return NaN for \(testCase.description)")
    }
}
```

---

## 6. Testing (Swift Testing Framework)

> **📖 Full References:**
> - **[Test-Driven Development Directive](09_TEST_DRIVEN_DEVELOPMENT.md)** — Comprehensive TDD standard
> - **[Testing Guide](TESTING.md)** — Running tests, parallelism, CI/CD
>
> This section provides a quick overview. The full TDD directive covers:
> - Required test coverage per function (golden path, edge cases, invalid inputs, property tests)
> - Deterministic randomness standard with seeded generators
> - Floating-point safety patterns
> - Numerical stability and stress testing
> - Security and adversarial safeguards
> - Anti-patterns to avoid
>
> **Always consult the full TDD Directive before writing tests.**

### Quick Reference

**Use Swift Testing framework** (not XCTest):
```swift
import Testing
@testable import YourLibrary

@Suite("Feature Tests")
struct FeatureTests {
    @Test("Description of what is tested")
    func testName() {
        #expect(result == expected)
    }
}
```

### Core Testing Requirements

| Requirement | Description |
|-------------|-------------|
| **Deterministic** | All stochastic tests must use seeded RNG |
| **Floating-point safe** | Never use `==` for doubles; use tolerance |
| **Edge cases** | Test boundaries, empty inputs, extremes |
| **Invalid inputs** | Verify proper error handling |
| **Time-bounded** | Use `.timeLimit()` for convergence tests |

### Key Patterns

```swift
// ❌ Forbidden: Direct floating-point equality
#expect(result == 0.3989)

// ✅ Required: Tolerance-based comparison
#expect(abs(result - 0.3989) < 1e-6)

// ❌ Forbidden: Unseeded randomness in tests
let sample = distribution.random()

// ✅ Required: Deterministic seeded tests
var rng = DeterministicRNG(seed: 42)
let sample = distribution.random(using: &rng)
```

### Running Tests

```bash
# Optimized parallel execution
swift test --parallel --num-workers 8

# Single test
swift test --filter "testName"
```

---

## 7. Dependencies

### Import Guidelines
- Import only what's needed
- Standard imports: `Foundation`, `Numerics`
- Testing imports: `Testing`, `@testable import [PROJECT_NAME]`

```swift
// Production code
import Foundation
import Numerics

// Test code
import Testing
import Numerics
@testable import [PROJECT_NAME]
```

### Package Dependencies
Defined in `Package.swift`:
```swift
dependencies: [
    .package(url: "https://github.com/apple/swift-numerics", from: "1.0.2"),
],
targets: [
    .target(
        name: "[PROJECT_NAME]",
        dependencies: [
            .product(name: "Numerics", package: "swift-numerics")
        ],
        swiftSettings: [
            .enableUpcomingFeature("StrictConcurrency")
        ]
    ),
]
```

---

## 8. Swift Version Compatibility

### Version Requirements
- **Minimum Required**: Swift 5.9
- **Forward Compatible**: Swift 6.0+
- **Tools Version**: `swift-tools-version: 5.9` in Package.swift

### Swift 6.0 Preparation Strategy

[PROJECT_NAME] is **Swift 5.9 compatible** while being **Swift 6.0 ready**. This dual-compatibility strategy ensures:
- Works with current Swift 5.9 toolchains
- Adopts Swift 6 concurrency features incrementally
- Smooth migration path when Swift 6.0 becomes the minimum

#### Package.swift Configuration

**Always use Swift 5.9 tools version with Swift 6 upcoming features enabled:**

```swift
// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "[PROJECT_NAME]",
    platforms: [
        .iOS(.v14),
        .macOS(.v13),
        .tvOS(.v14),
        .watchOS(.v7),
        .visionOS(.v1)
    ],
    // ... products and dependencies ...
    targets: [
        .target(
            name: "[PROJECT_NAME]",
            dependencies: [
                .product(name: "Numerics", package: "swift-numerics")
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        // ... other targets ...
    ]
)
```

#### Key Requirements

1. **Swift Tools Version**: Must be `5.9` (not `6.0`)
   ```swift
   // ✅ CORRECT
   // swift-tools-version: 5.9

   // ❌ WRONG - Too new, excludes Swift 5.9 users
   // swift-tools-version: 6.0
   ```

2. **Enable Strict Concurrency**: Required for all targets
   ```swift
   swiftSettings: [
       .enableUpcomingFeature("StrictConcurrency")
   ]
   ```

3. **Mandatory Swift 6 Compliance Testing**: All code MUST pass strict concurrency checks
   ```bash
   # REQUIRED: Build with full strict concurrency checking
   swift build -Xswiftc -strict-concurrency=complete

   # REQUIRED: Run tests with strict concurrency
   swift test -Xswiftc -strict-concurrency=complete

   # Build must complete with zero concurrency errors
   # Warnings about unhandled files (.disabled, .metal, READMEs) are acceptable
   ```

4. **CI/CD Integration**: Automated builds must verify Swift 6 compliance
   ```yaml
   # Required in all CI workflows
   - name: Verify Swift 6 Compliance
     run: |
       swift build -Xswiftc -strict-concurrency=complete
       swift test -Xswiftc -strict-concurrency=complete
   ```

### Why This Matters

**Swift 5.9 Minimum**:
- Many users still on Xcode 15.x (includes Swift 5.9)
- Broader compatibility means more users can adopt the library
- Stable, production-ready toolchain

**Swift 6.0 Strict Compliance** (MANDATORY):
- StrictConcurrency catches data race issues at compile time
- All code MUST compile with `-strict-concurrency=complete`
- Smooth upgrade path when Swift 6.0 becomes standard
- Code is 100% compliant with Swift 6 requirements
- **No exceptions**: Data race safety is non-negotiable

**Common Mistake to Avoid**:
```swift
// ❌ DO NOT DO THIS - Breaks Swift 5.9 compatibility
// swift-tools-version: 6.0
```

This would force all users to upgrade to Swift 6.0, which:
- Excludes users on older Xcode versions
- May break compatibility with other packages
- Is unnecessary since we can use Swift 6 features in 5.9

**Critical Rule**:
- ✅ Use `swift-tools-version: 5.9` for broad compatibility
- ✅ Enable `StrictConcurrency` for Swift 6 compliance
- ✅ Test with `-strict-concurrency=complete` to verify
- ❌ Never merge code that fails strict concurrency checks

### Version Compatibility Matrix

| Swift Version | Status | Compliance Level | Notes |
|--------------|--------|------------------|-------|
| 5.9.x | ✅ Supported | Full Swift 6 strict concurrency | Minimum required version |
| 6.0.x | ✅ Supported | Native Swift 6 compliance | Forward compatible, tested with `-strict-concurrency=complete` |
| < 5.9 | ❌ Not Supported | N/A | Missing required features |

### Compliance Verification

**Before Every Commit:**
```bash
# Run these commands and verify ZERO concurrency errors
swift build -Xswiftc -strict-concurrency=complete
swift test -Xswiftc -strict-concurrency=complete
```

**Expected Output:**
- ✅ Build complete with no concurrency errors
- ⚠️ Warnings about unhandled files are acceptable (.disabled, .metal, READMEs)
- ❌ Any concurrency-related errors MUST be fixed before committing

**Acceptable Warnings:**
```
warning: '[project_name]': found N file(s) which are unhandled
    /path/to/file.swift.disabled
    /path/to/shader.metal
    /path/to/README.md
```

**Unacceptable Errors:**
```
error: sending 'self' risks causing data races
error: capture of 'x' with non-sendable type
error: mutation of captured var 'y' in concurrently-executing code
```

---

## 9. Concurrency (MANDATORY)

### Swift 6 Strict Concurrency Compliance

**ALL code must compile with zero errors under strict concurrency checking.**

This is a non-negotiable requirement enforced on every commit:
```bash
swift build -Xswiftc -strict-concurrency=complete  # Must pass with 0 errors
swift test -Xswiftc -strict-concurrency=complete   # Must pass with 0 errors
```

### Strict Concurrency Rules

1. **Always enabled**: `.enableUpcomingFeature("StrictConcurrency")` in Package.swift
2. **Zero concurrency errors**: Any data race error is a blocker
3. **Prefer value types**: Structs are automatically `Sendable` when their components are
4. **Mark types explicitly**: Add `Sendable` conformance to reference types only when thread-safe
5. **Test with Thread Sanitizer**: Enable in scheme settings during development

### Value Type Pattern (Preferred)

```swift
// Value types are automatically Sendable when their components are
public struct DenseMatrix<T: Real>: Sendable where T: Sendable {
    private let data: [[T]]  // Immutable storage
    public let rows: Int
    public let columns: Int

    // All methods are implicitly thread-safe (value semantics)
    public func multiplied(by other: DenseMatrix<T>) -> DenseMatrix<T> {
        // Implementation
    }
}
```

**Why this matters**: Value types eliminate shared mutable state, preventing data races by design.

### Reference Type Pattern (When Necessary)

```swift
// Reference types need explicit Sendable conformance and synchronization
public final class MatrixCache: @unchecked Sendable {
    private let lock = NSLock()
    private var _cache: [String: [[Double]]] = [:]

    public func get(_ key: String) -> [[Double]]? {
        lock.lock()
        defer { lock.unlock() }
        return _cache[key]
    }

    public func set(_ key: String, value: [[Double]]) {
        lock.lock()
        defer { lock.unlock() }
        _cache[key] = value
    }
}
```

**⚠️ Use `@unchecked Sendable` only when**:
- You've implemented manual synchronization (locks, atomics)
- You've documented the thread-safety guarantees
- You've tested with Thread Sanitizer

### Actor Pattern (Modern Concurrency)

```swift
/// Thread-safe matrix computation cache using Swift concurrency.
///
/// All operations are serialized automatically by the actor runtime.
@available(macOS 10.15, iOS 13.0, *)
public actor MatrixComputationCache {
    private var cache: [String: [[Double]]] = [:]

    public func get(_ key: String) -> [[Double]]? {
        cache[key]
    }

    public func set(_ key: String, value: [[Double]]) {
        cache[key] = value
    }
}
```

### Concurrency Testing Requirements

1. **Enable Thread Sanitizer** during development
   - Xcode: Edit Scheme → Run → Diagnostics → Thread Sanitizer ✓

2. **Test concurrent access patterns**
   ```swift
   @Test("Concurrent matrix operations are thread-safe")
   func concurrentOperations() async {
       let matrix = DenseMatrix(...)

       await withTaskGroup(of: DenseMatrix<Double>.self) { group in
           for _ in 0..<100 {
               group.addTask { matrix.transposed() }
           }
       }
       // Should complete without crashes or data corruption
   }
   ```

3. **Document thread safety** in API documentation
   ```swift
   /// Multiply two matrices.
   ///
   /// This operation is thread-safe and can be called concurrently
   /// from multiple tasks without synchronization.
   ///
   /// - Complexity: O(n³) where n is the matrix dimension
   public func multiplied(by other: DenseMatrix<T>) -> DenseMatrix<T>
   ```

### Forbidden Patterns

❌ **Never:**
- Use global mutable state without synchronization
- Share mutable reference types across threads without protection
- Ignore concurrency warnings during compilation
- Mark types as `@unchecked Sendable` without manual synchronization
- Commit code that fails `-strict-concurrency=complete` checks

✅ **Always:**
- Prefer immutable value types
- Use actors for stateful concurrent operations
- Add `Sendable` conformance explicitly to document thread safety
- Test with Thread Sanitizer enabled
- Verify zero concurrency errors before committing

---

## 10. GPU Acceleration Architecture (MANDATORY)

### Performance Through Hardware Acceleration

**ALL computationally intensive operations must support GPU acceleration on capable platforms.**

This requirement applies to:
- Matrix operations (multiplication, decomposition, solving)
- Large-scale optimization (populations ≥ 1,000)
- Monte Carlo simulations (iterations ≥ 10,000)
- Statistical computations on large datasets (n ≥ 10,000)

### Architecture Pattern: Backend Protocol

Use **protocol-based abstraction** to support multiple backends:

```swift
/// Backend for matrix computations.
///
/// Implementations provide CPU or GPU execution based on platform capabilities.
public protocol MatrixBackend: Sendable {
    /// Multiply two matrices: C = A × B
    func multiply(_ A: [[Double]], _ B: [[Double]]) -> [[Double]]

    /// Solve linear system: Ax = b
    func solve(_ A: [[Double]], _ b: [Double]) -> [Double]

    /// QR decomposition: A = QR
    func qrDecomposition(_ A: [[Double]]) -> (q: [[Double]], r: [[Double]])
}
```

### CPU Backend (Always Available)

```swift
/// Pure Swift CPU implementation of matrix operations.
///
/// Used as fallback on all platforms and primary implementation on non-Apple platforms.
public struct CPUMatrixBackend: MatrixBackend {
    public func multiply(_ A: [[Double]], _ B: [[Double]]) -> [[Double]] {
        // Pure Swift implementation
        // Uses SIMD when beneficial
    }

    public func solve(_ A: [[Double]], _ b: [Double]) -> [Double] {
        // QR decomposition with back-substitution
    }
}
```

### GPU Backend (Apple Silicon)

```swift
#if canImport(Metal)
import Metal

/// Metal-accelerated matrix operations for Apple Silicon.
///
/// Provides 10-100× speedup for large matrices (n ≥ 1000).
/// Automatically selected when Metal is available and matrix size justifies GPU overhead.
public struct MetalMatrixBackend: MatrixBackend {
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let library: MTLLibrary

    public init?() {
        guard let device = MTLCreateSystemDefaultDevice(),
              let commandQueue = device.makeCommandQueue(),
              let library = device.makeDefaultLibrary() else {
            return nil
        }
        self.device = device
        self.commandQueue = commandQueue
        self.library = library
    }

    public func multiply(_ A: [[Double]], _ B: [[Double]]) -> [[Double]] {
        // Metal kernel for matrix multiplication
        // See matrixMultiply.metal shader
    }
}
#endif
```

### Accelerate Backend (Apple Platforms)

```swift
#if canImport(Accelerate)
import Accelerate

/// Accelerate framework backend using optimized BLAS/LAPACK.
///
/// Provides 5-20× speedup using Apple's optimized linear algebra libraries.
/// Preferred over pure Swift for medium-sized matrices (100 ≤ n < 1000).
public struct AccelerateMatrixBackend: MatrixBackend {
    public func multiply(_ A: [[Double]], _ B: [[Double]]) -> [[Double]] {
        // Use cblas_dgemm for matrix multiplication
        var result = [[Double]](repeating: [Double](repeating: 0, count: B[0].count),
                                 count: A.count)

        // Convert to column-major for BLAS
        // Call cblas_dgemm
        // Convert back to row-major

        return result
    }

    public func solve(_ A: [[Double]], _ b: [Double]) -> [Double] {
        // Use dgesv_ for general linear systems
        // Or dpotrs_ for symmetric positive definite
    }
}
#endif
```

### Automatic Backend Selection

```swift
/// Automatically selects the best backend based on platform and problem size.
public struct MatrixBackendSelector {
    public static func selectBackend(matrixSize: Int) -> any MatrixBackend {
        #if canImport(Metal)
        // Use Metal for very large matrices on Apple Silicon
        if matrixSize >= 1000, let metalBackend = MetalMatrixBackend() {
            return metalBackend
        }
        #endif

        #if canImport(Accelerate)
        // Use Accelerate for medium-to-large matrices on Apple platforms
        if matrixSize >= 100 {
            return AccelerateMatrixBackend()
        }
        #endif

        // Fallback to CPU for small matrices or non-Apple platforms
        return CPUMatrixBackend()
    }
}
```

### User-Facing API (Backend-Agnostic)

```swift
/// Multiply two matrices with automatic backend selection.
///
/// Automatically uses GPU acceleration on capable platforms for large matrices.
/// Falls back to optimized CPU implementation otherwise.
///
/// - Parameters:
///   - A: Left matrix (m × n)
///   - B: Right matrix (n × p)
///   - backend: Optional backend override (default: automatic selection)
///
/// - Returns: Product matrix (m × p)
///
/// - Complexity:
///   - CPU: O(mnp)
///   - GPU: O(mnp/cores) for large matrices
public func multiplyMatrices(
    _ A: [[Double]],
    _ B: [[Double]],
    backend: (any MatrixBackend)? = nil
) -> [[Double]] {
    let selectedBackend = backend ?? MatrixBackendSelector.selectBackend(
        matrixSize: max(A.count, B[0].count)
    )
    return selectedBackend.multiply(A, B)
}
```

### Metal Shader Example

Create `matrixMultiply.metal`:

```metal
#include <metal_stdlib>
using namespace metal;

// Matrix multiplication kernel: C = A × B
kernel void matrixMultiply(
    const device float* A [[buffer(0)]],
    const device float* B [[buffer(1)]],
    device float* C [[buffer(2)]],
    constant uint& M [[buffer(3)]],  // Rows of A
    constant uint& N [[buffer(4)]],  // Cols of A / Rows of B
    constant uint& P [[buffer(5)]],  // Cols of B
    uint2 gid [[thread_position_in_grid]]
) {
    uint row = gid.y;
    uint col = gid.x;

    if (row >= M || col >= P) return;

    float sum = 0.0;
    for (uint k = 0; k < N; k++) {
        sum += A[row * N + k] * B[k * P + col];
    }

    C[row * P + col] = sum;
}
```

### Performance Benchmarking

**Every GPU-accelerated operation must include performance benchmarks:**

```swift
@Test("GPU vs CPU performance comparison")
func gpuVsCPUPerformance() {
    let n = 1000
    let A = randomMatrix(rows: n, columns: n)
    let B = randomMatrix(rows: n, columns: n)

    // CPU baseline
    let cpuBackend = CPUMatrixBackend()
    let cpuStart = ContinuousClock.now
    let cpuResult = cpuBackend.multiply(A, B)
    let cpuTime = cpuStart.duration(to: .now)

    #if canImport(Metal)
    // GPU acceleration
    guard let metalBackend = MetalMatrixBackend() else {
        Issue.record("Metal not available")
        return
    }

    let gpuStart = ContinuousClock.now
    let gpuResult = metalBackend.multiply(A, B)
    let gpuTime = gpuStart.duration(to: .now)

    let speedup = Double(cpuTime.components.seconds) / Double(gpuTime.components.seconds)

    #expect(speedup >= 5.0, "GPU should be at least 5× faster for n=1000")
    #expect(matricesEqual(cpuResult, gpuResult, tolerance: 1e-6))
    #endif
}
```

### GPU Acceleration Checklist

For every computationally intensive operation:

- [ ] Protocol-based backend abstraction implemented
- [ ] CPU backend (pure Swift) implemented and tested
- [ ] GPU backend (Metal) implemented for Apple platforms
- [ ] Accelerate backend (BLAS/LAPACK) implemented for Apple platforms
- [ ] Automatic backend selection based on problem size
- [ ] Performance benchmarks showing speedup metrics
- [ ] Graceful fallback when GPU unavailable
- [ ] Documentation includes performance characteristics
- [ ] Metal shaders compile without warnings
- [ ] Results match across all backends (within numerical tolerance)

### Integration with Existing GPU Code

If your project includes GPU acceleration (e.g., for genetic algorithms), follow the same patterns:

1. **Separate shader files** (`.metal`) in Sources
2. **Conditional compilation** with `#if canImport(Metal)`
3. **Performance thresholds** for GPU activation
4. **Comprehensive testing** across backends
5. **Clear documentation** of when GPU is used

### Why This Matters

**Performance Impact:**
- Matrix operations: 10-100× speedup for n ≥ 1000
- Large-scale regression: Sub-second fitting for 10,000 observations
- Real-time interactive analysis in production applications

**Platform Support:**
- Pure Swift works everywhere (Linux, Windows, non-Apple platforms)
- GPU acceleration on Apple Silicon (Metal)
- Accelerate optimization on all Apple platforms
- Users get best performance for their platform automatically

**Example Speedups (1000×1000 matrices):**
- Pure Swift: ~2.5 seconds
- Accelerate: ~0.3 seconds (8× faster)
- Metal: ~0.025 seconds (100× faster)

---

## 11. API Design Principles

### Clarity at Point of Use
```swift
// Good
let result = npv(discountRate: 0.1, cashFlows: flows)

// Bad
let result = npv(0.1, flows)
```

### Fluent APIs
Support method chaining where appropriate:
```swift
let adjusted = timeSeries
    .fillForward()
    .map { $0 * 1.1 }
    .movingAverage(window: 3)
```

### Progressive Disclosure
- Simple cases should be simple
- Advanced features available but not required
- Use defaults liberally

```swift
// Simple case
let pv = presentValue(futureValue: 1000, rate: 0.05, periods: 10)

// Advanced case
let pv = presentValueAnnuity(
    payment: 100,
    rate: 0.05,
    periods: 10,
    type: .due
)
```

---

## 12. Performance Considerations

### Measurement
- Profile before optimizing
- Document complexity for non-trivial algorithms
- Consider lazy evaluation for large datasets

### Guidelines
- Prefer `O(1)` lookups (use dictionaries/sets)
- Avoid unnecessary allocations
- Use copy-on-write for collections
- Consider caching expensive computations

```swift
// Good - O(1) lookup
private let values: [Period: T]

// Less good - O(n) lookup
private let values: [(Period, T)]
```

---

## 13. Version Control

### Commits
- Clear, descriptive commit messages
- One logical change per commit
- Test before committing

### Branches
- Work in feature branches for significant changes
- Main branch should always build and pass tests

---

## 14. Random Number Generation

### Testing vs Production Randomness

Projects commonly use random numbers for Monte Carlo simulations, stochastic optimization (genetic algorithms, simulated annealing), and statistical sampling.

**Testing requires reproducibility. Production requires quality.**

### Seeded Generators for Testing

```swift
/// TESTING ONLY - Deterministic random number generator.
///
/// - Warning: This generator is predictable. Never use for:
///   - Security-sensitive operations
///   - Production simulations where unpredictability matters
///
/// Use `SystemRandomNumberGenerator` for production code.
@available(*, deprecated, message: "For testing only - not suitable for production")
internal struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed
    }

    mutating func next() -> UInt64 {
        // SplitMix64 - better statistical properties than LCG
        state &+= 0x9e3779b97f4a7c15
        var z = state
        z = (z ^ (z >> 30)) &* 0xbf58476d1ce4e5b9
        z = (z ^ (z >> 27)) &* 0x94d049bb133111eb
        return z ^ (z >> 31)
    }
}
```

### Random Value Normalization

Convert random bits to floating-point correctly:

```swift
// ❌ BAD: Can produce exactly 1.0
let random = Double(bits >> 32) / Double(UInt32.max)

// ✅ GOOD: Produces [0, 1) exclusive of 1.0
let random = Double(bits >> 32) / Double(1 << 32)
```

Why this matters: Many formulas break when random = 1.0 (e.g., `log(1 - random)` → `log(0)` → negative infinity).

### Default Parameter Entropy

Don't evaluate random expressions in default parameters:

```swift
// ❌ BAD: Consumes entropy even when seed is provided
func sample(seed: Double = Double.random(in: 0..<1)) -> T

// ✅ GOOD: Only generate random when needed
func sample(seed: Double? = nil) -> T {
    let actualSeed = seed ?? Double.random(in: 0..<1)
    // ...
}
```

### Naming Conventions for Test Configurations

```swift
// ❌ CONFUSING: Sounds like a production default
public static let seededDefault = Config(seed: 42)

// ✅ CLEAR: Obviously for testing
public static let testConfiguration = Config(seed: 42)
public static let deterministicForTesting = Config(seed: 42)
```

### Documentation Requirements

All randomness-dependent functions must document:
1. Whether seeding is supported
2. The statistical properties required (uniform, normal, etc.)
3. Whether results are reproducible with the same seed

```swift
/// Generate samples from a normal distribution.
///
/// - Parameters:
///   - mean: Distribution mean
///   - stdDev: Distribution standard deviation
///   - seed: Optional seed for reproducible results. If nil, uses system RNG.
///
/// - Returns: A random sample from N(mean, stdDev²)
///
/// - Note: When seed is provided, results are deterministic and reproducible.
///   Use this for testing. For production Monte Carlo simulations, omit the seed
///   parameter to use cryptographically-seeded system randomness.
public func normalSample<T: Real>(mean: T, stdDev: T, seed: Double? = nil) -> T
```

---

## 15. Memory Management (MANDATORY)

### Value Types vs Reference Types

**Prefer structs over classes.** Value types eliminate entire categories of memory bugs:
- No retain cycles (value types are copied, not referenced)
- No shared mutable state
- Automatic `Sendable` conformance when components are Sendable
- Predictable memory behavior

```swift
// ✅ PREFERRED: Value type - no memory management concerns
public struct Optimizer<T: Real> {
    private var history: [T] = []
    private let maxIterations: Int

    public mutating func optimize() -> T {
        // Mutations create new value, no shared state
    }
}

// ⚠️ USE SPARINGLY: Reference type - requires careful memory management
public final class CacheManager {
    // Must consider: retain cycles, thread safety, lifecycle
}
```

### Class Memory Rules

When classes are necessary, follow these rules:

#### Rule 1: Implement deinit for Resource-Holding Classes

```swift
// ❌ BAD: No explicit cleanup
final class MetalBufferPool {
    private var buffers: [MTLBuffer] = []
    // Relies on ARC, no visibility into cleanup
}

// ✅ GOOD: Explicit deinit documents and enables cleanup
final class MetalBufferPool {
    private var buffers: [MTLBuffer] = []

    deinit {
        // Clear any pending operations
        buffers.removeAll()
        #if DEBUG
        print("MetalBufferPool deallocated: \(bufferCount) buffers released")
        #endif
    }
}
```

#### Rule 2: Use Weak References for Delegates and Parents

```swift
// ❌ BAD: Strong reference creates retain cycle
class Child {
    var parent: Parent?  // Strong reference
}

class Parent {
    var child: Child?
}
// parent.child = child; child.parent = parent → MEMORY LEAK

// ✅ GOOD: Weak reference breaks cycle
class Child {
    weak var parent: Parent?  // Weak reference
}

class Parent {
    var child: Child?
}
// No retain cycle - parent can be deallocated
```

#### Rule 3: Use Capture Lists in Closures

```swift
// ❌ BAD: Strong capture creates retain cycle
class ViewModel {
    var onUpdate: (() -> Void)?

    func setup() {
        onUpdate = {
            self.refresh()  // Strong capture of self
        }
    }
}

// ✅ GOOD: Weak capture prevents cycle
class ViewModel {
    var onUpdate: (() -> Void)?

    func setup() {
        onUpdate = { [weak self] in
            self?.refresh()
        }
    }
}
```

### Cache Memory Rules

All caches must have:
1. **Maximum size** with eviction policy
2. **Public clear method** for manual cleanup
3. **Efficient eviction** (O(1) or O(log n), not O(n))

```swift
// ❌ BAD: Cache grows forever
final class ComputationCache {
    private var cache: [String: Any] = [:]

    func get(_ key: String, compute: () -> Any) -> Any {
        if let cached = cache[key] { return cached }
        let result = compute()
        cache[key] = result  // Never evicted!
        return result
    }
}

// ✅ GOOD: Bounded cache with LRU eviction
final class ComputationCache {
    private var cache: [String: CachedValue] = [:]
    private var accessOrder: [String] = []  // Or Deque for O(1)
    private let maxSize: Int

    public init(maxSize: Int = 1000) {
        self.maxSize = maxSize
    }

    func get(_ key: String, compute: () -> Any) -> Any {
        if let cached = cache[key] {
            updateAccessOrder(key)
            return cached.value
        }

        let result = compute()
        cache[key] = CachedValue(value: result)
        accessOrder.append(key)

        // Evict LRU entries
        while cache.count > maxSize {
            if let oldest = accessOrder.first {
                accessOrder.removeFirst()
                cache.removeValue(forKey: oldest)
            }
        }

        return result
    }

    /// Clear all cached values.
    public func clear() {
        cache.removeAll()
        accessOrder.removeAll()
    }
}
```

### Metal/GPU Resource Management

GPU resources require special attention because:
- GPU memory is separate from system memory
- Buffers may not be released immediately by ARC
- Creating buffers is expensive; prefer reuse

#### Rule 1: Use Autorelease Pools for Batch Operations

```swift
// ❌ BAD: Buffers accumulate during loop
func runSimulations(count: Int) -> [Result] {
    var results: [Result] = []
    for i in 0..<count {
        let buffer = device.makeBuffer(length: size)!
        results.append(compute(buffer))
        // Buffer not released until function returns
    }
    return results
}

// ✅ GOOD: Explicit cleanup per iteration
func runSimulations(count: Int) -> [Result] {
    var results: [Result] = []
    for i in 0..<count {
        autoreleasepool {
            let buffer = device.makeBuffer(length: size)!
            results.append(compute(buffer))
            // Buffer released at end of autoreleasepool
        }
    }
    return results
}
```

#### Rule 2: Reuse Buffers When Possible

```swift
// ❌ BAD: Create new buffers every iteration
for generation in 0..<1000 {
    let populationBuffer = device.makeBuffer(...)  // 1000 allocations!
    let fitnessBuffer = device.makeBuffer(...)
    // ...
}

// ✅ GOOD: Pre-allocate and reuse
let populationBuffer = device.makeBuffer(length: maxSize)!
let fitnessBuffer = device.makeBuffer(length: maxSize)!

for generation in 0..<1000 {
    updateBufferContents(populationBuffer, with: population)
    // Reuse existing buffers
}
```

#### Rule 3: Always End Encoders

```swift
// ❌ BAD: Early return without cleanup
guard let encoder = commandBuffer.makeComputeCommandEncoder() else {
    return nil
}
guard let pipeline = getPipeline() else {
    return nil  // Encoder never ended!
}

// ✅ GOOD: Defer ensures cleanup
guard let encoder = commandBuffer.makeComputeCommandEncoder() else {
    return nil
}
defer { encoder.endEncoding() }

guard let pipeline = getPipeline() else {
    return nil  // Encoder properly ended via defer
}
```

### Async Task Lifecycle Management

Detached tasks can outlive their intended scope, wasting CPU and memory.

#### Rule 1: Store Task Handles for Cancellation

```swift
// ❌ BAD: Fire-and-forget task
func startProcessing() {
    Task {
        while true {
            await process()  // Runs forever!
        }
    }
}

// ✅ GOOD: Store handle, cancel on deinit
class Processor {
    private var processingTask: Task<Void, Never>?

    func start() {
        processingTask = Task {
            while !Task.isCancelled {
                await process()
            }
        }
    }

    func stop() {
        processingTask?.cancel()
        processingTask = nil
    }

    deinit {
        processingTask?.cancel()
    }
}
```

#### Rule 2: Check Cancellation in Long-Running Tasks

```swift
// ❌ BAD: Ignores cancellation
AsyncThrowingStream { continuation in
    Task {
        for iteration in 0..<10_000 {
            let result = compute(iteration)
            continuation.yield(result)
            // If consumer stops after 100 iterations,
            // we still compute 9,900 more!
        }
    }
}

// ✅ GOOD: Respects cancellation
AsyncThrowingStream { continuation in
    Task {
        for iteration in 0..<10_000 {
            if Task.isCancelled {
                continuation.finish(throwing: CancellationError())
                return
            }
            let result = compute(iteration)
            continuation.yield(result)
        }
        continuation.finish()
    }
}
```

#### Rule 3: Clean Up Continuations

```swift
// ❌ BAD: Continuation may be resumed after cancellation
struct InflightEntry {
    var waiters: [CheckedContinuation<Void, Never>] = []
}

// Later, task is cancelled but waiter remains in array
// When leader finishes: for waiter in waiters { waiter.resume() }
// Undefined behavior for cancelled tasks!

// ✅ GOOD: Track task lifecycle with waiters
struct InflightEntry {
    var waiters: [(continuation: CheckedContinuation<Void, Never>, task: Task<Void, Never>)] = []
}

// Only resume non-cancelled waiters
for (continuation, task) in waiters where !task.isCancelled {
    continuation.resume()
}
```

### Streaming API Design

Streaming APIs should process data incrementally, not buffer everything.

```swift
// ❌ BAD: "Streaming" API that buffers everything
public struct StreamingAnalyzer {
    private var allValues: [Double] = []

    public mutating func analyze() async throws -> Result {
        // Collects entire stream first
        while let value = try await iterator.next() {
            allValues.append(value)
        }
        // Then processes
        return computeResult(allValues)
    }
}

// ✅ GOOD: True streaming with bounded memory
public struct StreamingAnalyzer {
    private var window: RingBuffer<Double>
    private var runningStats: IncrementalStatistics

    public init(windowSize: Int = 1000) {
        self.window = RingBuffer(capacity: windowSize)
        self.runningStats = IncrementalStatistics()
    }

    public mutating func analyze() async throws -> AsyncStream<PartialResult> {
        AsyncStream { continuation in
            Task {
                while let value = try await iterator.next() {
                    window.append(value)
                    runningStats.update(value)

                    // Emit partial results as we go
                    if shouldEmit() {
                        continuation.yield(runningStats.currentResult)
                    }
                }
                continuation.finish()
            }
        }
    }
}
```

### Memory Audit Checklist

For every class:
- [ ] `deinit` implemented if holding resources
- [ ] Delegate/parent references are `weak`
- [ ] Closure captures use `[weak self]` or `[unowned self]`
- [ ] No circular strong references

For every cache:
- [ ] Maximum size defined
- [ ] Eviction policy implemented (LRU, TTL, etc.)
- [ ] Public `clear()` method available
- [ ] Eviction is O(1) or O(log n), not O(n)

For every Metal/GPU operation:
- [ ] Buffers reused where possible
- [ ] Autoreleasepool around batch operations
- [ ] Command encoders always ended (use `defer`)
- [ ] Buffer pool cleaned up in `deinit`

For every async task:
- [ ] Task handle stored if long-running
- [ ] Cancellation checked in loops
- [ ] Continuations properly managed
- [ ] `deinit` cancels owned tasks

For every streaming API:
- [ ] Uses bounded buffers (ring buffer or max size)
- [ ] Emits results incrementally
- [ ] Doesn't buffer entire stream
- [ ] Cancellation propagated to background tasks

---

## Summary Checklist

For every public API:
- [ ] Public access modifier
- [ ] Complete DocC documentation with examples
- [ ] Descriptive parameter labels
- [ ] Appropriate error handling (return NaN or throw errors for mathematically undefined operations)
- [ ] Never use default values that mask mathematical errors
- [ ] Use Swift native string formatting (`.padding()`) instead of C-style format strings
- [ ] Generic over `Real` where applicable
- [ ] Comprehensive tests with `@Test` attributes
- [ ] Edge case handling
- [ ] Tests for invalid inputs verify NaN or error behavior
- [ ] Performance considerations documented
- [ ] Provide a comprehensive tutorial of all new functionality that can run directly in an Xcode playground
- [ ] **Thread safety**: Value type (preferred) or explicit `Sendable` conformance
- [ ] **GPU acceleration**: Protocol-based backend for computationally intensive operations
- [ ] **No force operations**: No `!`, `as!`, `try!`, `fatalError`, or `precondition` in production code
- [ ] **Division safety**: All divisions guarded against zero denominators
- [ ] **Overflow protection**: Large numeric operations checked for overflow
- [ ] **Bounded iterations**: All loops have maximum iteration limits
- [ ] **Collection safety**: Array access guarded with bounds checks
- [ ] **Randomness documented**: Seeding behavior and statistical properties documented
- [ ] **Bounded collections**: All growing collections have maximum size limits
- [ ] **Cache eviction**: All caches have eviction policies and public clear() methods

For every commit:
- [ ] **Swift 6 Compliance (MANDATORY)**: `swift build -Xswiftc -strict-concurrency=complete` passes with **zero concurrency errors**
- [ ] **All Tests Pass**: `swift test -Xswiftc -strict-concurrency=complete` completes successfully
- [ ] Code compiles on Swift 5.9+ (minimum version)
- [ ] Thread safety verified for concurrent code (marked `Sendable`, uses actors, or properly synchronized)
- [ ] No data race warnings or errors
- [ ] Metal shaders compile (if GPU acceleration added)
- [ ] **Safety audit**: Search for `!`, `as!`, `try!`, `fatalError`, `while true` - justify or fix each occurrence
- [ ] **Memory audit**: Collections have size limits, caches have eviction, async tasks have cancellation

For computationally intensive features (matrix operations, optimization, simulation):
- [ ] Protocol-based backend abstraction
- [ ] CPU backend implemented (pure Swift)
- [ ] GPU backend implemented (Metal on Apple platforms)
- [ ] Accelerate backend implemented (BLAS/LAPACK on Apple platforms)
- [ ] Automatic backend selection based on problem size
- [ ] Performance benchmarks showing speedup metrics
- [ ] Results validated across all backends (numerical tolerance)
- [ ] Documentation explains when GPU is used
- [ ] GPU buffers reused where possible (avoid per-iteration allocation)
- [ ] Autoreleasepool around batch GPU operations

For every class (reference type):
- [ ] `deinit` implemented if holding resources (Metal buffers, locks, tasks)
- [ ] Delegate/parent references are `weak`
- [ ] Closure properties capture `[weak self]` or `[unowned self]`
- [ ] No circular strong reference chains
- [ ] Thread safety documented

For every async/streaming feature:
- [ ] Long-running Task handles stored for cancellation
- [ ] `Task.isCancelled` checked in iteration loops
- [ ] Continuations properly managed (not resumed after cancellation)
- [ ] `deinit` cancels owned background tasks
- [ ] Streaming APIs use bounded buffers, not unbounded arrays

---

## Related Documents

- [Master Plan](00_MASTER_PLAN.md)
- [Usage Examples](02_USAGE_EXAMPLES.md)
- [DocC Guidelines](03_DOCC_GUIDELINES.md)
- [Implementation Checklist](../04_IMPLEMENTATION_CHECKLISTS/TEMPLATE.md)

### Audit Reports

These reports detail specific issues found in the codebase and should be consulted when working in affected areas:

- [Security Audit](../05_SUMMARIES/securityAudit.md) - Force unwraps, division by zero, overflow, randomness issues
- [Memory Audit](../05_SUMMARIES/memoryAudit.md) - Unbounded collections, GPU resources, async tasks, caches
