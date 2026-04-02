/// A complete BASIC program: an ordered collection of numbered lines.
public struct Program: Sendable, Equatable {
    /// The lines of the program, sorted by line number.
    public let lines: [Line]

    /// Initializes a program from an array of lines.
    public init(lines: [Line]) {
        self.lines = lines.sorted { $0.lineNumber < $1.lineNumber }
    }
}

/// A single numbered line in a BASIC program, containing one or more statements.
public struct Line: Sendable, Equatable {
    /// The line number.
    public let lineNumber: Int

    /// The statements on this line (separated by colons in source).
    public let statements: [Statement]
}

/// A BASIC statement (one executable unit).
public indirect enum Statement: Sendable, Equatable {
    /// `REM comment text`
    case rem(String)

    /// `PRINT expr; expr, expr` — items with separators.
    case print([PrintItem])

    /// `LET var = expr` (LET keyword is optional in Applesoft).
    case letStatement(variable: LValue, value: Expression)

    /// `GOTO lineNumber`
    case goto(Expression)

    /// `GOSUB lineNumber`
    case gosub(Expression)

    /// `RETURN`
    case returnStatement

    /// `IF condition THEN lineNumber/statement`
    case ifThen(condition: Expression, then: IfBody)

    /// `FOR var = start TO end [STEP step]`
    case forStatement(variable: String, start: Expression, end: Expression, step: Expression?)

    /// `NEXT [var]`
    case next(variable: String?)

    /// `INPUT ["prompt";] var [, var ...]`
    case input(prompt: String?, variables: [LValue])

    /// `GET var`
    case get(variable: LValue)

    /// `DIM var(size) [, var(size) ...]`
    case dim([DimDeclaration])

    /// `DATA value, value, ...`
    case data([DataValue])

    /// `READ var [, var ...]`
    case read([LValue])

    /// `RESTORE`
    case restore

    /// `ON expr GOTO line, line, ...`
    case onGoto(Expression, [Expression])

    /// `ON expr GOSUB line, line, ...`
    case onGosub(Expression, [Expression])

    /// `DEF FN name(param) = expr`
    case defFn(name: String, parameter: String, body: Expression)

    /// `HOME`
    case home

    /// `HTAB expr`
    case htab(Expression)

    /// `VTAB expr`
    case vtab(Expression)

    /// `INVERSE`
    case inverse

    /// `NORMAL`
    case normal

    /// `FLASH`
    case flash

    /// `END`
    case end

    /// `STOP`
    case stop
}

/// The body of an IF...THEN: either a line number to GOTO or an inline statement.
public enum IfBody: Sendable, Equatable {
    /// `IF cond THEN 100` — implicit GOTO.
    case lineNumber(Expression)

    /// `IF cond THEN PRINT "YES"` — inline statement.
    case statement(Statement)
}

/// An item in a PRINT statement, with its trailing separator.
public struct PrintItem: Sendable, Equatable {
    /// The expression to print (nil for a bare separator).
    public let expression: Expression?

    /// The separator following this item.
    public let separator: PrintSeparator

    /// Creates a print item with an optional expression and separator.
    public init(expression: Expression?, separator: PrintSeparator = .newline) {
        self.expression = expression
        self.separator = separator
    }
}

/// Separators between PRINT items controlling cursor behavior.
public enum PrintSeparator: Sendable, Equatable {
    /// Semicolon: no space added.
    case semicolon
    /// Comma: advance to next tab stop (columns 0, 16, 32).
    case comma
    /// End of PRINT: advance to next line.
    case newline
}

/// A value that can be assigned to (variable or array element).
public enum LValue: Sendable, Equatable {
    /// A simple variable: `A`, `X1`, `N$`
    case variable(String)
    /// An array element: `A(1)`, `B(I,J)`
    case arrayElement(name: String, indices: [Expression])
}

/// A value in a DATA statement.
public enum DataValue: Sendable, Equatable {
    /// A numeric data value.
    case number(Double)
    /// A string data value.
    case string(String)
}

/// An expression in Applesoft BASIC.
public indirect enum Expression: Sendable, Equatable {
    /// A numeric literal: `42`, `3.14`
    case numberLiteral(Double)

    /// A string literal: `"HELLO"`
    case stringLiteral(String)

    /// A variable reference: `A`, `N$`
    case variable(String)

    /// An array element access: `A(1)`, `B(I,J)`
    case arrayAccess(name: String, indices: [Expression])

    /// A binary operation: `expr + expr`
    case binary(left: Expression, op: Operator, right: Expression)

    /// A unary operation: `-expr`, `NOT expr`
    case unary(op: UnaryOperator, operand: Expression)

    /// A built-in function call: `SIN(X)`, `LEFT$(A$,3)`
    case functionCall(name: String, arguments: [Expression])

    /// A user-defined function call: `FN AREA(R)`
    case userFunctionCall(name: String, argument: Expression)

    /// Logical AND.
    case and(Expression, Expression)

    /// Logical OR.
    case or(Expression, Expression)

    /// `TAB(n)` — cursor positioning in PRINT.
    case tab(Expression)

    /// `SPC(n)` — spaces in PRINT.
    case spc(Expression)
}

/// Unary operators.
public enum UnaryOperator: Sendable, Equatable {
    /// Arithmetic negation: `-expr`
    case negate
    /// Logical negation: `NOT expr`
    case not
}

/// A DIM declaration for a single array.
public struct DimDeclaration: Sendable, Equatable {
    /// The array name.
    public let name: String
    /// The dimension sizes.
    public let dimensions: [Expression]

    /// Creates a DIM declaration for an array with the given dimensions.
    public init(name: String, dimensions: [Expression]) {
        self.name = name
        self.dimensions = dimensions
    }
}
