# Release Checklist

**Purpose:** Reproducible process for preparing and publishing a new release.
**Applies to:** Every tagged release (patch, minor, major).

---

## Quick Reference

| Stage | Command / Action | Output |
|-------|-----------------|--------|
| **All quality checks** | `quality-gate` | All checks PASSED |
| Dependency audit | `swift package show-dependencies` | Dependency tree |
| Count test cases | `swift test --list-tests \| wc -l` | Integer count |
| JSON output (CI) | `quality-gate --format json` | JSON report |
| GitHub SARIF | `quality-gate --format sarif > results.sarif` | SARIF file |

**Legend:**
- ⬜ Not Started
- 🔄 In Progress
- ✅ Complete
- ⚠️ Needs Attention
- 🔴 Blocking — do not release

**Release Type Guidelines:**
- **Patch (x.y.Z):** Phases 1, 4, 5 required
- **Minor (x.Y.0):** All phases required
- **Major (X.0.0):** All phases required; migration guide recommended

---

## Phase 1: Code Quality Gates

### 1.1 Run Quality Gate ✅ required

> **Setup & usage details:** See [Implementation Checklist](../04_IMPLEMENTATION_CHECKLISTS/TEMPLATE.md#quality-gate-setup) for installation, configuration, and manual fallback commands.

```bash
quality-gate
```

- [ ] All checks show **PASSED**
- [ ] No warnings or errors in any check

### 1.2 Verify Test Count

```bash
swift test --list-tests | wc -l
```

- [ ] Note the test count for README update
- [ ] No unexpected skips

### 1.3 Manual Verification

- [ ] All targets build (main library + macros if present)
- [ ] Every public API has a `///` doc comment

> **Rule:** No symbol ships undocumented.

---

### 1.4 Concurrency Verification

The `quality-gate` build check includes strict concurrency. Additionally verify:

- [ ] `@Sendable` conformances verified for types crossing isolation boundaries
- [ ] Actor isolation is correct for shared mutable state

---

### 1.5 Dependency Security Audit ✅ required

```bash
swift package show-dependencies --format json
swift package update --dry-run
```

- [ ] All dependencies resolve successfully
- [ ] No dependencies are yanked or deprecated
- [ ] Review dependency versions for known security vulnerabilities
- [ ] If using GitHub, review Dependabot alerts (if enabled)

---

## Phase 2: Platform Verification

### 2.1 macOS Build and Test ✅ required

```bash
swift build
swift test
swift build -c release
```

- [ ] Debug build succeeds
- [ ] Release build succeeds
- [ ] All tests pass

---

### 2.2 Linux Build and Test ✅ required for cross-platform libraries

```bash
# Using Docker (from macOS)
docker run --rm -v "$PWD":/workspace -w /workspace swift:6.0 swift build
docker run --rm -v "$PWD":/workspace -w /workspace swift:6.0 swift test
```

Or verify via CI:
- [ ] GitHub Actions Linux job passes
- [ ] Platform-specific code paths tested (`#if os(Linux)` branches)

---

### 2.3 Additional Platform Archives ⚠️ recommended for Apple platform libraries

```bash
# iOS
xcodebuild archive -scheme [SCHEME] -destination "generic/platform=iOS" SKIP_INSTALL=NO

# tvOS
xcodebuild archive -scheme [SCHEME] -destination "generic/platform=tvOS" SKIP_INSTALL=NO

# watchOS
xcodebuild archive -scheme [SCHEME] -destination "generic/platform=watchOS" SKIP_INSTALL=NO

# visionOS
xcodebuild archive -scheme [SCHEME] -destination "generic/platform=visionOS" SKIP_INSTALL=NO
```

- [ ] iOS archive builds successfully
- [ ] tvOS archive builds successfully
- [ ] watchOS archive builds successfully
- [ ] visionOS archive builds successfully (if supporting)

---

### 2.4 Performance Regression Testing ⚠️ required for major releases

```bash
swift test --filter "Performance"
```

- [ ] Benchmark suite executed (if available)
- [ ] No significant performance regressions (>10% slowdown)
- [ ] Memory usage within acceptable bounds

---

## Phase 3: Documentation Verification

### 3.1 DocC Documentation Build ✅ required

```bash
swift package generate-documentation --target [PROJECT_NAME]
```

- [ ] Documentation builds without errors
- [ ] Documentation builds without warnings
- [ ] All public API symbols appear in generated documentation
- [ ] Code examples in documentation compile correctly
- [ ] Navigation structure is correct

---

### 3.2 Example Code Verification ✅ required

- [ ] All Swift Playgrounds open without errors in Xcode
- [ ] Example code compiles
- [ ] README code snippets are accurate and would compile

---

## Phase 4: README Update

### 4.1 Update Metrics

- [ ] Test count updated
- [ ] Documentation coverage updated (if tracked)
- [ ] Version number updated in installation instructions

### 4.2 Manual Review

- [ ] Version headline updated if version changed
- [ ] New feature bullets added for significant features
- [ ] Installation version updated: `from: "X.Y.Z"`
- [ ] Release notes link correct
- [ ] Requirements section accurate

### 4.3 Content Guardrails

These items must **never appear** in README.md:

- [ ] No placeholder text (`TODO`, `TBD`, `FIXME`)
- [ ] No broken relative links
- [ ] No internal references (instruction set paths, session notes)

---

## Phase 5: Git Operations

### 5.1 Final Checks Before Commit

- [ ] `swift test` passes
- [ ] `swift build` is clean with **zero warnings**
- [ ] `docc-lint` reports **zero issues**
- [ ] `git diff` reviewed — only expected changes

---

### 5.2 Package.resolved Verification ✅ required

```bash
swift package resolve
git diff Package.resolved
```

- [ ] `Package.resolved` is up to date
- [ ] No unexpected dependency version changes

---

### 5.3 Changelog Review ✅ required

- [ ] `CHANGELOG.md` has entry for this version
- [ ] Entry includes date in consistent format: `## [X.Y.Z] - YYYY-MM-DD`
- [ ] All significant changes documented:
  - [ ] Added (new features)
  - [ ] Changed (changes to existing functionality)
  - [ ] Deprecated (features to be removed)
  - [ ] Removed (removed features)
  - [ ] Fixed (bug fixes)
  - [ ] Security (security fixes)

> **Format:** Follow [Keep a Changelog](https://keepachangelog.com/) conventions.

---

### 5.4 Release Commit

```bash
git add .
git commit -m "Release vX.Y.Z: <one-line summary>"
```

- [ ] Commit message follows convention: `Release vX.Y.Z: ...`
- [ ] All modified files staged
- [ ] Commit succeeded

---

### 5.5 Version Tag

```bash
git tag -a vX.Y.Z -m "Version X.Y.Z"
git push origin main
git push origin vX.Y.Z
```

- [ ] Tag created with correct version number
- [ ] Main branch pushed
- [ ] Tag pushed to remote

---

## Phase 6: Post-Release Verification

- [ ] CI build passes on tagged commit
- [ ] Documentation builds cleanly
- [ ] README renders correctly on GitHub
- [ ] Package resolves correctly when added to a new project:
  ```swift
  .package(url: "https://github.com/[USER]/[PROJECT]", from: "X.Y.Z")
  ```

---

## Completion Criteria

A release is ready when **all of the following are true**:

### Code Quality
- [ ] `swift build` → zero errors, zero warnings
- [ ] `swift test` → all pass, zero failures
- [ ] `swift build -Xswiftc -strict-concurrency=complete` → zero errors
- [ ] `docc-lint` → zero issues
- [ ] Documentation coverage = 100%

### Documentation
- [ ] DocC documentation builds without errors
- [ ] Example code verified
- [ ] README updated with correct version and metrics

### Git
- [ ] CHANGELOG.md updated
- [ ] Package.resolved current
- [ ] Release commit created
- [ ] Git tag created and pushed

### Cross-Platform (if applicable)
- [ ] macOS build and tests pass
- [ ] Linux build passes
- [ ] Platform archives build (iOS, tvOS, watchOS, visionOS)

### Major Release Additional Requirements (X.0.0)
- [ ] Performance regression testing completed
- [ ] Migration guide created (if breaking changes exist)

---

## Related Documents

- [Coding Rules](01_CODING_RULES.md)
- [DocC Guidelines](03_DOCC_GUIDELINES.md)
- [Test-Driven Development](09_TEST_DRIVEN_DEVELOPMENT.md)
- [Implementation Checklist](../04_IMPLEMENTATION_CHECKLISTS/TEMPLATE.md)
