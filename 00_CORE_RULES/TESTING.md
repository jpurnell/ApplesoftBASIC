# Testing Guide for [PROJECT_NAME]

## Quick Start

To run the test suite with optimal performance, use 80% of available CPU cores:

```bash
# macOS
swift test --parallel --num-workers $(( $(sysctl -n hw.ncpu) * 80 / 100 ))

# Linux
swift test --parallel --num-workers $(( $(nproc) * 80 / 100 ))
```

## Performance Optimizations

### 1. Controlled Parallelism (80% of cores)
- **Why**: Limits parallel test execution to ~80% of available cores
- **Benefit**: Avoids context switching overhead and resource contention
- **Result**: Typically ~20% faster than unlimited parallel or serial execution

### 2. Serialized CPU-Intensive Suites

Mark CPU-intensive test suites as `.serialized` to prevent resource contention. Common candidates:
- Performance benchmark suites
- Monte Carlo simulation tests
- Optimization algorithm tests
- Matrix computation tests

These suites run one at a time to ensure accurate performance measurements and prevent CPU thrashing.

## Running Tests

### Full Test Suite (Optimized)
```bash
# Auto-detect optimal worker count
swift test --parallel --num-workers $(( $(sysctl -n hw.ncpu) * 80 / 100 ))
```

### Single Test
```bash
swift test --filter "testName"
```

### Specific Suite
```bash
swift test --filter "SuiteName"
```

### Debug Mode (Serial)
For debugging test failures, run serially:
```bash
swift test
```

## CI/CD Configuration

For continuous integration, use the optimized configuration:

```yaml
# GitHub Actions example
- name: Run Tests
  run: |
    WORKERS=$(( $(nproc) * 80 / 100 ))
    swift test --parallel --num-workers $WORKERS
```

## Troubleshooting

### Tests Running Slowly
- Ensure you're using `--parallel` with an appropriate `--num-workers` count
- Check CPU usage with `top` or Activity Monitor
- Verify no other CPU-intensive processes are running

### Random Test Failures
- Some failures may be due to resource contention
- Run the failing test individually: `swift test --filter "testName"`
- Check if the test is marked as CPU-intensive and should be `.serialized`

### Memory Issues
- Reduce `--num-workers` (try 50% of cores instead of 80%)
- Run tests serially: `swift test` (no --parallel flag)

## System Requirements

- **Recommended**: 8+ CPU cores
- **Minimum**: 4 CPU cores (use `--num-workers 3`)
- **Memory**: 8GB+ RAM

## Adding New Tests

When adding new performance-sensitive or CPU-intensive tests:

1. Mark the suite as serialized:
   ```swift
   @Suite("My Performance Tests", .serialized)
   struct MyPerformanceTests {
       // ...
   }
   ```

2. This prevents the suite from running in parallel with other tests
3. Use this for:
   - Optimization algorithm tests
   - Monte Carlo simulations
   - Matrix computations
   - Performance benchmarks
