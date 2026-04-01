# [PROJECT_NAME] Master Plan

**Purpose:** Source of truth for project vision, architecture, and goals.

---

## Project Overview

### Mission
[Describe the core mission of this project - what problem does it solve?]

### Target Users
- [User type 1]
- [User type 2]
- [User type 3]

### Key Differentiators
- [What makes this project unique?]
- [Why would someone choose this over alternatives?]

---

## Architecture

### Technology Stack
- **Language:** [Swift 6.0 / Python / etc.]
- **Frameworks:** [List key frameworks]
- **Build System:** [SPM / CocoaPods / etc.]
- **Testing:** [Swift Testing / XCTest / etc.]

### Module Structure

```
[PROJECT_NAME]/
├── Sources/
│   └── [PROJECT_NAME]/
│       ├── [Module1]/
│       ├── [Module2]/
│       └── [PROJECT_NAME].docc/
├── Tests/
│   └── [PROJECT_NAME]Tests/
└── Package.swift
```

### Key Types

| Type | Purpose |
|------|---------|
| `[Type1]` | [Description] |
| `[Type2]` | [Description] |
| `[Type3]` | [Description] |

---

## Current Status

### What's Working
- [x] [Feature 1]
- [x] [Feature 2]
- [ ] [Feature 3 - in progress]

### Known Issues
- [Issue 1]
- [Issue 2]

### Current Priorities
1. [Priority 1]
2. [Priority 2]
3. [Priority 3]

---

## Quality Standards

### Code Quality
- All code follows `01_CODING_RULES.md`
- Test coverage target: [80%+]
- Documentation for all public APIs
- No warnings in build output

### Documentation Quality
- DocC comments for all public functions
- Usage examples in documentation
- Articles for complex topics

---

## Error Registry

> **Purpose:** Single source of truth for all error types in the project. Consult this
> registry during the Design Proposal Phase to ensure new error cases don't duplicate
> existing ones. Update it whenever new error types are introduced.

### Error Types

| Error Enum | Case | When Thrown | Module |
|------------|------|------------|--------|
| `ProjectError` | `.emptyInput` | Collection is empty when non-empty is required | [Module] |
| `ProjectError` | `.invalidInput(message:)` | Parameter fails validation | [Module] |
| `ProjectError` | `.divisionByZero(context:)` | Denominator is zero or near-zero | [Module] |

*Add new error cases here as they are introduced. Remove this example content and replace with your project's actual errors.*

### Error Design Principles

- **One error enum per domain boundary** — avoid proliferating error types
- **Descriptive associated values** — include context (parameter name, expected range, etc.)
- **No overlapping cases** — `invalidParameter` and `outOfRange` should not coexist if they mean the same thing
- **Consult this registry** before creating new error cases in a Design Proposal

---

## Roadmap

### Phase 1: [Name]
- [ ] [Goal 1]
- [ ] [Goal 2]

### Phase 2: [Name]
- [ ] [Goal 1]
- [ ] [Goal 2]

### Future Considerations
- [Potential future direction 1]
- [Potential future direction 2]

---

**Last Updated:** [Date]
