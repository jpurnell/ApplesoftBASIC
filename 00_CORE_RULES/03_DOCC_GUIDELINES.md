# DocC Documentation Guidelines for [PROJECT_NAME]

**Purpose:** Comprehensive guide to creating excellent DocC documentation
**Reference:** [Apple DocC Documentation](https://www.swift.org/documentation/docc/)

---

## Table of Contents

1. [DocC Basics](#1-docc-basics)
2. [Documentation Structure](#2-documentation-structure)
3. [Markdown Formatting](#3-markdown-formatting)
4. [Code Examples](#4-code-examples)
5. [Topics Organization](#5-topics-organization)
6. [Building Documentation](#6-building-documentation)
7. [Documentation Catalog](#7-documentation-catalog)

---

## 1. DocC Basics

### What is DocC?

DocC is Apple's documentation compiler that creates rich, interactive documentation from:
- Source code comments (triple-slash `///`)
- Standalone markdown files (articles, tutorials)
- Documentation catalogs (`.docc` bundles)

### Key Benefits
- **Interactive**: Live code examples in Xcode
- **Type-safe**: Links to symbols are validated at compile time
- **Cross-platform**: Web export for broader distribution
- **Integrated**: Built into Swift Package Manager and Xcode

---

## 2. Documentation Structure

### Source Code Comments

Every public API should have documentation:

```swift
/// Brief one-line summary describing what this does.
///
/// A more detailed explanation of the function, including:
/// - What problem it solves
/// - How it works (if non-obvious)
/// - When to use it
/// - Important caveats or considerations
///
/// - Parameters:
///   - inputValue: The primary input for the calculation.
///     Should be expressed as a decimal (e.g., 0.10 for 10%).
///   - items: Array of values by period. First element is
///     typically the initial value (negative for costs).
///
/// - Returns: The computed result. A positive value indicates
///   the operation adds value.
///
/// - Throws: `CalculationError.emptyInput` if the items array is empty.
///
/// - Complexity: O(n) where n is the number of items.
///
/// - Note: The first item occurs at time 0 (present).
///   Subsequent items occur at the end of each period.
///
/// ## Domain Equivalent
/// Equivalent to a well-known domain formula or tool function.
///
/// ## Usage Example
/// ```swift
/// let items = [-100000.0, 30000.0, 30000.0, 30000.0, 30000.0]
/// let result = calculate(inputValue: 0.10, items: items)
/// print("Result: \(result)")
/// // Output: Result: -4641.92
/// ```
///
/// ## Mathematical Formula
/// The result is calculated as:
/// ```
/// Result = Σ (Vₜ / (1 + r)ᵗ)
/// ```
/// where:
/// - Vₜ = value at time t
/// - r = input rate
/// - t = time period
///
/// - SeeAlso:
///   - ``relatedFunctionA(items:guess:)``
///   - ``relatedFunctionB(items:rateA:rateB:)``
///   - ``relatedFunctionC(rate:dates:items:)``
public func calculate<T: Real>(inputValue r: T, items c: [T]) -> T {
    // Implementation
}
```

### Documentation Sections

#### Required for All Public APIs
- **Summary**: First line, one sentence
- **Parameters**: All parameters documented
- **Returns**: What the function returns

#### Optional but Recommended
- **Throws**: Errors that can be thrown
- **Complexity**: Time/space complexity if non-trivial
- **Note**: Additional information
- **Important**: Critical information users must know
- **Warning**: Potential pitfalls
- **Tip**: Helpful suggestions

#### Enhanced Documentation
- **Domain Equivalent**: For functions with well-known domain counterparts
- **Usage Example**: Real-world code examples
- **Mathematical Formula**: For mathematical functions
- **SeeAlso**: Related functions

---

## 3. Markdown Formatting

### Headings

Use `##` for major sections, `###` for subsections.

**Always leave a blank line after headings** — DocC parsing is whitespace-sensitive:

```swift
// ❌ Wrong - no blank line
/// ### Section
/// Text immediately after

// ✅ Correct - blank line after heading
/// ### Section
///
/// Text after blank line
```

Example structure:

```swift
/// Brief summary.
///
/// Detailed explanation.
///
/// ## Mathematical Background
///
/// The formula is based on...
///
/// ## Usage Patterns
///
/// ### Simple Cases
/// For basic usage...
///
/// ### Advanced Cases
/// For complex scenarios...
```

### Lists

Unordered lists:
```swift
/// This function handles:
/// - Core calculations
/// - Derived calculations
/// - Aggregate valuations
```

Ordered lists:
```swift
/// Follow these steps:
/// 1. Create a period range
/// 2. Populate with values
/// 3. Apply transformations
```

#### ⚠️ Bullet Formatting in Articles (Outside `## Topics`)

In standalone `.md` articles, `-` bullets directly under a heading can trigger DocC's
task-group parser, producing "Only links are allowed in task group list items" warnings.

**Inside `## Topics`**: Use `-` bullets (required for symbol/article links)

**Outside `## Topics`**: Prefer alternative formatting to avoid accidental task-group parsing:

```markdown
❌ Risky in articles (can trigger task-group parsing):
### Features
- Feature one
- Feature two

✅ Safe alternatives:

Option 1 — Unicode bullets:
• Feature one
• Feature two

Option 2 — Bold labels with em-dash:
**Feature One** — Explanation of feature one.
**Feature Two** — Explanation of feature two.

Option 3 — Plain prose with line breaks:
Feature One — Explanation of feature one.
Feature Two — Explanation of feature two.

Option 4 — Just use paragraphs:
The first feature does X. The second feature does Y.
```

**Note**: This warning applies to standalone article files. In source code doc comments
(`///`), standard `-` bullets are generally safe because they're not parsed as task groups.

### Emphasis

```swift
/// Use *italics* for emphasis and **bold** for strong emphasis.
/// Use `monospace` for code, parameter names, or literal values.
```

### Links

#### Symbol Links
```swift
/// Uses ``DataStore`` to store values.
/// See ``Model/create(name:type:)`` for creating models.
/// Related to ``calculate(inputValue:items:)`` computation.
```

#### Article Links
```swift
/// See <doc:GettingStarted> for an introduction.
/// For details, see <doc:CoreConcepts>.
```

#### External Links
```swift
/// For more information, see [Swift Numerics](https://github.com/apple/swift-numerics).
```

### Code Blocks

Inline code:
```swift
/// The `inputValue` parameter should be between 0 and 1.
```

Code blocks:
```swift
/// Example usage:
/// ```swift
/// let result = calculate(inputValue: 0.10, items: items)
/// ```
```

### Callouts

```swift
/// - Note: This is general information.
/// - Important: This is critical information.
/// - Warning: This warns about potential issues.
/// - Tip: This is a helpful suggestion.
/// - Experiment: Try modifying this example.
```

---

## 4. Code Examples

### Inline Examples

Short, focused examples within documentation:

```swift
/// Calculate the mean of an array.
///
/// ```swift
/// let values = [1.0, 2.0, 3.0, 4.0, 5.0]
/// let average = mean(values)  // 3.0
/// ```
public func mean<T: Real>(_ x: [T]) -> T {
    // Implementation
}
```

### Extended Examples

For complex workflows, use a dedicated section:

```swift
/// ## Extended Example
///
/// Here's a complete multi-step calculation scenario:
///
/// ```swift
/// // Input parameters
/// let initialValue: Double = 250000
/// let annualRate: Double = 0.045
/// let periods = 30
///
/// // Calculate periodic result
/// let periodicRate = annualRate / 12
/// let totalPeriods = periods * 12
/// let periodicResult = computePeriodicValue(
///     baseValue: initialValue,
///     rate: periodicRate,
///     periods: totalPeriods
/// )
///
/// // Generate schedule
/// for period in 1...12 {
///     let componentA = computeComponentA(
///         rate: periodicRate,
///         period: period,
///         totalPeriods: totalPeriods,
///         baseValue: initialValue
///     )
///     let componentB = computeComponentB(
///         rate: periodicRate,
///         period: period,
///         totalPeriods: totalPeriods,
///         baseValue: initialValue
///     )
///     print("Period \(period): Total \(periodicResult), A: \(componentA), B: \(componentB)")
/// }
/// ```
```

### Multiple Scenarios

```swift
/// ## Usage Examples
///
/// ### Basic Calculation
/// ```swift
/// let result = computeValue(input: 1000, rate: 0.05, periods: 10)
/// // Result: 613.91
/// ```
///
/// ### Variant A
/// ```swift
/// let resultA = computeAggregate(
///     perPeriodValue: 100,
///     rate: 0.05,
///     periods: 10,
///     type: .standard
/// )
/// // Result: 772.17
/// ```
///
/// ### Variant B
/// ```swift
/// let resultB = computeAggregate(
///     perPeriodValue: 100,
///     rate: 0.05,
///     periods: 10,
///     type: .modified
/// )
/// // Result: 810.78
/// ```
```

### ⚠️ Mandatory Example Requirements

**Every code example in documentation MUST be playground-executable.** Users should be able to copy any example directly into an Xcode Playground and run it without modification.

#### Rule 1: Self-Contained Examples

Each example must include everything needed to run:

```swift
// ❌ Wrong - depends on undefined variables
/// ```swift
/// let result = calculate(inputValue: rate, items: values)
/// ```

// ✅ Correct - fully self-contained
/// ```swift
/// import [PROJECT_NAME]
///
/// let inputValue = 0.10
/// let items = [-100000.0, 30000.0, 30000.0, 30000.0, 30000.0]
/// let result = calculate(inputValue: inputValue, items: items)
/// print("Result: \(result)")  // Result: -4641.92
/// ```
```

#### Rule 2: No Naming Collisions Between Examples

When multiple examples appear in the same documentation, use unique variable names to prevent redeclaration errors if a user runs them sequentially:

```swift
// ❌ Wrong - both examples use `result`, causes redeclaration error
/// ### Example 1
/// ```swift
/// let result = computeValue(input: 1000, rate: 0.05, periods: 10)
/// ```
///
/// ### Example 2
/// ```swift
/// let result = deriveValue(baseValue: 500, rate: 0.08, periods: 5)
/// ```

// ✅ Correct - unique names for each example
/// ### Example 1: Forward Calculation
/// ```swift
/// let forwardResult = computeValue(input: 1000, rate: 0.05, periods: 10)
/// print("Forward: \(forwardResult)")  // Forward: 613.91
/// ```
///
/// ### Example 2: Reverse Calculation
/// ```swift
/// let reverseResult = deriveValue(baseValue: 500, rate: 0.08, periods: 5)
/// print("Reverse: \(reverseResult)")  // Reverse: 734.66
/// ```
```

#### Rule 3: Explicit Seeds for Stochastic Examples

Any example involving random number generation MUST specify the seed used, so users can reproduce the exact output values shown:

```swift
// ❌ Wrong - non-reproducible output
/// ```swift
/// let sample = normalDistribution(mean: 100, stdDev: 15)
/// print(sample)  // Output: 97.3 (varies each run)
/// ```

// ✅ Correct - seed specified, output is reproducible
/// ```swift
/// // Using seed 42 for reproducibility
/// var rng = DeterministicRNG(seed: 42)
/// let sample = normalDistribution(mean: 100, stdDev: 15, using: &rng)
/// print(sample)  // Output: 97.3 (always this value with seed 42)
/// ```

// ✅ Also correct - seed as parameter with documented output
/// ```swift
/// // Seed: 12345 produces these exact values
/// let samples = monteCarloSimulation(
///     iterations: 5,
///     seed: 12345
/// )
/// print(samples)  // [0.234, 0.891, 0.156, 0.672, 0.445]
/// ```
```

#### Rule 4: Show Expected Output

Always include the expected output as a comment so users can verify their results:

```swift
// ❌ Wrong - no way to verify correctness
/// ```swift
/// let rate = try solveRate(items: [-1000, 300, 300, 300, 300, 300])
/// ```

// ✅ Correct - expected output shown
/// ```swift
/// let items = [-1000.0, 300.0, 300.0, 300.0, 300.0, 300.0]
/// let rateValue = try solveRate(items: items)
/// print("Rate: \(rateValue.percent(2))")  // Rate: 15.24%
/// ```
```

#### Example Validation Checklist

Before finalizing any documentation example:

- [ ] Runs in a fresh Xcode Playground without errors
- [ ] Includes all necessary imports (e.g., `import [PROJECT_NAME]`)
- [ ] All variables are defined within the example
- [ ] No naming collisions with other examples in the same doc
- [ ] Stochastic examples specify seeds for reproducibility
- [ ] Expected output shown as comments
- [ ] No pseudocode, ellipses (`...`), or placeholders

---

## 5. Topics Organization

### Automatic Topics

DocC automatically organizes symbols, but you can customize:

```swift
/// A model representing a discrete time interval.
///
/// ## Topics
///
/// ### Creating Intervals
/// - ``month(year:month:)``
/// - ``quarter(year:quarter:)``
/// - ``year(_:)``
/// - ``day(_:)``
///
/// ### Interval Properties
/// - ``type``
/// - ``date``
/// - ``startDate``
/// - ``endDate``
/// - ``label``
///
/// ### Interval Arithmetic
/// - ``+(_:_:)``
/// - ``-(_:_:)``
/// - ``distance(to:)``
///
/// ### Interval Ranges
/// - ``months()``
/// - ``quarters()``
/// - ``days()``
public struct Interval {
    // Implementation
}
```

### Custom Topics in Articles

Create custom groupings in `.docc` articles:

```markdown
# Core Calculations

## Overview

Compute forward values, reverse values, and solve for unknown rates.

## Topics

### Forward Calculations
- ``computeValue(input:rate:periods:)``
- ``computeAggregate(perPeriodValue:rate:periods:type:)``

### Reverse Calculations
- ``deriveValue(baseValue:rate:periods:)``
- ``deriveAggregate(perPeriodValue:rate:periods:)``

### Rate Solving
- ``solveRate(items:guess:)``
- ``solveModifiedRate(items:rateA:rateB:)``
- ``solveRateIrregular(dates:items:)``

### Aggregate Calculations
- ``calculate(inputValue:items:)``
- ``calculateIrregular(rate:dates:items:)``
```

### Task Group Restrictions

Inside a `## Topics` section, DocC enforces strict formatting rules. Task groups
may only contain `###` headings (the task group name) and bare link list items.
Violating these rules produces build warnings.

**Allowed heading level:** Only `###` creates a task group. Using `####` or deeper
headings inside `## Topics` causes DocC to treat them as plain text, triggering
"Only links are allowed in task group list items" warnings.

**No descriptive text:** Paragraphs, bold-text sub-headers, or any other prose
between the `###` heading and the link list items will produce "Extraneous content
found after a link in task group list item" warnings.

**Correct:**
```markdown
## Topics

### Forward Calculations
- ``computeValue(input:rate:periods:)``
- ``computeAggregate(perPeriodValue:rate:periods:type:)``

### Reverse Calculations
- ``deriveValue(baseValue:rate:periods:)``
```

**Incorrect** (descriptive text and `####` sub-headings):
```markdown
## Topics

### Analysis

Overview of analysis techniques.

#### Primary Analysis

Model A, Model B, and Model C approaches.

- ``analyzeWithModelA(items:rate:)``

**Secondary Analysis** - Extended calculations.

- ``analyzeWithModelB(paramA:paramB:paramC:)``
```

If you need to convey grouping hierarchy or descriptions, encode the context in
the `###` heading name itself (e.g., `### Analysis: Primary Models`) and keep
all descriptive prose in the `## Overview` section above `## Topics`.

### Topics vs See Also: When to Use Each

DocC documentation falls into two categories with different ending conventions:

| Document Type | Where | Ending Sections |
|---------------|-------|-----------------|
| **API Documentation** | Symbol docs, extension files | `## Topics` with `###` groups |
| **Narrative Articles** | Tutorials, guides, walkthroughs | `## Next Steps` + `## See Also` |

**API Documentation (symbols, types, modules):**

Use `## Topics` to organize related symbols into task groups:

```markdown
## Topics

### Creating Intervals
- ``month(year:month:)``
- ``quarter(year:quarter:)``

### Interval Arithmetic
- ``+(_:_:)``
- ``distance(to:)``
```

**Narrative Articles (tutorials, guides):**

Use `## Next Steps` for article cross-references and `## See Also` for API symbols:

```markdown
## Next Steps

- Explore <doc:AdvancedFeaturesGuide> for extended capabilities
- Learn about <doc:DataModelingGuide> for complete data modeling

## See Also

- ``Configuration``
- ``DataModel``
- ``Template``
```

**Why the distinction?** `## Topics` triggers DocC's task-group parser, which expects
only symbol/article links with `###` group headings. Narrative articles need prose
descriptions alongside links, which `## Next Steps` allows. Using `## Topics` in a
narrative article forces it to render as an "API Collection" rather than a readable guide.

---

## 6. Building Documentation

### Using Swift Package Manager

```bash
# Build documentation
swift package generate-documentation

# Preview documentation locally
swift package --disable-sandbox preview-documentation --target [PROJECT_NAME]

# Build for web hosting
swift package generate-documentation --target [PROJECT_NAME] \
    --output-path ./docs \
    --hosting-base-path [project-name]
```

### Using Xcode

1. **Product → Build Documentation** (⌃⌘⇧D)
2. Documentation appears in Xcode's Developer Documentation window
3. Export for hosting: **Product → Archive → Distribute → Copy App → Documentation**

### Continuous Integration

Add to your CI workflow:

```yaml
- name: Build Documentation
  run: |
    swift package generate-documentation --target [PROJECT_NAME]
```

---

## 7. Documentation Catalog

### Creating a .docc Catalog

Structure:
```
Sources/[PROJECT_NAME]/[PROJECT_NAME].docc/
├── [PROJECT_NAME].md              # Landing page
├── GettingStarted.md              # Tutorial
├── CoreConcepts.md                # Concept article
├── Resources/                     # Images, videos
│   ├── hero-image.png
│   └── diagram.svg
└── Extensions/                    # Extensions to organize docs
    ├── DataStore.md
    └── Interval.md
```

### Landing Page

`[PROJECT_NAME].md`:
```markdown
# ``[PROJECT_NAME]``

A comprehensive Swift library for [brief project description].

## Overview

[PROJECT_NAME] provides tools for:
- [Core capability 1]
- [Core capability 2]
- [Core capability 3]
- [Core capability 4]

Whether you're building [use case A], [use case B],
or [use case C], [PROJECT_NAME] offers a robust,
type-safe API built on Swift Numerics.

## Topics

### Essentials
- <doc:GettingStarted>
- <doc:CoreConcepts>

### Data Modeling
- ``Interval``
- ``DataStore``
- <doc:CoreConcepts>

### Analysis
- <doc:DescriptiveAnalysis>
- <doc:AdvancedAnalysis>

### Domain Functions
- <doc:CoreCalculations>
- <doc:DataModeling>

### Examples
- <doc:ExampleWorkflowA>
- <doc:ExampleWorkflowB>
- <doc:ExampleWorkflowC>
```

### Getting Started Tutorial

`GettingStarted.md`:
```markdown
# Getting Started with [PROJECT_NAME]

Learn the basics of using [PROJECT_NAME] for [primary use case].

## Overview

This tutorial covers:
- Installing [PROJECT_NAME]
- Creating models and data stores
- Basic calculations
- Building a simple workflow

### Add [PROJECT_NAME] to Your Project

Add the dependency to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/username/[PROJECT_NAME]", from: "2.0.0")
]
```

### Import the Library

```swift
import [PROJECT_NAME]
```

### Create Your First Data Store

```swift
let intervals = (1...12).map { Interval.month(year: 2025, month: $0) }
let values: [Double] = [100, 110, 121, 133, 146, 161, 177, 195, 214, 236, 259, 285]

let dataStore = DataStore(
    intervals: intervals,
    values: values,
    metadata: Metadata(name: "Monthly Values", units: "units")
)
```

### Calculate Trends

```swift
let periodOverPeriod = dataStore.growthRate(lag: 1)
let avgGrowth = mean(periodOverPeriod.valuesArray)
print("Average periodic growth: \(avgGrowth.percent(2))")
```

## Topics

### Next Steps
- <doc:DataStoreInDepth>
- <doc:AdvancedWorkflows>
- <doc:AnalysisGuide>
```

### Concept Article

`CoreConcepts.md`:
```markdown
# Core Concepts

Understand and apply the fundamental calculations in [PROJECT_NAME].

## Overview

[PROJECT_NAME] is built around a set of core concepts:
values can be transformed across time periods, aggregated,
and solved for unknown parameters.

## Core Concepts

### Forward Calculation

Compute the projected value given a base and a rate:

```swift
let input: Double = 10000
let rate: Double = 0.08
let periods = 5

let result = computeValue(input: input, rate: rate, periods: periods)
// Result: 6,805.83
```

### Reverse Calculation

Derive the original value from a known result:

```swift
let baseValue: Double = 5000
let rate: Double = 0.07
let periods = 10

let result = deriveValue(baseValue: baseValue, rate: rate, periods: periods)
// Result: 9,835.76
```

### Aggregate Calculation

Evaluate a sequence of values with a given rate:

```swift
let items = [-100000.0, 30000.0, 30000.0, 30000.0, 30000.0]
let result = calculate(inputValue: 0.10, items: items)
```

## Topics

### Functions
- ``computeValue(input:rate:periods:)``
- ``deriveValue(baseValue:rate:periods:)``
- ``calculate(inputValue:items:)``
- ``solveRate(items:guess:)``

### Related Concepts
- <doc:AdvancedCalculations>
- <doc:RateSolving>
```

---

## Best Practices

### 1. Write Documentation First

Consider documentation as part of your API design:
- Write doc comments before implementation
- Helps clarify the API design
- Ensures documentation stays in sync

### 2. Use Consistent Terminology

```swift
// Good - consistent terminology
/// The input rate used in aggregate calculations.

// Less good - inconsistent
/// The rate of input for computing values.
```

### 3. Provide Context

```swift
// Good - explains why and when
/// Solve for the unknown rate given a series of values.
/// Use this to evaluate the effectiveness of a sequence and compare
/// different approaches. The solved rate is the value that zeroes out the result.

// Less good - just states what
/// Solves for the rate.
```

### 4. Include Realistic, Playground-Ready Examples

```swift
// Good - complete, realistic example
/// ```swift
/// // Evaluate a series with initial outlay and periodic returns
/// let items = [-100000.0, 30000.0, 35000.0, 40000.0, 45000.0]
/// let rate = try solveRate(items: items)
/// print("Rate: \(rate.percent(2))")  // Rate: ~20.5%
/// ```

// Less good - trivial example
/// ```swift
/// let result = solveRate(items: values)
/// ```
```

### 5. Cross-Reference Related APIs

```swift
/// - SeeAlso:
///   - ``computeValue(input:rate:periods:)`` for single-item calculations
///   - ``solveModifiedRate(items:rateA:rateB:)`` for modified rate solving
///   - ``solveRateIrregular(dates:items:)`` for irregular intervals
```

### 6. Document Edge Cases

```swift
/// - Parameters:
///   - x: An array of values. Returns `T(0)` if empty.
///
/// - Returns: The arithmetic mean, or `T(0)` for an empty array.
///
/// - Note: This function treats empty arrays as having a mean of zero
///   rather than being undefined. For stricter behavior, check
///   `x.isEmpty` before calling.
```

### 7. Explain Mathematical Concepts

```swift
/// ## Mathematical Background
///
/// The standard deviation measures dispersion around the mean:
/// ```
/// σ = √(Σ(x - μ)² / n)
/// ```
/// where:
/// - σ = standard deviation
/// - x = each value
/// - μ = mean
/// - n = number of values
///
/// For sample standard deviation, use `n - 1` (Bessel's correction).
```

### 8. Keep Examples Self-Contained & Playground-Ready

> **See [Mandatory Example Requirements](#⚠️-mandatory-example-requirements)** for complete rules.

Every example must:
- Run in a fresh Xcode Playground without modification
- Include all imports and variable definitions
- Use unique variable names (no collisions with other examples)
- Specify seeds for any stochastic/random operations
- Show expected output as comments

```swift
/// ## Usage Example
/// ```swift
/// import [PROJECT_NAME]
///
/// let intervals = (1...5).map { Interval.year(2020 + $0 - 1) }
/// let items = [-100000.0, 30000.0, 30000.0, 30000.0, 30000.0]
///
/// let result = calculate(inputValue: 0.10, items: items)
/// print("Result: \(result.formatted(2))")  // Result: -4,641.92
/// ```
```

---

## Common DocC Pitfalls and Solutions

> **⚠️ CRITICAL CHECKLIST FOR NEW TUTORIALS**
>
> Before marking any tutorial as "done", verify ALL of these:
> 1. ✅ Ends with "Next Steps" section (article links using `<doc:...>`)
> 2. ✅ Ends with "See Also" section (API symbols using ` ``Symbol`` `)
> 3. ✅ Added to the `[PROJECT_NAME].md` landing page
> 4. ✅ NO "Related Documentation" section
> 5. ✅ NO `## Topics` header in article body
> 6. ✅ Article appears in navigation when docs are built
>
> **If any item is unchecked, the tutorial will not display correctly!**

### Pitfall 1: Using `## Topics` in Narrative Articles

**Problem**: Adding a `## Topics` header in tutorial articles causes them to appear as "API Collections" instead of proper narrative articles in Xcode documentation viewer.

**Why it happens**: `## Topics` is a special reserved header in DocC used exclusively for organizing API documentation symbols. When DocC encounters this header in a file, it treats the file as API documentation rather than a narrative article.

**Solution**:
- For narrative articles and tutorials, use `## Content` or `## Overview` instead
- Use regular `##` headers for main sections without a `## Topics` wrapper
- Reserve `## Topics` only for API symbol documentation pages

**Example - Wrong**:
```markdown
# Building Data Models

Learn how to construct complete data models.

## Topics

### Creating an Entity
Every data model starts with an entity...

### Building a Report
The report shows computed results...
```

**Example - Correct**:
```markdown
# Building Data Models

Learn how to construct complete data models.

## Overview

[PROJECT_NAME] provides a comprehensive framework...

## Creating an Entity
Every data model starts with an entity...

## Building a Report
The report shows computed results...
```

### Pitfall 2: Article Names Conflicting with Code Symbols

**Problem**: Tutorial articles with names matching code types or symbols can cause DocC to confuse the article with the API symbol, leading to incorrect content display.

**Why it happens**: DocC tries to resolve documentation references and may conflate article names with actual code symbol names, especially when they're identical.

**Solution**:
- Add descriptive suffixes to tutorial filenames (e.g., "Guide", "Tutorial", "Walkthrough")
- Example: `DataModel.md` -> `DataModelGuide.md`
- Update all cross-references to use the new filenames

**Example file naming**:
```
Wrong:
- DataModel.md (conflicts with DataModel type)
- Simulation.md (conflicts with Simulation module)

Correct:
- DataModelGuide.md
- SimulationTutorial.md
- AnalysisWalkthrough.md
```

### Pitfall 3: Incorrect Header Hierarchy in Articles

**Problem**: Using `###` subsections under `## Topics` prevents content from displaying correctly in documentation viewer.

**Why it happens**: When combined with `## Topics`, DocC expects `###` headers to reference API symbols, not narrative content sections.

**Solution**:
- Use `##` for all main sections in narrative articles
- Don't nest content sections under `## Topics`
- Use `###` and deeper only for subsections within narrative content

**Example - Wrong**:
```markdown
## Topics

### Problem Overview
Let me explain the problem...

### Solution Approach
Here's how we solve it...
```

**Example - Correct**:
```markdown
## Problem Overview
Let me explain the problem...

### Key Considerations
When solving this...

## Solution Approach
Here's how we solve it...

### Implementation Steps
Follow these steps...
```

### Pitfall 4: Broken Cross-References After Renaming

**Problem**: After renaming tutorial files, existing cross-references break, causing documentation build warnings or broken links.

**Solution**:
- Update all `<doc:...>` references when renaming files
- Search the entire `.docc` directory for references to the old name
- Use command-line tools for batch updates:

```bash
# Example: Updating all references after renaming
cd Sources/[PROJECT_NAME]/[PROJECT_NAME].docc
grep -r "<doc:DataModel>" .
sed -i '' 's/<doc:DataModel>/<doc:DataModelGuide>/g' *.md
```

### Quick Reference: Article vs API Documentation

| Feature | Narrative Article | API Documentation |
|---------|------------------|-------------------|
| Purpose | Tutorials, guides, walkthroughs | Type, function, property docs |
| `## Topics` | ❌ Don't use | ✅ Use for organizing symbols |
| Header structure | `##` for main sections | `## Topics` with `### ` groups |
| File location | `.docc/` directory | Inline or `.docc/` extension docs |
| File naming | Descriptive (e.g., `*Guide.md`) | Match symbol name |
| Cross-refs | `<doc:ArticleName>` | `<doc:SymbolName>` or ` ``SymbolName`` ` |

### Diagnostic Steps for Documentation Issues

If your tutorials appear as "API Collections" or show wrong content:

1. **Check for `## Topics` header** - Remove or change to `## Content`
2. **Verify header hierarchy** - Use `##` for main sections, not `###` under Topics
3. **Check filename conflicts** - Ensure article names don't match code symbols
4. **Validate cross-references** - Ensure all `<doc:...>` references are current
5. **Clean build** - Product → Clean Build Folder, then rebuild documentation
6. **Check DocC warnings** - Review build output for documentation warnings

### Pitfall 5: Incorrect "Related Documentation" Structure ⚠️ CRITICAL

**Problem**: Using "Related Documentation" as a section header with mixed article and API symbol links prevents tutorials from displaying correctly.

**Why it happens**: DocC expects two separate, properly structured sections at the end of tutorials:
1. "Next Steps" for article cross-references
2. "See Also" for API symbol references

Mixing both types in a single "Related Documentation" section or using incorrect link syntax causes parsing issues.

**Solution**: Always end narrative tutorials with these two separate sections in this exact order:

**Example - Wrong ❌**:
```markdown
## Related Documentation

- ``Configuration`` - Configuration modeling and settings
- ``DataModel`` - Data model with schema details
- <doc:AdvancedFeaturesGuide> for extended features
- ``Template`` - Reusable template definitions
```

**Example - Correct ✅**:
```markdown
## Next Steps

- Explore <doc:AdvancedFeaturesGuide> for extended capabilities
- Learn about <doc:DataModelingGuide> for complete data modeling
- Follow <doc:BuildingWorkflows> to integrate configurations into workflows

## See Also

- ``Configuration``
- ``DataModel``
- ``Template``
- ``Schema``
```

**Key Rules**:
1. **"Next Steps" section**: Only use `<doc:ArticleName>` with descriptive text explaining why to visit that article
2. **"See Also" section**: Only use ` ``SymbolName`` ` with NO extra description text
3. **Never mix**: Keep article links and API symbol links completely separate
4. **Always have both**: Include both sections even if one is short
5. **Order matters**: "Next Steps" always comes before "See Also"

### Pitfall 6: Forgetting to Add New Tutorials to Landing Page ⚠️ CRITICAL

**Problem**: New tutorial articles are created but don't appear in the documentation's top-level navigation.

**Why it happens**: Creating a `.md` file in the `.docc` directory is not enough. The article must be explicitly referenced in the main landing page (`[PROJECT_NAME].md`) to appear in navigation.

**Solution**: After creating any new tutorial or guide, immediately add it to the `[PROJECT_NAME].md` landing page in the appropriate section.

**Steps**:
1. Create your tutorial file (e.g., `NewFeatureGuide.md`)
2. Open `Sources/[PROJECT_NAME]/[PROJECT_NAME].docc/[PROJECT_NAME].md`
3. Add reference to the appropriate `## Topics` section:

```markdown
## Topics

### Tutorials

- <doc:GettingStarted>
- <doc:DataModelingGuide>
- <doc:NewFeatureGuide>  ← Add your new guide here
- <doc:AdvancedFeaturesGuide>  ← And here
- <doc:ExampleWorkflowA>
```

**Checklist for every new tutorial**:
- [ ] Created `.md` file in `.docc` directory
- [ ] Added to appropriate section in `[PROJECT_NAME].md`
- [ ] Used exact filename (without `.md` extension) in `<doc:...>` reference
- [ ] Verified documentation builds without warnings
- [ ] Confirmed article appears in navigation when viewing docs

**Why this is critical**: Without the landing page reference, your tutorial exists but is "orphaned" - users can only access it through direct links or search, not through normal navigation. This defeats the purpose of creating comprehensive documentation.

---

## Documentation Checklist

For every public type/function:
- [ ] Single-line summary
- [ ] Detailed description (2-3 sentences minimum)
- [ ] All parameters documented
- [ ] Return value documented
- [ ] Throws documented (if applicable)
- [ ] At least one usage example that is:
  - [ ] Self-contained (runs in fresh Playground)
  - [ ] Includes all imports and variable definitions
  - [ ] Shows expected output as comments
  - [ ] Uses unique variable names (no collisions with other examples)
  - [ ] Specifies seed if using random generation
- [ ] Related functions cross-referenced
- [ ] Edge cases explained
- [ ] Domain equivalent noted (for functions with well-known counterparts)
- [ ] Mathematical formula included (for math functions)

**MCP Readiness** (for ALL public APIs):
- [ ] MCP JSON schema example included (`## MCP Schema` section)
- [ ] All parameters have explicit types matching JSON Schema mapping
- [ ] Nested objects fully documented with all properties
- [ ] Date formats explicitly specified as ISO 8601
- [ ] Enum values listed exhaustively
- [ ] Optional vs required parameters clearly marked
- [ ] Stochastic functions include `seed` parameter in schema

For modules:
- [ ] Overview article in `.docc`
- [ ] Getting started guide
- [ ] Core concepts explained
- [ ] Topics organized logically
- [ ] Real-world examples provided

**Article Naming** (prevents DocC parser conflicts):
- [ ] Article filenames do NOT match Swift symbol names (e.g., use `DataModelGuide.md`, not `DataModel.md`)

**For every new tutorial/guide article** ⚠️ CRITICAL:
- [ ] File created in `.docc` directory with descriptive name ending in "Guide", "Tutorial", or "Walkthrough"
- [ ] Ends with "Next Steps" section (article links only using `<doc:...>`)
- [ ] Ends with "See Also" section (API symbols only using ` ``Symbol`` `)
- [ ] Added to `[PROJECT_NAME].md` landing page in appropriate `## Topics` section
- [ ] Documentation builds without warnings (`swift build`)
- [ ] Article appears in top-level navigation when viewing docs
- [ ] NO "Related Documentation" section mixing both types of links
- [ ] NO `## Topics` header in narrative article body

---

## 8. Article vs API Documentation Decision

### The Core Question

When documenting a feature, the LLM must determine: **API Documentation** or **Narrative Article**?

Making the wrong choice leads to either:
- Orphaned conceptual content buried in function comments (too much in API docs)
- Shallow tutorials that don't explain what functions actually do (too little in API docs)

### Decision Tree

```
┌─────────────────────────────────────────────────────────────┐
│     ARTICLE VS API DOCUMENTATION DECISION TREE               │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Is this documenting a SINGLE symbol (type, function)?       │
│     │                                                        │
│     ├─ YES → Use API Documentation (/// comments)           │
│     │         • What does this specific tool do?             │
│     │         • Parameters, returns, throws                  │
│     │         • Self-contained usage example                 │
│     │         • MCP JSON schema (if applicable)              │
│     │                                                        │
│     └─ NO → Does it combine MULTIPLE APIs or explain theory? │
│              │                                               │
│              ├─ YES → Use Narrative Article (.md in .docc)   │
│              │         • "How-To" guides                     │
│              │         • Conceptual deep dives               │
│              │         • Onboarding tutorials                │
│              │         • Mathematical theory                 │
│              │                                               │
│              └─ NO → Probably API docs for each symbol       │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### When to Use API Documentation (`///`)

Use triple-slash comments for **every public type, function, or property**:

| Content | Goes in API Docs |
|---------|------------------|
| What the function does | ✅ Yes |
| Parameter descriptions | ✅ Yes |
| Return value description | ✅ Yes |
| Single, focused usage example | ✅ Yes |
| MCP JSON schema for this function | ✅ Yes |
| Mathematical formula for this function | ✅ Yes |
| Edge case behavior | ✅ Yes |

**API docs answer:** *"What does THIS specific tool do?"*

### When to Use Narrative Articles (`.md`)

Create a narrative article when:

| Situation | Article Type |
|-----------|--------------|
| Combining 3+ APIs to accomplish a task | How-To Guide |
| Explaining mathematical theory behind a module | Conceptual Guide |
| Onboarding new users to a subsystem | Tutorial |
| Comparing approaches (e.g., "Method A vs Method B") | Deep Dive |
| Workflow spanning multiple steps | Walkthrough |

**Articles answer:** *"HOW do I use these tools together?"* or *"WHY does this work this way?"*

### Complexity Threshold Rule

**If a feature requires more than 50 lines of documentation to explain properly, it needs an article.**

This is a rough heuristic:
- Simple function with 3 parameters: API docs only
- Function requiring 3 examples to show variants: API docs + consider article
- Feature involving 5+ functions working together: Definitely needs article

### Structural Requirements

#### API Documentation Must Have:
```swift
/// Brief one-line summary.
///
/// Detailed explanation (2-3 sentences).
///
/// - Parameters:
///   - param1: Description
/// - Returns: Description
/// - Throws: Description (if applicable)
///
/// ## Usage Example
/// ```swift
/// // Self-contained, playground-ready example
/// import YourLibrary
/// let result = yourFunction(param: value)
/// print(result)  // Expected: output
/// ```
///
/// ## MCP Schema
/// ```json
/// {"param1": "value", "param2": 123}
/// ```
```

#### Narrative Articles Must Have:
```markdown
# Article Title

Introduction explaining what the reader will learn.

## Section 1: Core Concepts
Content explaining theory or setup.

## Section 2: Step-by-Step
Walkthrough with code examples.

## Section 3: Advanced Usage (optional)
Edge cases, optimizations.

## Next Steps
- <doc:RelatedGuide1>
- <doc:RelatedGuide2>

## See Also
- ``RelatedFunction1``
- ``RelatedType``
```

### Anti-Patterns

#### ❌ Tutorial Content in API Docs
```swift
/// Calculate the aggregate result.
///
/// Aggregate calculation is a core metric that computes
/// the combined result of all values in a series... [500 words of theory]
///
/// To understand aggregation, first consider the base concepts...
/// [Another 300 words explaining fundamentals]
```
**Problem:** Conceptual content belongs in an article, not a function comment.

#### ❌ Shallow Article Without API References
```markdown
# Getting Started with Aggregate Calculations

Aggregation is useful for analysis. Here's how to use it:

\```swift
let result = calculate(inputValue: 0.1, items: values)
\```

That's it!
```
**Problem:** No depth, no `## See Also` linking to actual API docs.

#### ✅ Correct Separation
**API Doc (`calculate` function):**
```swift
/// Calculate the aggregate result for a series of values.
///
/// - Parameters:
///   - inputValue: Rate per period
///   - items: Array of values (first is typically negative)
/// - Returns: Aggregate result
///
/// ## Usage Example
/// ```swift
/// let result = calculate(inputValue: 0.1, items: [-1000, 300, 300, 300, 300])
/// print(result)  // 146.87
/// ```
```

**Article (`AnalysisGuide.md`):**
```markdown
# Analysis with Aggregate and Rate-Solving Functions

This guide explains how to perform analysis using [PROJECT_NAME]'s
core functions.

## Understanding Aggregate Calculations

Aggregation answers: "What is the combined effect of these values?"
[Conceptual explanation with diagrams]

## Comparing Aggregation and Rate Solving

[Detailed comparison of when to use each]

## See Also
- ``calculate(inputValue:items:)``
- ``solveRate(items:)``
```

---

## 9. MCP-Ready Documentation Guidelines

> **Key Principle:** Treat AI models as a primary user class. Even if you never
> build an MCP server, documenting as if you will produces better APIs and docs.

### Overview

Model Context Protocol (MCP) tools require exceptionally clear documentation because AI assistants must construct proper tool calls without human guidance. Poor documentation leads to malformed tool calls and frustrated users.

**MCP Readiness applies to ALL public APIs**, not just explicit MCP tools. Any function could be exposed via MCP in the future, so document accordingly.

### Swift to JSON Schema Type Mapping

When documenting parameters for MCP consumption, use this mapping:

| Swift Type | JSON Schema Type | Format / Requirements |
|------------|------------------|----------------------|
| `Double` / `T: Real` | `number` | Specify valid range if constrained |
| `Int` | `integer` | Note if must be positive (`n > 0`) |
| `String` | `string` | Provide examples for patterns |
| `Bool` | `boolean` | Default to `false` unless specified |
| `Date` | `string` | **MANDATORY:** ISO 8601 format (`"2024-01-15T00:00:00Z"`) |
| `enum` | `string` | **MANDATORY:** List ALL allowed values |
| `[T]` | `array` | Specify `items` type |
| `struct` / `class` | `object` | Document ALL properties |
| `T?` (Optional) | any | Mark as `"required": false` |

### Stochastic Function Requirements

For ANY function involving randomness (Monte Carlo, sampling, distributions):

```swift
/// - Parameters:
///   - seed: Random seed for reproducibility. **Required for deterministic results.**
///
/// ## MCP Schema
/// ```json
/// {
///   "iterations": 10000,
///   "seed": 42
/// }
/// ```
///
/// **Note:** Same seed always produces identical results.
```

**Rule:** If a function CAN be stochastic, it MUST accept an optional seed parameter, and the MCP schema MUST document it.

### Critical Principle: Show, Don't Just Tell

**AI models need explicit JSON examples, not just descriptions.** A description like "Array of objects with 'date' and 'amount' properties" leaves too much ambiguity about structure, nesting, and formatting.

### Documentation Structure for MCP Tools

Every MCP tool must have:
1. **REQUIRED STRUCTURE** section with minimal working example
2. **Complete examples** showing realistic use cases
3. **Explicit input schema** with detailed parameter descriptions
4. **Type information** for every field in nested structures

### Rule 1: Always Include REQUIRED STRUCTURE

At the start of every tool description, show the minimal JSON structure:

**Example - Good ✅**:
```swift
description: """
Calculate aggregate result for irregular items with specific dates.

REQUIRED STRUCTURE:
{
  "rate": 0.10,
  "items": [
    {"date": "2024-01-15T00:00:00Z", "amount": -100000},
    {"date": "2024-06-15T00:00:00Z", "amount": 30000}
  ]
}

Example: Sequence with quarterly entries
{
  "rate": 0.08,
  "items": [
    {"date": "2024-01-01T00:00:00Z", "amount": -50000},
    {"date": "2024-04-15T00:00:00Z", "amount": 15000}
  ]
}
"""
```

**Example - Poor ❌**:
```swift
description: "Calculate aggregate result for irregular items"
```

### Rule 2: Document Nested Objects Explicitly

For any parameter that is an object or array of objects, show the complete structure:

**Example - Good ✅**:
```swift
"inputs": MCPSchemaProperty(
    type: "array",
    description: """
    Array of input variables. Each object must have:
    • name (string): Variable name (e.g., "Throughput")
    • distribution (string): "normal", "uniform", or "triangular"
    • parameters (object): Distribution parameters
      - normal: {mean: number, stdDev: number}
      - uniform: {min: number, max: number}

    Example: [{"name": "Throughput", "distribution": "normal", "parameters": {"mean": 1000000, "stdDev": 200000}}]
    """,
    items: MCPSchemaItems(type: "object")
)
```

**Example - Poor ❌**:
```swift
"inputs": MCPSchemaProperty(
    type: "array",
    description: "Array of input variables",
    items: MCPSchemaItems(type: "object")
)
```

### Rule 3: Show Multiple Examples for Complex Tools

Provide 2-3 complete examples showing different use cases:

```swift
description: """
Run Monte Carlo simulation.

REQUIRED STRUCTURE:
{
  "inputs": [{"name": "Throughput", "distribution": "normal", "parameters": {"mean": 1000000, "stdDev": 200000}}],
  "calculation": "{0}",
  "iterations": 10000
}

Example 1: Single-variable model
{
  "inputs": [{"name": "Throughput", "distribution": "normal", "parameters": {"mean": 1000000, "stdDev": 200000}}],
  "calculation": "{0}",
  "iterations": 10000
}

Example 2: Two-variable model (Output - Overhead)
{
  "inputs": [
    {"name": "Output", "distribution": "normal", "parameters": {"mean": 1000000, "stdDev": 200000}},
    {"name": "Overhead", "distribution": "normal", "parameters": {"mean": 600000, "stdDev": 100000}}
  ],
  "calculation": "{0} - {1}",
  "iterations": 10000
}
"""
```

### Rule 4: Specify Format Requirements Explicitly

Don't assume AI models know formatting conventions:

**Example - Good ✅**:
```swift
description: """
• date (string): ISO 8601 format (e.g., "2024-01-15T00:00:00Z")
• type (string): "annual", "quarterly", "monthly", or "daily"
"""
```

**Example - Poor ❌**:
```swift
description: "Date string and type"
```

### Rule 5: Document Optional vs Required Fields

Clearly indicate which fields are required vs optional:

**Example - Good ✅**:
```swift
"variableRange": MCPSchemaProperty(
    type: "object",
    description: """
    Range to test. Use ONE of:
    • {"percentChange": 20} - test ±20% from base (optional: defaults to ±10%)
    • {"min": 80, "max": 120} - test explicit range (both required)
    """
)
```

### Rule 6: Provide Inline Examples in Schema Descriptions

Include example JSON directly in the schema description:

```swift
"items": MCPSchemaProperty(
    type: "array",
    description: """
    Array of item objects. Each must have:
    • date (string): ISO 8601 format
    • amount (number): Item amount

    Example: [{"date": "2024-01-01T00:00:00Z", "amount": -100000}, {"date": "2024-12-31T00:00:00Z", "amount": 110000}]
    """
)
```

### Common Patterns Requiring Special Attention

#### Arrays of Objects
Always show complete object structure with type annotations:
```swift
"variables": [
  {"name": "Output", "baseValue": 1000000, "lowValue": 800000, "highValue": 1200000},
  {"name": "Overhead", "baseValue": 600000, "lowValue": 500000, "highValue": 700000}
]
```

#### Nested Objects with Variants
Show all variants clearly:
```swift
// Time period object - structure varies by type
{"year": 2024, "type": "annual"}                              // Annual
{"year": 2024, "month": 1, "type": "quarterly"}               // Quarterly
{"year": 2024, "month": 6, "type": "monthly"}                 // Monthly
{"year": 2024, "month": 3, "day": 15, "type": "daily"}       // Daily
```

#### Dates and Times
Always specify exact format:
```swift
// ISO 8601 format required
{"date": "2024-01-15T00:00:00Z", "amount": -100000}
```

#### Alternative Formats
When multiple formats are accepted, show examples of each:
```swift
// Option 1: Percent change
{"variableRange": {"percentChange": 20}}

// Option 2: Explicit range
{"variableRange": {"min": 800000, "max": 1200000}}
```

### MCP Tool Documentation Checklist

For every MCP tool:
- [ ] Includes "REQUIRED STRUCTURE" section with minimal example
- [ ] Has at least 2 complete usage examples
- [ ] Every nested object structure is fully documented
- [ ] All parameters have type information (string, number, object, array)
- [ ] Date/time formats explicitly specified (e.g., ISO 8601)
- [ ] Enum values listed explicitly
- [ ] Optional vs required fields clearly marked
- [ ] Example JSON included in schema descriptions
- [ ] Complex parameters have inline examples
- [ ] Alternative formats all shown with examples

### MCP Tool Discoverability (Orphan Prevention)

Every new MCP-ready tool **must** be cross-referenced in the module's landing page to prevent "orphaned" tools that other agents cannot discover:

```markdown
<!-- In [PROJECT_NAME].md landing page -->

## MCP Tools

| Tool | Description |
|------|-------------|
| ``computeValue(input:rate:periods:)`` | Compute forward value from inputs |
| ``deriveValue(baseValue:rate:periods:)`` | Derive reverse value from result |
| [Add new tool here] | [Description] |
```

**Rule:** No MCP tool is complete until it appears in the landing page's MCP Tools section.

### Testing Documentation Quality

To verify documentation quality, ask:
1. Could an AI generate a valid tool call from description alone?
2. Are all nested structures shown explicitly?
3. Are format requirements (dates, enums) specified?
4. Do examples cover common use cases?
5. Is the minimal working example truly minimal?

If the answer to any question is "no", improve the documentation.

### Why This Matters

**Without explicit examples**: AI models hallucinate incorrect structures, leading to "Missing or invalid 'inputs' array" errors and user frustration.

**With explicit examples**: AI models reliably construct correct tool calls, leading to successful executions and happy users.

**Investment**: 5-10 minutes of extra documentation per tool
**Payoff**: 90%+ reduction in malformed tool calls

---

## Related Documents

- [Master Plan](00_MASTER_PLAN.md)
- [Coding Rules](01_CODING_RULES.md)
- [Usage Examples](02_USAGE_EXAMPLES.md)
- [Implementation Checklist](../04_IMPLEMENTATION_CHECKLISTS/TEMPLATE.md)

## External Resources

- [Swift-DocC Documentation](https://www.swift.org/documentation/docc/)
- [Apple DocC Guide](https://developer.apple.com/documentation/docc)
- [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- [Model Context Protocol Specification](https://spec.modelcontextprotocol.io/)
