/// Parses a stream of tokens into an abstract syntax tree.
///
/// The parser converts the flat token stream from the ``Lexer`` into a structured
/// ``Program`` consisting of numbered ``Line``s containing ``Statement``s and
/// ``Expression``s.
public struct Parser: Sendable {
    private let tokens: [Token]
    private var position: Int = 0

    /// Creates a parser for the given token stream.
    ///
    /// - Parameter tokens: The tokens to parse, as produced by ``Lexer``.
    public init(tokens: [Token]) {
        self.tokens = tokens
    }

    /// Parses the token stream into a program AST.
    ///
    /// - Returns: A ``Program`` representing the parsed source code.
    /// - Throws: ``BASICError`` if the tokens contain invalid syntax.
    public mutating func parse() throws -> Program {
        var lines: [Line] = []
        let maxLines = 10_000

        while position < tokens.count {
            guard lines.count < maxLines else {
                throw BASICError.outOfMemory("Line limit exceeded")
            }
            skipEndOfLines()
            guard position < tokens.count else { break }

            let line = try parseLine()
            lines.append(line)
        }

        return Program(lines: lines)
    }

    // MARK: - Line Parsing

    private mutating func parseLine() throws -> Line {
        guard case .lineNumber(let num) = peek() else {
            throw BASICError.expectedLineNumber
        }
        advance()

        var statements: [Statement] = []
        let maxStatements = 100

        while position < tokens.count && peek() != .endOfLine {
            guard statements.count < maxStatements else {
                throw BASICError.outOfMemory("Too many statements on one line")
            }

            let stmt = try parseStatement()
            statements.append(stmt)

            // Consume colon separator between statements
            if peek() == .colon {
                advance()
            }
        }

        // Consume end of line
        if peek() == .endOfLine {
            advance()
        }

        return Line(lineNumber: num, statements: statements)
    }

    // MARK: - Statement Parsing

    private mutating func parseStatement() throws -> Statement {
        guard let token = peek() else {
            throw BASICError.unexpectedEndOfInput
        }

        switch token {
        case .keyword(let kw):
            switch kw {
            case .REM:
                return try parseRem()
            case .PRINT:
                advance()
                return try parsePrint()
            case .LET:
                advance()
                return try parseLetAssignment()
            case .GOTO:
                advance()
                let target = try parseExpression()
                return .goto(target)
            case .GOSUB:
                advance()
                let target = try parseExpression()
                return .gosub(target)
            case .RETURN:
                advance()
                return .returnStatement
            case .IF:
                return try parseIfThen()
            case .FOR:
                return try parseFor()
            case .NEXT:
                return try parseNext()
            case .INPUT:
                return try parseInput()
            case .GET:
                return try parseGet()
            case .DIM:
                return try parseDim()
            case .DATA:
                return try parseData()
            case .READ:
                return try parseRead()
            case .RESTORE:
                advance()
                return .restore
            case .ON:
                return try parseOn()
            case .DEF:
                return try parseDefFn()
            case .HOME:
                advance()
                return .home
            case .HTAB:
                advance()
                let expr = try parseExpression()
                return .htab(expr)
            case .VTAB:
                advance()
                let expr = try parseExpression()
                return .vtab(expr)
            case .INVERSE:
                advance()
                return .inverse
            case .NORMAL:
                advance()
                return .normal
            case .FLASH:
                advance()
                return .flash
            case .END:
                advance()
                return .end
            case .STOP:
                advance()
                return .stop
            case .CLR:
                advance()
                return .restore // CLR is similar to reset
            default:
                throw BASICError.unexpectedToken(String(describing: token), expected: "statement")
            }

        case .identifier:
            // Implicit LET
            return try parseLetAssignment()

        default:
            throw BASICError.unexpectedToken(String(describing: token), expected: "statement")
        }
    }

    // MARK: - Individual Statement Parsers

    private mutating func parseRem() throws -> Statement {
        advance() // skip REM keyword
        // The lexer captures the comment text as a string literal after REM
        if case .stringLiteral(let text) = peek() {
            advance()
            return .rem(text)
        }
        return .rem("")
    }

    private mutating func parsePrint() throws -> Statement {
        var items: [PrintItem] = []
        let maxItems = 1000

        // Bare PRINT (empty line)
        if peek() == .endOfLine || peek() == .colon || peek() == nil {
            return .print([PrintItem(expression: nil, separator: .newline)])
        }

        while position < tokens.count && peek() != .endOfLine && peek() != .colon {
            guard items.count < maxItems else {
                throw BASICError.outOfMemory("Too many PRINT items")
            }

            // Check for TAB( and SPC(
            if case .keyword(.TAB) = peek() {
                advance()
                try expect(.leftParen)
                let expr = try parseExpression()
                try expect(.rightParen)
                items.append(PrintItem(expression: .tab(expr), separator: .semicolon))
                continue
            }
            if case .keyword(.SPC) = peek() {
                advance()
                try expect(.leftParen)
                let expr = try parseExpression()
                try expect(.rightParen)
                items.append(PrintItem(expression: .spc(expr), separator: .semicolon))
                continue
            }

            // Check for bare separator
            if peek() == .semicolon {
                advance()
                if items.isEmpty {
                    items.append(PrintItem(expression: nil, separator: .semicolon))
                } else {
                    // Update the previous item's separator
                    let last = items.removeLast()
                    items.append(PrintItem(expression: last.expression, separator: .semicolon))
                }
                continue
            }
            if peek() == .comma {
                advance()
                if items.isEmpty {
                    items.append(PrintItem(expression: nil, separator: .comma))
                } else {
                    let last = items.removeLast()
                    items.append(PrintItem(expression: last.expression, separator: .comma))
                }
                continue
            }

            // Parse expression
            let expr = try parseExpression()
            items.append(PrintItem(expression: expr, separator: .newline))
        }

        // If the last item has a newline separator, that's the default (line feed at end)
        // If it ends with ; or , those suppress the newline
        return .print(items)
    }

    private mutating func parseLetAssignment() throws -> Statement {
        let lvalue = try parseLValue()
        try expect(.op(.equal))
        let value = try parseExpression()
        return .letStatement(variable: lvalue, value: value)
    }

    private mutating func parseLValue() throws -> LValue {
        guard case .identifier(let name) = peek() else {
            throw BASICError.unexpectedToken(
                String(describing: peek()),
                expected: "variable name"
            )
        }
        advance()

        // Check for array subscript
        if peek() == .leftParen {
            advance()
            var indices: [Expression] = []
            indices.append(try parseExpression())
            while peek() == .comma {
                advance()
                indices.append(try parseExpression())
            }
            try expect(.rightParen)
            return .arrayElement(name: name, indices: indices)
        }

        return .variable(name)
    }

    private mutating func parseIfThen() throws -> Statement {
        advance() // skip IF
        let condition = try parseExpression()
        try expectKeyword(.THEN)

        // After THEN, check if it's a line number or a statement
        if case .numberLiteral = peek() {
            let lineExpr = try parseExpression()
            return .ifThen(condition: condition, then: .lineNumber(lineExpr))
        }

        // It's an inline statement
        let stmt = try parseStatement()
        return .ifThen(condition: condition, then: .statement(stmt))
    }

    private mutating func parseFor() throws -> Statement {
        advance() // skip FOR
        guard case .identifier(let variable) = peek() else {
            throw BASICError.unexpectedToken(
                String(describing: peek()),
                expected: "variable name"
            )
        }
        advance()
        try expect(.op(.equal))
        let start = try parseExpression()
        try expectKeyword(.TO)
        let end = try parseExpression()

        var step: Expression?
        if case .keyword(.STEP) = peek() {
            advance()
            step = try parseExpression()
        }

        return .forStatement(variable: variable, start: start, end: end, step: step)
    }

    private mutating func parseNext() throws -> Statement {
        advance() // skip NEXT
        if case .identifier(let name) = peek() {
            advance()
            return .next(variable: name)
        }
        return .next(variable: nil)
    }

    private mutating func parseInput() throws -> Statement {
        advance() // skip INPUT
        var prompt: String?

        // Check for prompt string
        if case .stringLiteral(let text) = peek() {
            let savedPos = position
            advance()
            if peek() == .semicolon {
                advance()
                prompt = text
            } else {
                // Not a prompt, rewind
                position = savedPos
            }
        }

        var variables: [LValue] = []
        variables.append(try parseLValue())
        while peek() == .comma {
            advance()
            variables.append(try parseLValue())
        }

        return .input(prompt: prompt, variables: variables)
    }

    private mutating func parseGet() throws -> Statement {
        advance() // skip GET
        let lvalue = try parseLValue()
        return .get(variable: lvalue)
    }

    private mutating func parseDim() throws -> Statement {
        advance() // skip DIM
        var declarations: [DimDeclaration] = []

        repeat {
            guard case .identifier(let name) = peek() else {
                throw BASICError.unexpectedToken(
                    String(describing: peek()),
                    expected: "array name"
                )
            }
            advance()
            try expect(.leftParen)

            var dimensions: [Expression] = []
            dimensions.append(try parseExpression())
            while peek() == .comma {
                advance()
                dimensions.append(try parseExpression())
            }
            try expect(.rightParen)

            declarations.append(DimDeclaration(name: name, dimensions: dimensions))

            if peek() == .comma {
                advance()
            } else {
                break
            }
        } while true

        return .dim(declarations)
    }

    private mutating func parseData() throws -> Statement {
        advance() // skip DATA
        var values: [DataValue] = []
        let maxValues = 10_000

        repeat {
            guard values.count < maxValues else {
                throw BASICError.outOfMemory("Too many DATA values")
            }

            if case .stringLiteral(let text) = peek() {
                advance()
                values.append(.string(text))
            } else if case .numberLiteral(let num) = peek() {
                advance()
                values.append(.number(num))
            } else if peek() == .op(.minus) {
                advance()
                if case .numberLiteral(let num) = peek() {
                    advance()
                    values.append(.number(-num))
                } else {
                    throw BASICError.unexpectedToken(
                        String(describing: peek()),
                        expected: "number after minus"
                    )
                }
            } else {
                // Unquoted string data — read until comma or end of line
                // For simplicity, we'll just take whatever identifier/number is there
                break
            }

            if peek() == .comma {
                advance()
            } else {
                break
            }
        } while true

        return .data(values)
    }

    private mutating func parseRead() throws -> Statement {
        advance() // skip READ
        var variables: [LValue] = []

        variables.append(try parseLValue())
        while peek() == .comma {
            advance()
            variables.append(try parseLValue())
        }

        return .read(variables)
    }

    private mutating func parseOn() throws -> Statement {
        advance() // skip ON
        let expr = try parseExpression()

        let isGoto: Bool
        if case .keyword(.GOTO) = peek() {
            isGoto = true
            advance()
        } else if case .keyword(.GOSUB) = peek() {
            isGoto = false
            advance()
        } else {
            throw BASICError.unexpectedToken(
                String(describing: peek()),
                expected: "GOTO or GOSUB"
            )
        }

        var targets: [Expression] = []
        targets.append(try parseExpression())
        while peek() == .comma {
            advance()
            targets.append(try parseExpression())
        }

        if isGoto {
            return .onGoto(expr, targets)
        } else {
            return .onGosub(expr, targets)
        }
    }

    private mutating func parseDefFn() throws -> Statement {
        advance() // skip DEF
        try expectKeyword(.FN)

        guard case .identifier(let name) = peek() else {
            throw BASICError.unexpectedToken(
                String(describing: peek()),
                expected: "function name"
            )
        }
        advance()

        try expect(.leftParen)
        guard case .identifier(let param) = peek() else {
            throw BASICError.unexpectedToken(
                String(describing: peek()),
                expected: "parameter name"
            )
        }
        advance()
        try expect(.rightParen)

        try expect(.op(.equal))
        let body = try parseExpression()

        return .defFn(name: name, parameter: param, body: body)
    }

    // MARK: - Expression Parsing (Precedence Climbing)

    private mutating func parseExpression() throws -> Expression {
        return try parseOr()
    }

    private mutating func parseOr() throws -> Expression {
        var left = try parseAnd()
        while case .keyword(.OR) = peek() {
            advance()
            let right = try parseAnd()
            left = .or(left, right)
        }
        return left
    }

    private mutating func parseAnd() throws -> Expression {
        var left = try parseNot()
        while case .keyword(.AND) = peek() {
            advance()
            let right = try parseNot()
            left = .and(left, right)
        }
        return left
    }

    private mutating func parseNot() throws -> Expression {
        if case .keyword(.NOT) = peek() {
            advance()
            let operand = try parseComparison()
            return .unary(op: .not, operand: operand)
        }
        return try parseComparison()
    }

    private mutating func parseComparison() throws -> Expression {
        var left = try parseAddition()

        while let op = peekComparisonOp() {
            advance()
            let right = try parseAddition()
            left = .binary(left: left, op: op, right: right)
        }

        return left
    }

    private func peekComparisonOp() -> Operator? {
        guard let token = peek() else { return nil }
        switch token {
        case .op(.equal): return .equal
        case .op(.notEqual): return .notEqual
        case .op(.lessThan): return .lessThan
        case .op(.greaterThan): return .greaterThan
        case .op(.lessThanOrEqual): return .lessThanOrEqual
        case .op(.greaterThanOrEqual): return .greaterThanOrEqual
        default: return nil
        }
    }

    private mutating func parseAddition() throws -> Expression {
        var left = try parseMultiplication()

        while true {
            if peek() == .op(.plus) {
                advance()
                let right = try parseMultiplication()
                left = .binary(left: left, op: .plus, right: right)
            } else if peek() == .op(.minus) {
                advance()
                let right = try parseMultiplication()
                left = .binary(left: left, op: .minus, right: right)
            } else {
                break
            }
        }

        return left
    }

    private mutating func parseMultiplication() throws -> Expression {
        var left = try parsePower()

        while true {
            if peek() == .op(.multiply) {
                advance()
                let right = try parsePower()
                left = .binary(left: left, op: .multiply, right: right)
            } else if peek() == .op(.divide) {
                advance()
                let right = try parsePower()
                left = .binary(left: left, op: .divide, right: right)
            } else {
                break
            }
        }

        return left
    }

    private mutating func parsePower() throws -> Expression {
        let base = try parseUnary()

        if peek() == .op(.power) {
            advance()
            // Right-associative
            let exponent = try parsePower()
            return .binary(left: base, op: .power, right: exponent)
        }

        return base
    }

    private mutating func parseUnary() throws -> Expression {
        if peek() == .op(.minus) {
            advance()
            let operand = try parseUnary()
            return .unary(op: .negate, operand: operand)
        }
        if peek() == .op(.plus) {
            advance()
            return try parseUnary()
        }
        return try parsePrimary()
    }

    private mutating func parsePrimary() throws -> Expression {
        guard let token = peek() else {
            throw BASICError.unexpectedEndOfInput
        }

        switch token {
        case .numberLiteral(let value):
            advance()
            return .numberLiteral(value)

        case .stringLiteral(let value):
            advance()
            return .stringLiteral(value)

        case .leftParen:
            advance()
            let expr = try parseExpression()
            try expect(.rightParen)
            return expr

        case .keyword(let kw):
            return try parseKeywordExpression(kw)

        case .identifier(let name):
            advance()
            // Check for array access or function call
            if peek() == .leftParen {
                advance()
                var args: [Expression] = []
                if peek() != .rightParen {
                    args.append(try parseExpression())
                    while peek() == .comma {
                        advance()
                        args.append(try parseExpression())
                    }
                }
                try expect(.rightParen)
                return .arrayAccess(name: name, indices: args)
            }
            return .variable(name)

        default:
            throw BASICError.unexpectedToken(String(describing: token), expected: "expression")
        }
    }

    private mutating func parseKeywordExpression(_ kw: Keyword) throws -> Expression {
        switch kw {
        // Math functions
        case .ABS, .ATN, .COS, .EXP, .INT, .LOG, .SGN, .SIN, .SQR, .TAN,
             .ASC, .LEN, .VAL, .FRE, .POS, .PEEK, .RND:
            advance()
            try expect(.leftParen)
            let arg = try parseExpression()
            try expect(.rightParen)
            return .functionCall(name: kw.rawValue, arguments: [arg])

        // String functions (take multiple args)
        case .LEFT, .RIGHT, .MID:
            advance()
            // Consume the $ if present (lexer may have absorbed it into keyword)
            let funcName = kw.rawValue + "$"
            try expect(.leftParen)
            var args: [Expression] = []
            args.append(try parseExpression())
            while peek() == .comma {
                advance()
                args.append(try parseExpression())
            }
            try expect(.rightParen)
            return .functionCall(name: funcName, arguments: args)

        case .CHR, .STR:
            advance()
            let funcName = kw.rawValue + "$"
            try expect(.leftParen)
            let arg = try parseExpression()
            try expect(.rightParen)
            return .functionCall(name: funcName, arguments: [arg])

        case .FN:
            advance()
            guard case .identifier(let name) = peek() else {
                throw BASICError.unexpectedToken(
                    String(describing: peek()),
                    expected: "function name"
                )
            }
            advance()
            try expect(.leftParen)
            let arg = try parseExpression()
            try expect(.rightParen)
            return .userFunctionCall(name: name, argument: arg)

        case .TAB:
            advance()
            try expect(.leftParen)
            let expr = try parseExpression()
            try expect(.rightParen)
            return .tab(expr)

        case .SPC:
            advance()
            try expect(.leftParen)
            let expr = try parseExpression()
            try expect(.rightParen)
            return .spc(expr)

        case .NOT:
            advance()
            let operand = try parseComparison()
            return .unary(op: .not, operand: operand)

        default:
            throw BASICError.unexpectedToken(String(describing: kw), expected: "expression")
        }
    }

    // MARK: - Helpers

    private func peek() -> Token? {
        guard position < tokens.count else { return nil }
        return tokens[position]
    }

    @discardableResult
    private mutating func advance() -> Token? {
        guard position < tokens.count else { return nil }
        let token = tokens[position]
        position += 1
        return token
    }

    private mutating func expect(_ expected: Token) throws {
        guard let token = peek() else {
            throw BASICError.unexpectedEndOfInput
        }
        guard token == expected else {
            throw BASICError.unexpectedToken(
                String(describing: token),
                expected: String(describing: expected)
            )
        }
        advance()
    }

    private mutating func expectKeyword(_ kw: Keyword) throws {
        guard case .keyword(let actual) = peek() else {
            throw BASICError.unexpectedToken(
                String(describing: peek()),
                expected: kw.rawValue
            )
        }
        guard actual == kw else {
            throw BASICError.unexpectedToken(
                actual.rawValue,
                expected: kw.rawValue
            )
        }
        advance()
    }

    private mutating func skipEndOfLines() {
        while peek() == .endOfLine {
            advance()
        }
    }
}
