# Application Testing Patterns
### Beyond Unit Tests: Integration, E2E, Benchmarks, and Metrics

---

## Purpose

[09_TEST_DRIVEN_DEVELOPMENT.md](09_TEST_DRIVEN_DEVELOPMENT.md) defines the unit-level TDD contract. This document extends that foundation with **application-level testing patterns** — integration tests, end-to-end workflows, plugin pipelines, performance benchmarks, and coverage targets.

All examples use **Swift Testing** (`import Testing`). Never use XCTest.

---

## Testing Pyramid

Allocate test effort deliberately:

```
           /\
          /  \  Manual/Exploratory (5%)
         /----\
        /      \  E2E Tests (15%)
       /--------\
      /          \  Integration Tests (30%)
     /------------\
    /              \  Unit Tests (50%)
   /________________\
```

| Layer | Share | Purpose |
|-------|-------|---------|
| **Unit** | 50% | Pure functions, deterministic calculations |
| **Integration** | 30% | Multi-component interactions, pipelines |
| **E2E** | 15% | Full user workflows, UI through backend |
| **Manual** | 5% | Exploratory testing, edge case hunting |

---

## Plugin & Pipeline Testing

When testing modular architectures with plugin protocols, verify each stage of the pipeline independently and together.

```swift
import Testing

@Suite struct DataPluginTests {
    let plugin = SamplePlugin()

    @Test func recognizesCompatibleSource() {
        let source = DataSource.file(sampleFile, format: "csv")
        #expect(plugin.canHandle(source))
    }

    @Test func rejectsIncompatibleSource() {
        let source = DataSource.file(genericFile, format: "csv")
        #expect(!plugin.canHandle(source))
    }

    @Test func ingestionProducesValidOutput() async throws {
        let source = DataSource.file(sampleFile, format: "csv")
        let raw = try await plugin.ingest(from: source)

        #expect(raw.records.count > 0)
        #expect(raw.metadata.system == "ExpectedSystem")
    }

    @Test func normalizationAccuracy() async throws {
        let raw = try await plugin.ingest(from: knownSource)
        let result = try await plugin.normalize(raw, rules: nil)

        let accuracy = Double(result.mappedCount) / Double(raw.totalCount)
        #expect(accuracy > 0.85, "Mapping accuracy below 85%: \(accuracy)")
    }
}
```

---

## E2E Test Patterns

End-to-end tests exercise a full user workflow. Keep them focused on the critical path.

```swift
import Testing

@Suite struct WorkflowEndToEndTests {
    @Test func completeImportAndAnalysisFlow() async throws {
        // 1. Ingest
        let importResult = try await importService.import(file: sampleFile)
        #expect(importResult.success)

        // 2. Process
        let analysis = try await analysisService.analyze(importResult.dataId)
        #expect(analysis.metrics != nil)

        // 3. Export
        let export = try await exportService.export(analysis.id, format: .pdf)
        #expect(export.data.count > 0)
    }
}
```

**Guidelines:**

- Mark E2E suites `.serialized` to avoid resource contention
- Use `.timeLimit(.minutes(1))` to catch hangs
- Test the critical path first; add edge-case E2E tests only for high-risk flows

---

## Performance Benchmarking

Use `ContinuousClock` for all performance assertions. See [PERFORMANCE.md](PERFORMANCE.md) for full patterns.

```swift
@Suite("Benchmarks", .serialized)
struct Benchmarks {
    @Test func aggregationPerformance() {
        let data = generateLargeDataset(count: 10_000)

        let clock = ContinuousClock()
        let elapsed = clock.measure {
            _ = data.aggregate()
        }

        #expect(elapsed < .milliseconds(100))
    }

    @Test func asyncProcessingPerformance() async throws {
        let clock = ContinuousClock()
        let elapsed = try await clock.measure {
            try await engine.process(iterations: 10_000)
        }

        #expect(elapsed < .seconds(30))
    }
}
```

---

## Manual Testing Checklists

Maintain exploratory testing checklists alongside automated tests. Review before each release or design partner demo.

**Template:**

```markdown
### Pre-Release Manual Testing

- [ ] Import real data from each supported source
- [ ] Verify output accuracy against manual/reference model (within tolerance)
- [ ] Test with malformed input files
- [ ] Test with edge-case values (empty, very large, negative where unexpected)
- [ ] Test on target platforms and browsers
- [ ] Test under slow network conditions
```

Store checklists in `04_IMPLEMENTATION_CHECKLISTS/` or alongside the feature's roadmap documentation.

---

## Test Metrics & Coverage Targets

Set coverage targets by module type:

| Module Type | Unit Coverage | Integration Coverage |
|-------------|--------------|---------------------|
| Core library / math | 95%+ | 90%+ |
| Application core | 85%+ | 80%+ |
| Plugins / adapters | 90%+ | 85%+ |
| UI layer | 70%+ | N/A |

**Track weekly:**

- Test pass rate (target: 100%)
- Coverage trend over time
- Failing test count (target: 0)
- Test execution time (flag slowdowns > 20%)
- Flaky test detection (rerun 3x, flag inconsistent results)

---

## Related Documents

- [Test-Driven Development](09_TEST_DRIVEN_DEVELOPMENT.md) — unit-level TDD contract
- [Testing Guide](TESTING.md) — test execution, parallelism, CI/CD
- [Performance Guidelines](PERFORMANCE.md) — ContinuousClock patterns, profiling tools
- [Release Checklist](RELEASE_CHECKLIST.md) — pre-release verification gates

---
