# Language Reference

A quick reference for all supported Applesoft BASIC statements, functions, and operators.

## Overview

This interpreter supports the core Applesoft BASIC language as shipped on the Apple II.
Programs consist of numbered lines, each containing one or more statements separated
by colons.

## Statements

### Output

| Statement | Description |
|-----------|-------------|
| `PRINT expr` | Print a value followed by a newline |
| `PRINT expr;` | Print a value with no newline |
| `PRINT expr,` | Print a value and advance to next tab stop (column 16, 32, ...) |
| `PRINT` | Print a blank line |
| `HOME` | Clear the screen |
| `HTAB expr` | Move cursor to column |
| `VTAB expr` | Move cursor to row |
| `INVERSE` | Switch to inverse text mode |
| `NORMAL` | Switch to normal text mode |
| `FLASH` | Switch to flashing text mode |

### Variables and Assignment

| Statement | Description |
|-----------|-------------|
| `LET var = expr` | Assign a value to a variable |
| `var = expr` | Assign (LET is optional) |
| `DIM var(size)` | Dimension an array |
| `DIM var(r,c)` | Dimension a 2D array |

Variable names can be any length. String variables end with `$` (e.g., `N$`).
Numeric variables default to 0. String variables default to empty string.
Arrays are 0-indexed; `DIM A(10)` creates indices 0 through 10.

### Flow Control

| Statement | Description |
|-----------|-------------|
| `GOTO line` | Jump to a line number |
| `GOSUB line` | Jump to a subroutine (use RETURN to come back) |
| `RETURN` | Return from a GOSUB |
| `IF cond THEN line` | If condition is true, GOTO line |
| `IF cond THEN stmt` | If condition is true, execute statement |
| `FOR var = start TO end` | Start a counted loop |
| `FOR var = start TO end STEP s` | Counted loop with custom step |
| `NEXT var` | End of a FOR loop |
| `ON expr GOTO l1,l2,...` | Computed GOTO (branch by value) |
| `ON expr GOSUB l1,l2,...` | Computed GOSUB |
| `END` | Stop the program |
| `STOP` | Stop the program |

### Input

| Statement | Description |
|-----------|-------------|
| `INPUT var` | Read user input into a variable |
| `INPUT "prompt";var` | Display prompt, then read input |
| `GET var` | Read a single keypress |

### Data

| Statement | Description |
|-----------|-------------|
| `DATA val,val,...` | Define inline data values |
| `READ var` | Read next DATA value into a variable |
| `RESTORE` | Reset DATA pointer to the beginning |

### User-Defined Functions

| Statement | Description |
|-----------|-------------|
| `DEF FN name(param) = expr` | Define a function |
| `FN name(arg)` | Call a user-defined function |

### Other

| Statement | Description |
|-----------|-------------|
| `REM text` | Comment (ignored by interpreter) |

## Operators

### Arithmetic

| Operator | Description | Example |
|----------|-------------|---------|
| `+` | Addition | `3 + 4` is `7` |
| `-` | Subtraction | `10 - 3` is `7` |
| `*` | Multiplication | `5 * 6` is `30` |
| `/` | Division | `15 / 4` is `3.75` |
| `^` | Exponentiation | `2 ^ 10` is `1024` |
| `-` | Negation (unary) | `-5` |

### Comparison (return 1 for true, 0 for false)

| Operator | Description |
|----------|-------------|
| `=` | Equal to |
| `<>` | Not equal to |
| `<` | Less than |
| `>` | Greater than |
| `<=` | Less than or equal to |
| `>=` | Greater than or equal to |

### Logical

| Operator | Description |
|----------|-------------|
| `AND` | True if both sides are nonzero |
| `OR` | True if either side is nonzero |
| `NOT` | True if operand is zero |

### String

| Operator | Description |
|----------|-------------|
| `+` | String concatenation |

## Built-In Functions

### Math

| Function | Description |
|----------|-------------|
| `ABS(x)` | Absolute value |
| `INT(x)` | Floor (round toward negative infinity) |
| `SGN(x)` | Sign: -1, 0, or 1 |
| `SQR(x)` | Square root |
| `RND(x)` | Random number between 0 and 1 |
| `SIN(x)` | Sine (x in radians) |
| `COS(x)` | Cosine |
| `TAN(x)` | Tangent |
| `ATN(x)` | Arctangent |
| `LOG(x)` | Natural logarithm |
| `EXP(x)` | e raised to the x |

### String

| Function | Description |
|----------|-------------|
| `LEN(s$)` | Length of string |
| `LEFT$(s$,n)` | First n characters |
| `RIGHT$(s$,n)` | Last n characters |
| `MID$(s$,start,len)` | Substring from position start |
| `ASC(s$)` | ASCII code of first character |
| `CHR$(n)` | Character from ASCII code (0-127) |
| `STR$(n)` | Convert number to string |
| `VAL(s$)` | Convert string to number |

### Print Formatting

| Function | Description |
|----------|-------------|
| `TAB(n)` | Move to column n in PRINT |
| `SPC(n)` | Print n spaces in PRINT |

## Interactive Commands

These commands work at the `]` prompt in the REPL:

| Command | Description |
|---------|-------------|
| `RUN` | Execute the program |
| `LIST` | Display the full program listing |
| `LIST n` | Display line n |
| `LIST n-m` | Display lines n through m |
| `NEW` | Erase the program from memory |
| `DEL n` | Delete line n |
| `DEL n-m` | Delete lines n through m |
| `BYE` | Exit the interpreter |

## Differences from Original Applesoft

- **Variable names**: Full-length names are supported. Original Applesoft only recognized
  the first two characters (`TOTAL` and `TOAST` were the same variable).
- **Floating point**: Uses 64-bit IEEE 754 doubles. Original Applesoft used 40-bit
  Microsoft Binary Format. Results may differ slightly.
- **No hardware access**: `PEEK`, `POKE`, and `CALL` are not supported.
- **No graphics**: Lo-res and hi-res graphics commands are not implemented.
- **No disk I/O**: File operations (`OPEN`, `CLOSE`, `PRINT#`, `INPUT#`) are not supported.
