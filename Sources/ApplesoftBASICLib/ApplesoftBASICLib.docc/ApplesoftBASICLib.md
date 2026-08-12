# ``ApplesoftBASICLib``

A Swift implementation of the Applesoft BASIC interpreter, built for Apple's 50th birthday.

## Overview

ApplesoftBASICLib provides a complete three-stage interpreter pipeline for Applesoft BASIC:
source text is tokenized by the ``Lexer``, parsed into an abstract syntax tree by the ``Parser``,
and executed by the ``Interpreter``.

The interpreter faithfully reproduces the behavior of Applesoft BASIC as shipped on the Apple II
(1977–1993), supporting arithmetic, string operations, flow control, arrays, subroutines,
math functions, and screen commands — all running natively on modern macOS via Swift.

```
Source Text → Lexer → Tokens → Parser → AST → Interpreter → Output
```

### Running a Program

```swift
import ApplesoftBASICLib

let source = """
10 PRINT "HELLO WORLD"
20 END
"""

var lexer = Lexer(source: source)
let tokens = try lexer.tokenize()
var parser = Parser(tokens: tokens)
let program = try parser.parse()
var rng = SystemRandomNumberGenerator()
let interpreter = Interpreter(program: program, rng: &rng)
try interpreter.run()
```

### Testable I/O

Inject ``CapturedOutput`` and ``ScriptedInput`` to capture output and script input in tests:

```swift
let output = CapturedOutput()
let input = ScriptedInput(responses: ["APPLE"])
var testableIORNG = SystemRandomNumberGenerator()
let testableIOInterpreter = Interpreter(
    program: program,
    output: output,
    input: input,
    rng: &testableIORNG
)
try testableIOInterpreter.run()
// output.lines contains all printed lines
```

## Topics

### Essentials

- <doc:Tutorial>
- <doc:LanguageReference>

### Interpreter Pipeline

- ``Lexer``
- ``Parser``
- ``Interpreter``

### Tokens and Syntax Tree

- ``Token``
- ``Keyword``
- ``Operator``
- ``Program``
- ``Line``
- ``Statement``
- ``Expression``

### I/O Protocols

- ``OutputHandler``
- ``InputHandler``
- ``ConsoleOutput``
- ``ConsoleInput``
- ``CapturedOutput``
- ``ScriptedInput``

### Errors

- ``BASICError``
