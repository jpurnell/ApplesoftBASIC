import Testing
@testable import ApplesoftBASICLib

@Suite("Parser")
struct ParserTests {

    /// Helper: tokenize and parse a BASIC source string.
    private func parse(_ source: String) throws -> Program {
        var lexer = Lexer(source: source)
        let tokens = try lexer.tokenize()
        var parser = Parser(tokens: tokens)
        return try parser.parse()
    }

    // MARK: - Golden Path: Statement Types

    @Test("Parses REM statement")
    func remStatement() throws {
        let program = try parse("10 REM THIS IS A COMMENT")
        #expect(program.lines.count == 1)
        #expect(program.lines[0].lineNumber == 10)
        if case .rem(let text) = program.lines[0].statements[0] {
            #expect(text.contains("THIS IS A COMMENT"))
        } else {
            Issue.record("Expected REM statement")
        }
    }

    @Test("Parses PRINT string literal")
    func printString() throws {
        let program = try parse("10 PRINT \"HELLO\"")
        #expect(program.lines.count == 1)
        if case .print(let items) = program.lines[0].statements[0] {
            #expect(items.count >= 1)
        } else {
            Issue.record("Expected PRINT statement")
        }
    }

    @Test("Parses PRINT with semicolons")
    func printSemicolons() throws {
        let program = try parse("10 PRINT \"A\";\"B\";\"C\"")
        if case .print(let items) = program.lines[0].statements[0] {
            let semicolonCount = items.filter { $0.separator == .semicolon }.count
            #expect(semicolonCount >= 2)
        } else {
            Issue.record("Expected PRINT statement")
        }
    }

    @Test("Parses PRINT with commas")
    func printCommas() throws {
        let program = try parse("10 PRINT A,B,C")
        if case .print(let items) = program.lines[0].statements[0] {
            let commaCount = items.filter { $0.separator == .comma }.count
            #expect(commaCount >= 2)
        } else {
            Issue.record("Expected PRINT statement")
        }
    }

    @Test("Parses bare PRINT (empty line)")
    func barePrint() throws {
        let program = try parse("10 PRINT")
        if case .print(let items) = program.lines[0].statements[0] {
            // Bare PRINT should produce an empty items list or just a newline
            let hasExpression = items.contains { $0.expression != nil }
            #expect(!hasExpression)
        } else {
            Issue.record("Expected PRINT statement")
        }
    }

    @Test("Parses LET assignment")
    func letAssignment() throws {
        let program = try parse("10 LET A = 42")
        if case .letStatement(let variable, let value) = program.lines[0].statements[0] {
            #expect(variable == .variable("A"))
            #expect(value == .numberLiteral(42))
        } else {
            Issue.record("Expected LET statement")
        }
    }

    @Test("Parses implicit LET (assignment without LET keyword)")
    func implicitLet() throws {
        let program = try parse("10 A = 42")
        if case .letStatement(let variable, _) = program.lines[0].statements[0] {
            #expect(variable == .variable("A"))
        } else {
            Issue.record("Expected implicit LET statement")
        }
    }

    @Test("Parses GOTO")
    func gotoStatement() throws {
        let program = try parse("10 GOTO 100")
        if case .goto(let target) = program.lines[0].statements[0] {
            #expect(target == .numberLiteral(100))
        } else {
            Issue.record("Expected GOTO statement")
        }
    }

    @Test("Parses GOSUB and RETURN")
    func gosubReturn() throws {
        let source = """
        10 GOSUB 100
        100 RETURN
        """
        let program = try parse(source)
        if case .gosub(let target) = program.lines[0].statements[0] {
            #expect(target == .numberLiteral(100))
        } else {
            Issue.record("Expected GOSUB statement")
        }
        if case .returnStatement = program.lines[1].statements[0] {
            // pass
        } else {
            Issue.record("Expected RETURN statement")
        }
    }

    @Test("Parses IF...THEN with line number")
    func ifThenLineNumber() throws {
        let program = try parse("10 IF A = 1 THEN 100")
        if case .ifThen(let condition, let body) = program.lines[0].statements[0] {
            if case .binary(_, let op, _) = condition {
                #expect(op == .equal)
            } else {
                Issue.record("Expected binary condition")
            }
            if case .lineNumber(let expr) = body {
                #expect(expr == .numberLiteral(100))
            } else {
                Issue.record("Expected line number body")
            }
        } else {
            Issue.record("Expected IF...THEN statement")
        }
    }

    @Test("Parses IF...THEN with GOTO")
    func ifThenGoto() throws {
        let program = try parse("10 IF A = 50 THEN GOTO 250")
        guard case .ifThen(_, let body) = program.lines[0].statements[0] else {
            Issue.record("Expected IF...THEN statement")
            return
        }
        guard case .statement(let stmt) = body else {
            Issue.record("Expected statement body")
            return
        }
        if case .goto(let target) = stmt {
            #expect(target == .numberLiteral(250))
        } else {
            Issue.record("Expected GOTO in IF body")
        }
    }

    @Test("Parses IF...THEN with inline statement")
    func ifThenStatement() throws {
        let program = try parse("10 IF X > 0 THEN PRINT \"POSITIVE\"")
        guard case .ifThen(_, let body) = program.lines[0].statements[0] else {
            Issue.record("Expected IF...THEN statement")
            return
        }
        guard case .statement(let stmt) = body else {
            Issue.record("Expected statement body")
            return
        }
        #expect({
            if case .print = stmt { return true }
            return false
        }())
    }

    @Test("Parses FOR...NEXT loop")
    func forNextLoop() throws {
        let source = """
        10 FOR I = 1 TO 10
        20 PRINT I
        30 NEXT I
        """
        let program = try parse(source)
        if case .forStatement(let variable, let start, let end, let step) = program.lines[0].statements[0] {
            #expect(variable == "I")
            #expect(start == .numberLiteral(1))
            #expect(end == .numberLiteral(10))
            #expect(step == nil)
        } else {
            Issue.record("Expected FOR statement")
        }
        if case .next(let variable) = program.lines[2].statements[0] {
            #expect(variable == "I")
        } else {
            Issue.record("Expected NEXT statement")
        }
    }

    @Test("Parses FOR with STEP")
    func forWithStep() throws {
        let program = try parse("10 FOR I = 10 TO 0 STEP -1")
        if case .forStatement(_, _, _, let step) = program.lines[0].statements[0] {
            guard let step else {
                Issue.record("Expected STEP")
                return
            }
            // Should be unary negate of 1, or numberLiteral(-1)
            // Either representation is acceptable
            if case .numberLiteral(let value) = step {
                #expect(value == -1.0)
            } else if case .unary(let op, let operand) = step {
                #expect(op == .negate)
                #expect(operand == .numberLiteral(1))
            } else {
                Issue.record("Expected numeric STEP value")
            }
        } else {
            Issue.record("Expected FOR statement with STEP")
        }
    }

    @Test("Parses INPUT with prompt")
    func inputWithPrompt() throws {
        let program = try parse("10 INPUT \"ENTER NAME: \";N$")
        if case .input(let prompt, let variables) = program.lines[0].statements[0] {
            #expect(prompt == "ENTER NAME: ")
            #expect(variables.count == 1)
            #expect(variables[0] == .variable("N$"))
        } else {
            Issue.record("Expected INPUT statement")
        }
    }

    @Test("Parses INPUT without prompt")
    func inputWithoutPrompt() throws {
        let program = try parse("10 INPUT A")
        if case .input(let prompt, let variables) = program.lines[0].statements[0] {
            #expect(prompt == nil)
            #expect(variables.count == 1)
        } else {
            Issue.record("Expected INPUT statement")
        }
    }

    @Test("Parses DIM")
    func dimStatement() throws {
        let program = try parse("10 DIM A(10)")
        if case .dim(let declarations) = program.lines[0].statements[0] {
            #expect(declarations.count == 1)
            #expect(declarations[0].name == "A")
            #expect(declarations[0].dimensions.count == 1)
        } else {
            Issue.record("Expected DIM statement")
        }
    }

    @Test("Parses 2D DIM")
    func dim2D() throws {
        let program = try parse("10 DIM B(5,10)")
        if case .dim(let declarations) = program.lines[0].statements[0] {
            #expect(declarations[0].dimensions.count == 2)
        } else {
            Issue.record("Expected 2D DIM statement")
        }
    }

    @Test("Parses DATA statement")
    func dataStatement() throws {
        let program = try parse("10 DATA 1,2,3,\"HELLO\"")
        if case .data(let values) = program.lines[0].statements[0] {
            #expect(values.count == 4)
            #expect(values[0] == .number(1))
            #expect(values[3] == .string("HELLO"))
        } else {
            Issue.record("Expected DATA statement")
        }
    }

    @Test("Parses READ")
    func readStatement() throws {
        let program = try parse("10 READ A,B$")
        if case .read(let variables) = program.lines[0].statements[0] {
            #expect(variables.count == 2)
            #expect(variables[0] == .variable("A"))
            #expect(variables[1] == .variable("B$"))
        } else {
            Issue.record("Expected READ statement")
        }
    }

    @Test("Parses RESTORE")
    func restoreStatement() throws {
        let program = try parse("10 RESTORE")
        #expect({
            if case .restore = program.lines[0].statements[0] { return true }
            return false
        }())
    }

    @Test("Parses ON...GOTO")
    func onGoto() throws {
        let program = try parse("10 ON X GOTO 100,200,300")
        if case .onGoto(_, let targets) = program.lines[0].statements[0] {
            #expect(targets.count == 3)
        } else {
            Issue.record("Expected ON...GOTO statement")
        }
    }

    @Test("Parses ON...GOSUB")
    func onGosub() throws {
        let program = try parse("10 ON X GOSUB 100,200,300")
        if case .onGosub(_, let targets) = program.lines[0].statements[0] {
            #expect(targets.count == 3)
        } else {
            Issue.record("Expected ON...GOSUB statement")
        }
    }

    @Test("Parses DEF FN")
    func defFn() throws {
        let program = try parse("10 DEF FN AREA(R) = 3.14159 * R * R")
        if case .defFn(let name, let param, _) = program.lines[0].statements[0] {
            #expect(name == "AREA")
            #expect(param == "R")
        } else {
            Issue.record("Expected DEF FN statement")
        }
    }

    @Test("Parses HOME")
    func homeStatement() throws {
        let program = try parse("10 HOME")
        #expect({
            if case .home = program.lines[0].statements[0] { return true }
            return false
        }())
    }

    @Test("Parses END")
    func endStatement() throws {
        let program = try parse("10 END")
        #expect({
            if case .end = program.lines[0].statements[0] { return true }
            return false
        }())
    }

    // MARK: - Expressions

    @Test("Parses arithmetic expression with precedence")
    func arithmeticPrecedence() throws {
        // 2 + 3 * 4 should parse as 2 + (3 * 4)
        let program = try parse("10 LET A = 2 + 3 * 4")
        if case .letStatement(_, let value) = program.lines[0].statements[0] {
            if case .binary(let left, let op, _) = value {
                #expect(op == .plus)
                #expect(left == .numberLiteral(2))
            } else {
                Issue.record("Expected binary expression")
            }
        } else {
            Issue.record("Expected LET statement")
        }
    }

    @Test("Parses parenthesized expression")
    func parenthesizedExpression() throws {
        // (2 + 3) * 4 should group addition first
        let program = try parse("10 LET A = (2 + 3) * 4")
        if case .letStatement(_, let value) = program.lines[0].statements[0] {
            if case .binary(_, let op, let right) = value {
                #expect(op == .multiply)
                #expect(right == .numberLiteral(4))
            } else {
                Issue.record("Expected binary expression with multiply at top")
            }
        } else {
            Issue.record("Expected LET statement")
        }
    }

    @Test("Parses unary negation")
    func unaryNegation() throws {
        let program = try parse("10 LET A = -5")
        if case .letStatement(_, let value) = program.lines[0].statements[0] {
            if case .unary(let op, let operand) = value {
                #expect(op == .negate)
                #expect(operand == .numberLiteral(5))
            } else if case .numberLiteral(let n) = value {
                // Also acceptable: lexer may produce -5 directly
                #expect(n == -5.0)
            } else {
                Issue.record("Expected unary negation or negative literal")
            }
        } else {
            Issue.record("Expected LET statement")
        }
    }

    @Test("Parses function call")
    func functionCall() throws {
        let program = try parse("10 LET A = SIN(3.14)")
        if case .letStatement(_, let value) = program.lines[0].statements[0] {
            if case .functionCall(let name, let args) = value {
                #expect(name == "SIN")
                #expect(args.count == 1)
            } else {
                Issue.record("Expected function call expression")
            }
        } else {
            Issue.record("Expected LET statement")
        }
    }

    @Test("Parses string function with multiple arguments")
    func stringFunction() throws {
        let program = try parse("10 LET A$ = LEFT$(B$,3)")
        if case .letStatement(_, let value) = program.lines[0].statements[0] {
            if case .functionCall(let name, let args) = value {
                #expect(name == "LEFT$")
                #expect(args.count == 2)
            } else {
                Issue.record("Expected function call expression")
            }
        } else {
            Issue.record("Expected LET statement")
        }
    }

    @Test("Parses logical operators")
    func logicalOperators() throws {
        let program = try parse("10 IF A > 0 AND B > 0 THEN 100")
        guard case .ifThen(let condition, _) = program.lines[0].statements[0] else {
            Issue.record("Expected IF...THEN statement")
            return
        }
        #expect({
            if case .and = condition { return true }
            return false
        }())
    }

    @Test("Parses NOT operator")
    func notOperator() throws {
        let program = try parse("10 IF NOT A THEN 100")
        if case .ifThen(let condition, _) = program.lines[0].statements[0] {
            if case .unary(let op, _) = condition {
                #expect(op == .not)
            } else {
                Issue.record("Expected NOT expression")
            }
        } else {
            Issue.record("Expected IF...THEN statement")
        }
    }

    // MARK: - Multiple Statements Per Line

    @Test("Parses colon-separated statements")
    func colonSeparation() throws {
        let program = try parse("10 A = 1 : B = 2 : C = 3")
        #expect(program.lines[0].statements.count == 3)
    }

    // MARK: - Program Structure

    @Test("Lines are sorted by line number")
    func linesSorted() throws {
        let source = """
        30 END
        10 PRINT "FIRST"
        20 PRINT "SECOND"
        """
        let program = try parse(source)
        #expect(program.lines[0].lineNumber == 10)
        #expect(program.lines[1].lineNumber == 20)
        #expect(program.lines[2].lineNumber == 30)
    }

    @Test("Parses the full birthday program")
    func birthdayProgram() throws {
        let source = """
        10 REM *** HAPPY BIRTHDAY APPLE ***
        20 REM *** FOUNDED APRIL 1, 1976 ***
        30 PRINT
        40 PRINT "*** HAPPY BIRTHDAY APPLE! ***"
        50 PRINT
        60 LET V = 1
        70 IF V = 1 THEN PRINT "HAPPY BIRTHDAY TO YOU..."
        80 IF V = 2 THEN PRINT "HAPPY BIRTHDAY TO YOU..."
        90 IF V = 3 THEN PRINT "HAPPY BIRTHDAY DEAR APPLE..."
        100 IF V = 4 THEN PRINT "HAPPY BIRTHDAY TO YOU!"
        110 IF V = 4 THEN GOTO 150
        120 LET V = V + 1
        130 GOTO 70
        150 PRINT
        160 PRINT "NOW... HOW OLD ARE YOU?"
        170 PRINT
        180 LET A = 1
        190 PRINT "ARE YOU ";A;"?"
        200 IF A = 50 THEN GOTO 250
        210 PRINT "...NOOOO!"
        220 LET A = A + 1
        230 GOTO 190
        250 PRINT "...YAAAAY!!!"
        260 PRINT
        270 PRINT "APPLE IS 50 YEARS OLD TODAY!"
        280 PRINT "APRIL 1, 1976 - APRIL 1, 2026"
        290 PRINT
        300 PRINT "NOW GO EAT SOME CAKE!"
        310 GOTO 320
        320 END
        """
        let program = try parse(source)
        #expect(program.lines.count == 30)
        #expect(program.lines.first?.lineNumber == 10)
        #expect(program.lines.last?.lineNumber == 320)
    }

    // MARK: - Edge Cases

    @Test("Empty program produces empty lines")
    func emptyProgram() throws {
        let program = try parse("")
        #expect(program.lines.isEmpty)
    }

    // MARK: - Error Cases

    @Test("Missing line number throws error")
    func missingLineNumber() throws {
        #expect(throws: BASICError.self) {
            try parse("PRINT \"HELLO\"")
        }
    }
}
