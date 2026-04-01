# Floating-Point Formatting Guidelines

**Purpose:** Standards for displaying floating-point numbers in user-facing output.

---

## The Problem

Floating-point arithmetic produces numerical noise in the least significant digits:

```swift
// What the computer calculates:
let result = 2.9999999999999964

// What the user expects to see:
// 3.0
```

Common issues:
- `0.7500000000000002` instead of `0.75`
- `1.2345678901234567e-15` instead of `0`
- `99.99999999999999` truncating to `99` when cast to `Int`

---

## Core Principles

### 1. Display Clean, Calculate Raw

Always store and calculate with full precision, but display formatted values:

```swift
// Store raw value
let rawValue: Double = 2.9999999999999964

// Display formatted
print(rawValue.formatted())  // "3"

// Use raw for calculations
let nextValue = rawValue * 2  // Uses full precision
```

### 2. Smart Rounding

Round to integers when very close (within tolerance):

```swift
extension Double {
    /// Round to integer if within tolerance
    func smartRounded(tolerance: Double = 1e-9) -> Double {
        let rounded = self.rounded()
        if abs(self - rounded) < tolerance {
            return rounded
        }
        return self
    }
}

// Usage
2.9999999999999964.smartRounded()  // 3.0
2.5.smartRounded()                  // 2.5 (not close to integer)
```

### 3. Integer Conversion

**CRITICAL:** Never truncate when converting to integers. Always round:

```swift
// ❌ WRONG - truncates 99.999... to 99
let quantity = Int(floatingValue)

// ✅ CORRECT - rounds to 100
let quantity = Int(round(floatingValue))

// ✅ ALSO CORRECT - explicit rounding
let quantity = Int(floatingValue.rounded())
```

---

## Formatting Strategies

### Significant Figures

Use for scientific or general numeric output:

```swift
extension Double {
    func significantFigures(_ n: Int) -> String {
        guard n > 0 else { return "0" }
        guard self != 0 else { return "0" }

        let magnitude = floor(log10(abs(self)))
        let divisor = pow(10, magnitude - Double(n - 1))
        let rounded = (self / divisor).rounded() * divisor

        // Format with appropriate decimal places
        let decimals = max(0, n - 1 - Int(magnitude))
        return String(format: "%.\(decimals)f", rounded)
    }
}

// Examples
123456.789.significantFigures(3)  // "123000"
0.00123456.significantFigures(3)  // "0.00123"
```

### Fixed Decimal Places

Use for currency, percentages, or other fixed-format output:

```swift
extension Double {
    /// Format with fixed decimal places
    func number(_ decimals: Int = 2) -> String {
        String(format: "%.\(decimals)f", self)
    }

    /// Format as currency
    func currency(_ decimals: Int = 2) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = decimals
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }

    /// Format as percentage
    func percent(_ decimals: Int = 1) -> String {
        "\((self * 100).number(decimals))%"
    }
}

// Examples
14060.125.currency()     // "$14,060.13"
0.1523.percent()         // "15.2%"
3.14159.number(2)        // "3.14"
```

### Context-Aware Formatting

Choose strategy based on value characteristics:

```swift
extension Double {
    func formatted(
        maxDecimals: Int = 6,
        snapToInteger: Bool = true,
        zeroThreshold: Double = 1e-12
    ) -> String {
        // Handle essentially zero
        if abs(self) < zeroThreshold {
            return "0"
        }

        // Snap to integer if very close
        if snapToInteger {
            let rounded = self.rounded()
            if abs(self - rounded) < 1e-9 {
                return String(format: "%.0f", rounded)
            }
        }

        // Trim trailing zeros
        var result = String(format: "%.\(maxDecimals)f", self)
        while result.hasSuffix("0") && result.contains(".") {
            result.removeLast()
        }
        if result.hasSuffix(".") {
            result.removeLast()
        }

        return result
    }
}

// Examples
2.9999999999999964.formatted()  // "3"
0.75000000000000002.formatted() // "0.75"
1.234567890.formatted()         // "1.234568"
0.0.formatted()                 // "0"
```

---

## Array Formatting

Format arrays of numbers consistently:

```swift
extension Array where Element == Double {
    func formatted() -> String {
        "[\(self.map { $0.formatted() }.joined(separator: ", "))]"
    }
}

// Example
[2.9999, 3.0001, 4.5000].formatted()  // "[3, 3, 4.5]"
```

---

## Testing Formatted Output

### Don't Test String Equality for Values

```swift
// ❌ WRONG - fragile string comparison
#expect(result.description == "3.0")

// ✅ CORRECT - test numeric value
#expect(abs(result - 3.0) < 1e-9)

// ✅ ALSO CORRECT - test formatted output separately
#expect(result.formatted() == "3")
```

### Test Edge Cases

```swift
@Test("Formatting edge cases")
func formattingEdgeCases() {
    #expect(0.0.formatted() == "0")
    #expect((-0.0).formatted() == "0")
    #expect(Double.infinity.formatted().contains("inf"))
    #expect(Double.nan.formatted().lowercased().contains("nan"))
    #expect(1e-15.formatted() == "0")  // Essentially zero
    #expect(999999999999.9.formatted() == "1000000000000")  // Snaps to integer
}
```

---

## Common Pitfalls

### 1. Integer Truncation

```swift
// ❌ Dangerous - truncates toward zero
Int(99.999999999)  // 99, not 100!
Int(-0.1)          // 0, not -1!

// ✅ Safe - rounds to nearest
Int(round(99.999999999))  // 100
Int((-0.1).rounded())     // 0
```

### 2. String Format Precision Loss

```swift
// ❌ May lose precision
"\(value)"  // Uses default formatting

// ✅ Control precision explicitly
String(format: "%.15g", value)  // Full precision
value.formatted()               // Smart formatting
```

### 3. Comparison After Formatting

```swift
// ❌ Comparing formatted strings can fail
formatted1 == formatted2  // "3" vs "3.0"

// ✅ Compare raw values
abs(value1 - value2) < tolerance
```

---

## Configuration Defaults

Recommended defaults for different contexts:

| Context | Strategy | Example |
|---------|----------|---------|
| General display | Smart rounding, 6 decimals | `3.14159` |
| Currency | Fixed 2 decimals | `$1,234.56` |
| Percentages | Fixed 1-2 decimals | `15.2%` |
| Scientific | 3-4 significant figures | `1.23e6` |
| Integer results | Round to nearest | `100` |
| Probabilities | Fixed 3-4 decimals | `0.9532` |

---

## Implementation Checklist

When adding formatting to a project:

- [ ] Define standard formatting extensions for `Double`
- [ ] Add `smartRounded()` with configurable tolerance
- [ ] Add `formatted()` with sensible defaults
- [ ] Add domain-specific methods (`currency()`, `percent()`, etc.)
- [ ] Use `Int(round(x))` instead of `Int(x)` for integer conversion
- [ ] Test edge cases: 0, infinity, NaN, very small, very large
- [ ] Document expected output in tests
- [ ] Keep raw values accessible for calculations

---

## Related Documents

- [Coding Rules](01_CODING_RULES.md)
- [Test-Driven Development](09_TEST_DRIVEN_DEVELOPMENT.md)
