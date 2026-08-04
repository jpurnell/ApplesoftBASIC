# Design Proposal: Applesoft BASIC Interpreter

**Date:** 2026-04-01 (Apple's 50th Birthday)
**Status:** DRAFT
**Author:** Justin Purnell + Claude

---

## 1. Objective

Build a command-line Applesoft BASIC interpreter in Swift that faithfully reproduces
the behavior of Applesoft BASIC as shipped on the Apple II (1977–1993). The interpreter
runs `.bas` files and provides an interactive REPL, bringing 1976 to 2026 as a birthday
gift to Apple, written in Apple's own modern language.

---

## 2. Proposed Architecture

A classic three-stage interpreter pipeline:

```
Source Text → Tokenizer (Lexer) → Parser → AST → Interpreter (Runtime)
```

### Module Structure

```
Sources/ApplesoftBASICLib/
├── Errors/
│   └── BASICError.swift          # Error registry (single source of truth)
├── Lexer/
│   └── Lexer.swift               # Tokenizer: source → tokens
│   └── Token.swift               # Token type definitions
├── Parser/
│   └── Parser.swift              # Tokens → AST
│   └── AST.swift                 # Abstract syntax tree node types
├── Interpreter/
│   └── Interpreter.swift         # AST walker / executor
│   └── Environment.swift         # Variable storage, DATA pointer, call stack
│   └── BuiltInFunctions.swift    # Math, string, and utility functions
├── IO/
│   └── OutputHandler.swift       # Protocol for PRINT output (testable)
│   └── InputHandler.swift        # Protocol for INPUT/GET (testable)
└── ApplesoftBASICLib.swift       # Public API entry point

Sources/ApplesoftBASIC/
└── main.swift                    # CLI: REPL + file execution
```

---

## 3. API Surface

### Core Public Types

```swift
/// Tokenizes Applesoft BASIC source code into a stream of tokens.
public struct Lexer: Sendable {
    public init(source: String)
    public mutating func tokenize() throws -> [Token]
}

/// Represents a single lexical token from BASIC source code.
public enum Token: Sendable, Equatable {
    case lineNumber(Int)
    case keyword(Keyword)
    case identifier(String)
    case stringLiteral(String)
    case numberLiteral(Double)
    case op(Operator)
    case comma, semicolon, colon
    case leftParen, rightParen
    case endOfLine
}

/// Parses a token stream into an abstract syntax tree.
public struct Parser: Sendable {
    public init(tokens: [Token])
    public mutating func parse() throws -> Program
}

/// A complete BASIC program: ordered dictionary of line numbers → statements.
public struct Program: Sendable {
    public let lines: [(lineNumber: Int, statements: [Statement])]
}

/// Executes a parsed BASIC program.
public final class Interpreter {
    public init(
        program: Program,
        output: any OutputHandler = ConsoleOutput(),
        input: any InputHandler = ConsoleInput()
    )
    public func run() throws
}
```

### I/O Protocols (for testability)

```swift
/// Abstraction for PRINT output — enables capturing output in tests.
public protocol OutputHandler: Sendable {
    func print(_ text: String)
    func printLine(_ text: String)
    func clearScreen()
}

/// Abstraction for INPUT/GET — enables scripted input in tests.
public protocol InputHandler: Sendable {
    func readLine(prompt: String) -> String?
    func getChar() -> Character?
}
```

---

## 4. Language Features (Applesoft BASIC Compatibility)

### Tier 1 — Core (MVP, required for birthday program)
| Feature | Statements/Functions |
|---------|---------------------|
| Line numbers | Program storage and ordering |
| PRINT | String/numeric output, `;` and `,` formatting |
| LET | Variable assignment (numeric and string) |
| GOTO | Unconditional branch |
| IF...THEN | Conditional (THEN can be line number or statement) |
| FOR...NEXT | Counted loops with STEP |
| REM | Comments |
| END | Program termination |
| Arithmetic | `+`, `-`, `*`, `/`, `^`, unary `-` |
| Comparison | `=`, `<>`, `<`, `>`, `<=`, `>=` |
| Parentheses | Expression grouping |

### Tier 2 — Essential
| Feature | Statements/Functions |
|---------|---------------------|
| GOSUB/RETURN | Subroutine calls |
| INPUT | User input with optional prompt |
| DATA/READ/RESTORE | Inline data tables |
| DIM | Array declaration (1D and 2D) |
| ON...GOTO/GOSUB | Computed branching |
| AND/OR/NOT | Logical operators |
| String variables | `A$` naming convention |
| String functions | `LEFT$`, `RIGHT$`, `MID$`, `LEN`, `STR$`, `VAL`, `CHR$`, `ASC` |
| String concatenation | `+` operator for strings |

### Tier 3 — Math & Utility
| Feature | Functions |
|---------|-----------|
| Math | `INT`, `ABS`, `SQR`, `RND`, `SGN` |
| Trigonometry | `SIN`, `COS`, `TAN`, `ATN` |
| Logarithmic | `LOG`, `EXP` |
| Utility | `TAB()`, `SPC()`, `POS()` |

### Tier 4 — Screen & Display
| Feature | Statements |
|---------|-----------|
| HOME | Clear screen |
| HTAB/VTAB | Cursor positioning |
| INVERSE/NORMAL/FLASH | Text display modes |
| GET | Single character input |

### Explicitly Out of Scope
- `PEEK`/`POKE`/`CALL` (hardware memory access)
- `HPLOT`/`PLOT`/`GR`/`HGR`/`COLOR`/`HCOLOR` (graphics)
- `ONERR GOTO` (error trapping)
- `OPEN`/`CLOSE`/`PRINT#`/`INPUT#` (disk I/O)
- `SPEED=` / `IN#` / `PR#` (device control)

---

## 5. REPL & File Execution

### Interactive Mode (REPL)
```
$ applesoft
Applesoft BASIC Interpreter v0.1.0
]10 PRINT "HELLO WORLD"
]20 GOTO 10
]RUN
HELLO WORLD
HELLO WORLD
...
^C
BREAK
]LIST
10 PRINT "HELLO WORLD"
20 GOTO 10
]
```

### Interactive Commands (Direct Mode)
| Command | Description |
|---------|-------------|
| RUN | Execute the program |
| LIST | Display program listing |
| LIST n | Display line n |
| LIST n-m | Display lines n through m |
| NEW | Clear program from memory |
| DEL n | Delete line n |
| DEL n-m | Delete lines n through m |

### File Mode
```
$ applesoft birthday.bas
```

---

## 6. Constraints & Compliance

- **Swift 6**: Strict concurrency. All core types are value types (Sendable).
  `Interpreter` is a reference type because it holds mutable state (program counter,
  variables, call stack) but does not cross isolation boundaries.
- **No force unwraps**: Guard clauses throughout.
- **Division safety**: Check denominators in arithmetic evaluation.
- **Iteration limits**: GOTO/GOSUB loops enforced with configurable max step count
  (default 1,000,000) to prevent infinite loops in tests.
- **Bounded collections**: DATA storage, variable tables, and GOSUB call stack all
  have configurable max sizes.

---

## 7. Error Registry (Single Source of Truth)

```swift
/// All errors that the Applesoft BASIC interpreter can produce.
public enum BASICError: Error, Sendable, Equatable {
    // Lexer errors
    case unterminatedString(line: Int)
    case invalidCharacter(Character, line: Int)
    case invalidNumber(String, line: Int)

    // Parser errors
    case expectedLineNumber
    case unexpectedToken(Token, expected: String)
    case unexpectedEndOfInput

    // Runtime errors
    case undefinedVariable(String)
    case undefinedLine(Int)
    case typeMismatch(expected: String, got: String)
    case divisionByZero
    case outOfData
    case returnWithoutGosub
    case nextWithoutFor(variable: String?)
    case overflow
    case illegalQuantity(Double)
    case dimensionError(String)
    case redimensionError(String)
    case outOfMemory(String)
    case formulaTooComplex
    case stringTooLong
    case badSubscript(index: Int, bound: Int)
    case stepCountExceeded(limit: Int)
    case stackOverflow(depth: Int)

    // I/O errors
    case breakInterrupt
}
```

---

## 8. Test Strategy

| Category | What We Test |
|----------|-------------|
| **Lexer Golden Path** | Tokenize all keyword types, numbers, strings, operators |
| **Lexer Edge Cases** | Empty input, unterminated strings, very long lines |
| **Parser Golden Path** | Parse each statement type into correct AST |
| **Parser Edge Cases** | Missing line numbers, malformed expressions |
| **Interpreter Golden Path** | Execute simple programs, verify output |
| **Interpreter Edge Cases** | Division by zero, undefined variables, GOTO to missing line |
| **Integration** | Full programs (birthday program!), REPL session simulation |
| **Property-Based** | Round-trip: program → LIST → re-parse produces same AST |
| **Stress Tests** | Large programs, deep GOSUB nesting, large arrays |

### Testing I/O
- `OutputHandler` protocol enables capturing all PRINT output as `[String]`
- `InputHandler` protocol enables scripting INPUT responses
- No console I/O in tests — fully deterministic

---

## 9. Dependencies

- **None** (pure Swift, no external packages)

---

## 10. Open Questions

1. **Applesoft quirks**: Should we replicate Applesoft's two-character variable name
   limitation? (Original Applesoft only read first two characters: `TOTAL` and `TOAST`
   were the same variable.) **Recommendation: No — implement full names but document
   the historical behavior.**

2. **Error messages**: Applesoft used terse messages like `?SYNTAX ERROR`. Should we
   use those for authenticity, or more descriptive Swift-style errors?
   **Recommendation: Applesoft-style for REPL display, detailed `.description` on
   the Swift error type for programmatic use.**

3. **Floating point**: Applesoft used 40-bit Microsoft Binary Format. We'll use
   Swift's `Double` (64-bit IEEE 754). Results will differ slightly from original
   hardware. **Recommendation: Accept the difference, document it.**

---

## 11. Documentation Strategy

- DocC comments on all public types and functions
- A top-level `ApplesoftBASICLib.docc` documentation catalog with:
  - Getting Started guide
  - Language reference (supported statements)
  - Architecture overview
  - Historical notes on Applesoft BASIC
