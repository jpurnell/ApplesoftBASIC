# Performance Guidelines

**Purpose:** Standards and patterns for writing performant Swift code.

---

## Core Principles

### 1. Measure First, Optimize Later

Never optimize without profiling:

```bash
# Run with Instruments
xcrun xctrace record --template "Time Profiler" --launch -- .build/release/YourApp

# Quick benchmark
swift build -c release
time .build/release/YourBenchmark
```

### 2. Algorithmic Complexity Matters Most

Focus on Big-O before micro-optimizations:

| Complexity | Name | Example |
|------------|------|---------|
| O(1) | Constant | Dictionary lookup |
| O(log n) | Logarithmic | Binary search |
| O(n) | Linear | Single array pass |
| O(n log n) | Linearithmic | Sorting |
| O(n²) | Quadratic | Nested loops |
| O(2ⁿ) | Exponential | Brute force combinations |

---

## Common Performance Pitfalls

### 1. Repeated Expensive Calculations

```swift
// ❌ O(n²) - mean() recalculated for every element
let result = values.map { $0 - mean(values) }

// ✅ O(n) - calculate once, reuse
let meanValue = mean(values)
let result = values.map { $0 - meanValue }
```

### 2. Unnecessary Memory Allocations

```swift
// ❌ Creates intermediate arrays
let result = array.filter { $0 > 0 }.map { $0 * 2 }.reduce(0, +)

// ✅ Single pass with lazy evaluation
let result = array.lazy.filter { $0 > 0 }.map { $0 * 2 }.reduce(0, +)
```

### 3. Value Type Copying

```swift
// ❌ Large struct copied on every access
struct LargeData {
    var matrix: [[Double]]  // Could be 1000x1000
}
func process(_ data: LargeData) { ... }  // Copies entire matrix

// ✅ Use inout or reference type for large data
func process(_ data: inout LargeData) { ... }  // No copy

// ✅ Or use class for large shared data
final class LargeData {
    var matrix: [[Double]]
}
```

### 4. Computed Property Recalculation

```swift
// ❌ Expensive computation on every access
var covarianceMatrix: [[Double]] {
    // Expensive calculation every time
    calculateCovarianceMatrix()
}

// ✅ Calculate once, cache the result
private let _covarianceMatrix: [[Double]]

init(...) {
    self._covarianceMatrix = calculateCovarianceMatrix()
}

var covarianceMatrix: [[Double]] { _covarianceMatrix }
```

### 5. String Concatenation in Loops

```swift
// ❌ O(n²) due to repeated string allocations
var result = ""
for item in items {
    result += item.description
}

// ✅ O(n) with array join
let result = items.map(\.description).joined()
```

---

## Swift-Specific Optimizations

### Use Release Builds for Benchmarks

```bash
# Debug builds have disabled optimizations
swift build -c debug   # ❌ Don't benchmark this

# Release builds enable full optimization
swift build -c release # ✅ Use for performance testing
```

### Leverage Copy-on-Write

Swift's standard types (Array, Dictionary, String) use copy-on-write:

```swift
var array1 = [1, 2, 3, 4, 5]
var array2 = array1  // No copy yet! Just shares storage

array2.append(6)     // NOW a copy happens (on mutation)
```

### Use ContiguousArray for Performance-Critical Code

```swift
// Standard Array (can hold class references, AnyObject)
var array: [Int] = []

// ContiguousArray (guaranteed contiguous storage, faster iteration)
var fastArray: ContiguousArray<Int> = []
```

### Avoid Bridging Overhead

```swift
// ❌ Implicit bridging to NSArray
let array: [Int] = [1, 2, 3]
someObjCFunction(array)  // Bridged to NSArray

// ✅ Use native Swift throughout
let array: [Int] = [1, 2, 3]
swiftFunction(array)  // No bridging
```

---

## Concurrency Performance

### Actor Isolation Overhead

```swift
// ❌ Frequent cross-actor calls
for item in items {
    await actor.process(item)  // Context switch each time
}

// ✅ Batch operations
await actor.processAll(items)  // Single context switch
```

### Task Priority

```swift
// Use appropriate priority
Task(priority: .background) {
    // Long-running, non-urgent work
}

Task(priority: .userInitiated) {
    // Respond to user action quickly
}
```

---

## Memory Performance

### Avoid Retain Cycles

```swift
// ❌ Retain cycle - closure captures self strongly
class MyClass {
    var closure: (() -> Void)?

    func setup() {
        closure = { self.doWork() }  // Strong reference cycle
    }
}

// ✅ Use weak or unowned
func setup() {
    closure = { [weak self] in self?.doWork() }
}
```

### Pre-allocate Collections

```swift
// ❌ Multiple reallocations as array grows
var results: [Double] = []
for i in 0..<10000 {
    results.append(compute(i))
}

// ✅ Reserve capacity upfront
var results: [Double] = []
results.reserveCapacity(10000)
for i in 0..<10000 {
    results.append(compute(i))
}
```

---

## Profiling Tools

### Instruments Templates

| Template | Use For |
|----------|---------|
| Time Profiler | CPU hotspots |
| Allocations | Memory usage |
| Leaks | Memory leaks |
| System Trace | Overall system performance |

### Quick Timing with ContinuousClock

```swift
let clock = ContinuousClock()
let elapsed = clock.measure {
    // ... operation to measure ...
    expensiveOperation()
}
print("Elapsed: \(elapsed)")
```

### Swift Testing Performance Measurement

Use `ContinuousClock` inside `@Test` functions to assert timing bounds:

```swift
@Test func operationCompletes() {
    let clock = ContinuousClock()
    let elapsed = clock.measure {
        expensiveOperation()
    }
    #expect(elapsed < .milliseconds(100))
}
```

For async operations:

```swift
@Test func asyncOperationCompletes() async throws {
    let clock = ContinuousClock()
    let elapsed = try await clock.measure {
        try await expensiveAsyncOperation()
    }
    #expect(elapsed < .seconds(5))
}
```

---

## Performance Checklist

When optimizing code:

- [ ] Profile first — identify actual bottlenecks
- [ ] Check algorithmic complexity (Big-O)
- [ ] Look for repeated expensive calculations
- [ ] Check for unnecessary allocations
- [ ] Verify using release build for benchmarks
- [ ] Consider lazy evaluation for transformations
- [ ] Cache expensive computed properties
- [ ] Pre-allocate collections when size is known
- [ ] Batch async operations to reduce context switches
- [ ] Check for retain cycles in closures

---

## Performance Testing Guidelines

### Write Deterministic Benchmarks

```swift
@Test("Performance: matrix multiplication")
func matrixMultiplicationPerformance() {
    // Fixed input for reproducibility
    let matrixA = Matrix(rows: 100, cols: 100, fill: 1.0)
    let matrixB = Matrix(rows: 100, cols: 100, fill: 2.0)

    // Warm-up run (not measured)
    _ = matrixA * matrixB

    // Measured runs
    let clock = ContinuousClock()
    let elapsed = clock.measure {
        for _ in 0..<100 {
            _ = matrixA * matrixB
        }
    }

    // Assert reasonable performance
    #expect(elapsed < .seconds(1), "Matrix multiplication too slow: \(elapsed)")
}
```

### Isolate Performance Tests

```swift
@Suite("Performance Benchmarks", .disabled("Run explicitly"))
struct PerformanceBenchmarks {
    // Performance tests that shouldn't run in CI by default
}
```

---

## Related Documents

- [Coding Rules](01_CODING_RULES.md)
- [Testing Guide](TESTING.md)
- [Test-Driven Development](09_TEST_DRIVEN_DEVELOPMENT.md)
