import Foundation
import Testing
@testable import ApplesoftBASICLib

@Suite("Interpreter")
struct InterpreterTests {

    /// Helper: run a BASIC program and return captured output.
    private func run(_ source: String, input: [String] = [], maxSteps: Int = 100_000) throws -> CapturedOutput {
        var lexer = Lexer(source: source)
        let tokens = try lexer.tokenize()
        var parser = Parser(tokens: tokens)
        let program = try parser.parse()
        let output = CapturedOutput()
        let scriptedInput = ScriptedInput(responses: input)
        var rng = SeededGenerator(seed: 42)
        let interpreter = Interpreter(
            program: program,
            output: output,
            input: scriptedInput,
            maxSteps: maxSteps,
            rng: &rng
        )
        try interpreter.run()
        return output
    }

    // MARK: - Golden Path: PRINT

    @Test("PRINT string literal")
    func printString() throws {
        let output = try run("10 PRINT \"HELLO WORLD\"\n20 END")
        #expect(output.lines.contains("HELLO WORLD"))
    }

    @Test("PRINT number")
    func printNumber() throws {
        let output = try run("10 PRINT 42\n20 END")
        #expect(output.text.contains("42"))
    }

    @Test("PRINT empty line")
    func printEmpty() throws {
        let output = try run("10 PRINT\n20 END")
        #expect(output.text.contains("\n"))
    }

    @Test("PRINT with semicolon suppresses newline and spacing")
    func printSemicolon() throws {
        let output = try run("10 PRINT \"A\";\"B\";\"C\"\n20 END")
        #expect(output.text.contains("ABC"))
    }

    @Test("PRINT with comma uses tab stops")
    func printComma() throws {
        let output = try run("10 PRINT \"A\",\"B\"\n20 END")
        // Comma should advance to next tab column (16-char tab stops in Applesoft)
        #expect(output.text.contains("A"))
        #expect(output.text.contains("B"))
        // B should be indented past A
        guard let bRange = output.text.range(of: "B") else {
            Issue.record("B not found in output")
            return
        }
        let bPosition = output.text.distance(from: output.text.startIndex, to: bRange.lowerBound)
        #expect(bPosition >= 16)
    }

    @Test("Multiple PRINT statements on separate lines")
    func multiplePrints() throws {
        let source = """
        10 PRINT "FIRST"
        20 PRINT "SECOND"
        30 END
        """
        let output = try run(source)
        #expect(output.lines.count >= 2)
        #expect(output.lines[0] == "FIRST")
        #expect(output.lines[1] == "SECOND")
    }

    // MARK: - Golden Path: Variables & LET

    @Test("LET assigns and PRINT reads variable")
    func letAndPrint() throws {
        let source = """
        10 LET A = 42
        20 PRINT A
        30 END
        """
        let output = try run(source)
        #expect(output.text.contains("42"))
    }

    @Test("Implicit LET works")
    func implicitLet() throws {
        let source = """
        10 A = 42
        20 PRINT A
        30 END
        """
        let output = try run(source)
        #expect(output.text.contains("42"))
    }

    @Test("String variable assignment")
    func stringVariable() throws {
        let source = """
        10 LET N$ = "APPLE"
        20 PRINT N$
        30 END
        """
        let output = try run(source)
        #expect(output.lines.contains("APPLE"))
    }

    @Test("Arithmetic expressions evaluate correctly")
    func arithmetic() throws {
        let source = """
        10 LET A = 2 + 3 * 4
        20 PRINT A
        30 END
        """
        let output = try run(source)
        #expect(output.text.contains("14"))
    }

    @Test("Exponentiation works")
    func exponentiation() throws {
        let source = """
        10 LET A = 2 ^ 10
        20 PRINT A
        30 END
        """
        let output = try run(source)
        #expect(output.text.contains("1024"))
    }

    // MARK: - Golden Path: Control Flow

    @Test("GOTO jumps to target line")
    func gotoJumps() throws {
        let source = """
        10 GOTO 30
        20 PRINT "SKIPPED"
        30 PRINT "REACHED"
        40 END
        """
        let output = try run(source)
        #expect(!output.text.contains("SKIPPED"))
        #expect(output.text.contains("REACHED"))
    }

    @Test("IF...THEN executes when condition is true")
    func ifThenTrue() throws {
        let source = """
        10 LET A = 5
        20 IF A = 5 THEN PRINT "YES"
        30 END
        """
        let output = try run(source)
        #expect(output.text.contains("YES"))
    }

    @Test("IF...THEN skips when condition is false")
    func ifThenFalse() throws {
        let source = """
        10 LET A = 3
        20 IF A = 5 THEN PRINT "YES"
        30 PRINT "DONE"
        40 END
        """
        let output = try run(source)
        #expect(!output.text.contains("YES"))
        #expect(output.text.contains("DONE"))
    }

    @Test("IF...THEN with GOTO")
    func ifThenGoto() throws {
        let source = """
        10 LET A = 50
        20 IF A = 50 THEN GOTO 40
        30 PRINT "SKIPPED"
        40 PRINT "JUMPED"
        50 END
        """
        let output = try run(source)
        #expect(!output.text.contains("SKIPPED"))
        #expect(output.text.contains("JUMPED"))
    }

    @Test("FOR...NEXT loop counts correctly")
    func forNextLoop() throws {
        let source = """
        10 FOR I = 1 TO 5
        20 PRINT I;
        30 NEXT I
        40 END
        """
        let output = try run(source)
        #expect(output.text.contains("1"))
        #expect(output.text.contains("5"))
    }

    @Test("FOR...NEXT with STEP")
    func forNextStep() throws {
        let source = """
        10 FOR I = 0 TO 10 STEP 2
        20 PRINT I;
        30 NEXT I
        40 END
        """
        let output = try run(source)
        #expect(output.text.contains("0"))
        #expect(output.text.contains("2"))
        #expect(output.text.contains("10"))
        #expect(!output.text.contains("3"))
    }

    @Test("FOR...NEXT with negative STEP")
    func forNextNegativeStep() throws {
        let source = """
        10 FOR I = 5 TO 1 STEP -1
        20 PRINT I;
        30 NEXT I
        40 END
        """
        let output = try run(source)
        #expect(output.text.contains("5"))
        #expect(output.text.contains("1"))
    }

    @Test("GOSUB and RETURN")
    func gosubReturn() throws {
        let source = """
        10 GOSUB 100
        20 PRINT "BACK"
        30 END
        100 PRINT "SUB"
        110 RETURN
        """
        let output = try run(source)
        let lines = output.lines
        #expect(lines.count >= 2)
        #expect(lines[0] == "SUB")
        #expect(lines[1] == "BACK")
    }

    @Test("Nested GOSUB")
    func nestedGosub() throws {
        let source = """
        10 GOSUB 100
        20 PRINT "DONE"
        30 END
        100 PRINT "OUTER"
        110 GOSUB 200
        120 RETURN
        200 PRINT "INNER"
        210 RETURN
        """
        let output = try run(source)
        let lines = output.lines
        #expect(lines[0] == "OUTER")
        #expect(lines[1] == "INNER")
        #expect(lines[2] == "DONE")
    }

    @Test("ON...GOTO branches correctly")
    func onGoto() throws {
        let source = """
        10 LET X = 2
        20 ON X GOTO 100,200,300
        30 END
        100 PRINT "ONE" : END
        200 PRINT "TWO" : END
        300 PRINT "THREE" : END
        """
        let output = try run(source)
        #expect(output.lines.contains("TWO"))
        #expect(!output.text.contains("ONE"))
        #expect(!output.text.contains("THREE"))
    }

    // MARK: - Golden Path: DATA / READ / RESTORE

    @Test("DATA and READ")
    func dataAndRead() throws {
        let source = """
        10 DATA 10, 20, 30
        20 READ A
        30 READ B
        40 READ C
        50 PRINT A;B;C
        60 END
        """
        let output = try run(source)
        #expect(output.text.contains("10"))
        #expect(output.text.contains("20"))
        #expect(output.text.contains("30"))
    }

    @Test("RESTORE resets DATA pointer")
    func restoreResets() throws {
        let source = """
        10 DATA 42
        20 READ A
        30 RESTORE
        40 READ B
        50 PRINT A;B
        60 END
        """
        let output = try run(source)
        // Both reads should get 42
        let count = output.text.components(separatedBy: "42").count - 1
        #expect(count == 2)
    }

    // MARK: - Golden Path: Arrays

    @Test("DIM and array access")
    func dimAndAccess() throws {
        let source = """
        10 DIM A(5)
        20 A(1) = 42
        30 PRINT A(1)
        40 END
        """
        let output = try run(source)
        #expect(output.text.contains("42"))
    }

    @Test("2D array")
    func twoDArray() throws {
        let source = """
        10 DIM A(3,3)
        20 A(1,2) = 99
        30 PRINT A(1,2)
        40 END
        """
        let output = try run(source)
        #expect(output.text.contains("99"))
    }

    // MARK: - Golden Path: String Operations

    @Test("String concatenation")
    func stringConcatenation() throws {
        let source = """
        10 LET A$ = "HELLO" + " " + "WORLD"
        20 PRINT A$
        30 END
        """
        let output = try run(source)
        #expect(output.lines.contains("HELLO WORLD"))
    }

    @Test("LEN function")
    func lenFunction() throws {
        let source = """
        10 LET A$ = "APPLE"
        20 PRINT LEN(A$)
        30 END
        """
        let output = try run(source)
        #expect(output.text.contains("5"))
    }

    @Test("LEFT$ function")
    func leftFunction() throws {
        let source = """
        10 LET A$ = "HELLO WORLD"
        20 PRINT LEFT$(A$,5)
        30 END
        """
        let output = try run(source)
        #expect(output.text.contains("HELLO"))
    }

    @Test("RIGHT$ function")
    func rightFunction() throws {
        let source = """
        10 LET A$ = "HELLO WORLD"
        20 PRINT RIGHT$(A$,5)
        30 END
        """
        let output = try run(source)
        #expect(output.text.contains("WORLD"))
    }

    @Test("MID$ function")
    func midFunction() throws {
        let source = """
        10 LET A$ = "HELLO WORLD"
        20 PRINT MID$(A$,7,5)
        30 END
        """
        let output = try run(source)
        #expect(output.text.contains("WORLD"))
    }

    @Test("CHR$ and ASC functions")
    func chrAndAsc() throws {
        let source = """
        10 PRINT CHR$(65)
        20 PRINT ASC("A")
        30 END
        """
        let output = try run(source)
        #expect(output.text.contains("A"))
        #expect(output.text.contains("65"))
    }

    @Test("STR$ and VAL functions")
    func strAndVal() throws {
        let source = """
        10 LET A$ = STR$(42)
        20 LET B = VAL("123")
        30 PRINT A$;B
        40 END
        """
        let output = try run(source)
        #expect(output.text.contains("42"))
        #expect(output.text.contains("123"))
    }

    // MARK: - Golden Path: Math Functions

    @Test("INT function truncates toward negative infinity")
    func intFunction() throws {
        let source = """
        10 PRINT INT(3.7)
        20 PRINT INT(-3.7)
        30 END
        """
        let output = try run(source)
        #expect(output.text.contains("3"))
        #expect(output.text.contains("-4"))
    }

    @Test("ABS function")
    func absFunction() throws {
        let source = """
        10 PRINT ABS(-42)
        20 END
        """
        let output = try run(source)
        #expect(output.text.contains("42"))
    }

    @Test("SQR function")
    func sqrFunction() throws {
        let source = """
        10 PRINT SQR(144)
        20 END
        """
        let output = try run(source)
        #expect(output.text.contains("12"))
    }

    @Test("SGN function")
    func sgnFunction() throws {
        let source = """
        10 PRINT SGN(-5);SGN(0);SGN(5)
        20 END
        """
        let output = try run(source)
        #expect(output.text.contains("-1"))
        #expect(output.text.contains("0"))
        #expect(output.text.contains("1"))
    }

    @Test("RND function returns value in [0,1)")
    func rndFunction() throws {
        let source = """
        10 LET R = RND(1)
        20 IF R >= 0 AND R < 1 THEN PRINT "OK"
        30 END
        """
        let output = try run(source)
        #expect(output.text.contains("OK"))
    }

    @Test("Trigonometric functions")
    func trigFunctions() throws {
        // SIN(0) = 0, COS(0) = 1
        let source = """
        10 PRINT SIN(0)
        20 PRINT COS(0)
        30 END
        """
        let output = try run(source)
        #expect(output.text.contains("0"))
        #expect(output.text.contains("1"))
    }

    // MARK: - Golden Path: INPUT

    @Test("INPUT reads user input")
    func inputReads() throws {
        let source = """
        10 INPUT "NAME? ";N$
        20 PRINT "HELLO ";N$
        30 END
        """
        let output = try run(source, input: ["APPLE"])
        #expect(output.text.contains("HELLO"))
        #expect(output.text.contains("APPLE"))
    }

    // MARK: - Golden Path: Screen Commands

    @Test("HOME clears output")
    func homeClears() throws {
        let source = """
        10 PRINT "BEFORE"
        20 HOME
        30 PRINT "AFTER"
        40 END
        """
        let output = try run(source)
        // HOME clears the CapturedOutput, so "BEFORE" should be gone
        #expect(!output.text.contains("BEFORE"))
        #expect(output.text.contains("AFTER"))
    }

    // MARK: - Golden Path: DEF FN

    @Test("User-defined function")
    func userDefinedFunction() throws {
        let source = """
        10 DEF FN SQUARE(X) = X * X
        20 PRINT FN SQUARE(7)
        30 END
        """
        let output = try run(source)
        #expect(output.text.contains("49"))
    }

    // MARK: - Golden Path: Logical Operators

    @Test("AND operator")
    func andOperator() throws {
        let source = """
        10 IF 1 AND 1 THEN PRINT "YES"
        20 IF 1 AND 0 THEN PRINT "NO"
        30 END
        """
        let output = try run(source)
        #expect(output.text.contains("YES"))
        #expect(!output.text.contains("NO"))
    }

    @Test("OR operator")
    func orOperator() throws {
        let source = """
        10 IF 0 OR 1 THEN PRINT "YES"
        20 IF 0 OR 0 THEN PRINT "NO"
        30 END
        """
        let output = try run(source)
        #expect(output.text.contains("YES"))
        #expect(!output.text.contains("NO"))
    }

    @Test("NOT operator")
    func notOperator() throws {
        let source = """
        10 IF NOT 0 THEN PRINT "YES"
        20 IF NOT 1 THEN PRINT "NO"
        30 END
        """
        let output = try run(source)
        #expect(output.text.contains("YES"))
        #expect(!output.text.contains("NO"))
    }

    // MARK: - Integration: Birthday Program

    @Test("Runs the complete Apple birthday program")
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
        let output = try run(source)

        // Verify the song was sung
        #expect(output.text.contains("HAPPY BIRTHDAY TO YOU..."))
        #expect(output.text.contains("HAPPY BIRTHDAY DEAR APPLE..."))
        #expect(output.text.contains("HAPPY BIRTHDAY TO YOU!"))

        // Verify the counting happened
        #expect(output.text.contains("ARE YOU 1?"))
        #expect(output.text.contains("...NOOOO!"))
        #expect(output.text.contains("ARE YOU 50?"))
        #expect(output.text.contains("...YAAAAY!!!"))

        // Verify the finale
        #expect(output.text.contains("APPLE IS 50 YEARS OLD TODAY!"))
        #expect(output.text.contains("NOW GO EAT SOME CAKE!"))
    }

    // MARK: - Edge Cases: Runtime Errors

    @Test("Division by zero throws error")
    func divisionByZero() throws {
        let source = """
        10 PRINT 1/0
        20 END
        """
        #expect(throws: BASICError.divisionByZero) {
            try run(source)
        }
    }

    @Test("GOTO undefined line throws error")
    func gotoUndefined() throws {
        let source = """
        10 GOTO 999
        20 END
        """
        #expect(throws: BASICError.self) {
            try run(source)
        }
    }

    @Test("RETURN without GOSUB throws error")
    func returnWithoutGosub() throws {
        let source = """
        10 RETURN
        20 END
        """
        #expect(throws: BASICError.returnWithoutGosub) {
            try run(source)
        }
    }

    @Test("NEXT without FOR throws error")
    func nextWithoutFor() throws {
        let source = """
        10 NEXT I
        20 END
        """
        #expect(throws: BASICError.self) {
            try run(source)
        }
    }

    @Test("READ past DATA throws error")
    func readPastData() throws {
        let source = """
        10 DATA 1
        20 READ A
        30 READ B
        40 END
        """
        #expect(throws: BASICError.outOfData) {
            try run(source)
        }
    }

    @Test("Bad array subscript throws error")
    func badSubscript() throws {
        let source = """
        10 DIM A(5)
        20 A(10) = 1
        30 END
        """
        #expect(throws: BASICError.self) {
            try run(source)
        }
    }

    @Test("Re-DIM array throws error")
    func reDim() throws {
        let source = """
        10 DIM A(5)
        20 DIM A(10)
        30 END
        """
        #expect(throws: BASICError.self) {
            try run(source)
        }
    }

    // MARK: - Stress Tests

    @Test("Infinite loop is caught by step limit")
    func infiniteLoopProtection() throws {
        let source = """
        10 GOTO 10
        """
        #expect(throws: BASICError.self) {
            try run(source, maxSteps: 1000)
        }
    }

    @Test("Deep GOSUB nesting respects stack limit")
    func deepGosubNesting() throws {
        // Build a program that recurses deeply
        var lines: [String] = []
        lines.append("10 GOSUB 20")
        lines.append("15 END")
        lines.append("20 GOSUB 20")  // Infinite recursion
        lines.append("30 RETURN")
        let source = lines.joined(separator: "\n")
        #expect(throws: BASICError.self) {
            try run(source, maxSteps: 10_000)
        }
    }

    @Test("Large FOR loop completes")
    func largeForLoop() throws {
        let source = """
        10 LET S = 0
        20 FOR I = 1 TO 1000
        30 LET S = S + I
        40 NEXT I
        50 PRINT S
        60 END
        """
        let output = try run(source)
        // Sum of 1 to 1000 = 500500
        #expect(output.text.contains("500500"))
    }

    // MARK: - Comparison Operators

    @Test("All comparison operators work",
          arguments: [
            ("10 IF 5 > 3 THEN PRINT \"YES\"\n20 END", true),
            ("10 IF 3 > 5 THEN PRINT \"YES\"\n20 END", false),
            ("10 IF 3 < 5 THEN PRINT \"YES\"\n20 END", true),
            ("10 IF 5 < 3 THEN PRINT \"YES\"\n20 END", false),
            ("10 IF 5 >= 5 THEN PRINT \"YES\"\n20 END", true),
            ("10 IF 4 >= 5 THEN PRINT \"YES\"\n20 END", false),
            ("10 IF 5 <= 5 THEN PRINT \"YES\"\n20 END", true),
            ("10 IF 6 <= 5 THEN PRINT \"YES\"\n20 END", false),
            ("10 IF 5 <> 3 THEN PRINT \"YES\"\n20 END", true),
            ("10 IF 5 <> 5 THEN PRINT \"YES\"\n20 END", false),
          ])
    func comparisonOperators(source: String, expectedYes: Bool) throws {
        let output = try run(source)
        if expectedYes {
            #expect(output.text.contains("YES"))
        } else {
            #expect(!output.text.contains("YES"))
        }
    }

    // MARK: - PRINT Formatting

    @Test("PRINT expression with semicolons concatenates")
    func printExprSemicolon() throws {
        let source = """
        10 LET A = 1
        20 PRINT "ARE YOU ";A;"?"
        30 END
        """
        let output = try run(source)
        #expect(output.text.contains("ARE YOU "))
        #expect(output.text.contains("?"))
    }

    @Test("Trailing semicolon suppresses newline")
    func trailingSemicolon() throws {
        let source = """
        10 PRINT "A";
        20 PRINT "B"
        30 END
        """
        let output = try run(source)
        #expect(output.text.contains("AB"))
    }
}
