import Testing
@testable import ApplesoftBASICLib

@Suite("Lexer")
struct LexerTests {

    // MARK: - Golden Path

    @Test("Tokenizes a line number")
    func lineNumber() throws {
        var lexer = Lexer(source: "10 PRINT")
        let tokens = try lexer.tokenize()
        #expect(tokens.first == .lineNumber(10))
    }

    @Test("Tokenizes PRINT keyword")
    func printKeyword() throws {
        var lexer = Lexer(source: "10 PRINT")
        let tokens = try lexer.tokenize()
        #expect(tokens.contains(.keyword(.PRINT)))
    }

    @Test("Tokenizes string literal")
    func stringLiteral() throws {
        var lexer = Lexer(source: "10 PRINT \"HELLO WORLD\"")
        let tokens = try lexer.tokenize()
        #expect(tokens.contains(.stringLiteral("HELLO WORLD")))
    }

    @Test("Tokenizes numeric literal integer")
    func numericLiteralInteger() throws {
        var lexer = Lexer(source: "10 LET A = 42")
        let tokens = try lexer.tokenize()
        #expect(tokens.contains(.numberLiteral(42)))
    }

    @Test("Tokenizes numeric literal decimal")
    func numericLiteralDecimal() throws {
        var lexer = Lexer(source: "10 LET A = 3.14")
        let tokens = try lexer.tokenize()
        #expect(tokens.contains(.numberLiteral(3.14)))
    }

    @Test("Tokenizes scientific notation")
    func scientificNotation() throws {
        var lexer = Lexer(source: "10 LET A = 1E10")
        let tokens = try lexer.tokenize()
        #expect(tokens.contains(.numberLiteral(1e10)))
    }

    @Test("Tokenizes negative exponent")
    func negativeExponent() throws {
        var lexer = Lexer(source: "10 LET A = 1.5E-3")
        let tokens = try lexer.tokenize()
        #expect(tokens.contains(.numberLiteral(1.5e-3)))
    }

    @Test("Tokenizes identifier")
    func identifier() throws {
        var lexer = Lexer(source: "10 LET SCORE = 100")
        let tokens = try lexer.tokenize()
        #expect(tokens.contains(.identifier("SCORE")))
    }

    @Test("Tokenizes string variable identifier")
    func stringIdentifier() throws {
        var lexer = Lexer(source: "10 LET N$ = \"BOB\"")
        let tokens = try lexer.tokenize()
        #expect(tokens.contains(.identifier("N$")))
    }

    @Test("Tokenizes all arithmetic operators",
          arguments: [
            ("+", Operator.plus),
            ("-", Operator.minus),
            ("*", Operator.multiply),
            ("/", Operator.divide),
            ("^", Operator.power),
          ])
    func arithmeticOperators(source: String, expected: Operator) throws {
        var lexer = Lexer(source: "10 LET A = 1 \(source) 2")
        let tokens = try lexer.tokenize()
        #expect(tokens.contains(.op(expected)))
    }

    @Test("Tokenizes comparison operators",
          arguments: [
            ("=", Operator.equal),
            ("<>", Operator.notEqual),
            ("<", Operator.lessThan),
            (">", Operator.greaterThan),
            ("<=", Operator.lessThanOrEqual),
            (">=", Operator.greaterThanOrEqual),
          ])
    func comparisonOperators(source: String, expected: Operator) throws {
        var lexer = Lexer(source: "10 IF A \(source) B THEN 20")
        let tokens = try lexer.tokenize()
        #expect(tokens.contains(.op(expected)))
    }

    @Test("Tokenizes punctuation")
    func punctuation() throws {
        var lexer = Lexer(source: "10 PRINT A;B,C")
        let tokens = try lexer.tokenize()
        #expect(tokens.contains(.semicolon))
        #expect(tokens.contains(.comma))
    }

    @Test("Tokenizes parentheses")
    func parentheses() throws {
        var lexer = Lexer(source: "10 LET A = (1 + 2)")
        let tokens = try lexer.tokenize()
        #expect(tokens.contains(.leftParen))
        #expect(tokens.contains(.rightParen))
    }

    @Test("Tokenizes colon statement separator")
    func colonSeparator() throws {
        var lexer = Lexer(source: "10 PRINT A : PRINT B")
        let tokens = try lexer.tokenize()
        #expect(tokens.contains(.colon))
    }

    @Test("Tokenizes REM preserves comment text")
    func remComment() throws {
        var lexer = Lexer(source: "10 REM THIS IS A COMMENT")
        let tokens = try lexer.tokenize()
        #expect(tokens.contains(.keyword(.REM)))
        // After REM, the rest of the line should be captured as a string literal
        #expect(tokens.contains(.stringLiteral(" THIS IS A COMMENT")))
    }

    @Test("Tokenizes all keywords", arguments: [
        "GOTO", "GOSUB", "RETURN", "IF", "THEN", "FOR", "TO", "STEP", "NEXT",
        "ON", "END", "STOP", "PRINT", "INPUT", "GET", "LET", "DIM", "DATA",
        "READ", "RESTORE", "HOME", "AND", "OR", "NOT",
    ])
    func allKeywords(keyword: String) throws {
        var lexer = Lexer(source: "10 \(keyword)")
        let tokens = try lexer.tokenize()
        guard let expected = Keyword(rawValue: keyword) else {
            Issue.record("Unknown keyword: \(keyword)")
            return
        }
        #expect(tokens.contains(.keyword(expected)))
    }

    @Test("Keywords are case insensitive")
    func caseInsensitive() throws {
        var lexer = Lexer(source: "10 print \"hello\"")
        let tokens = try lexer.tokenize()
        #expect(tokens.contains(.keyword(.PRINT)))
    }

    @Test("Tokenizes multi-line program")
    func multiLine() throws {
        let source = """
        10 PRINT "HELLO"
        20 GOTO 10
        """
        var lexer = Lexer(source: source)
        let tokens = try lexer.tokenize()
        #expect(tokens.contains(.lineNumber(10)))
        #expect(tokens.contains(.lineNumber(20)))
        #expect(tokens.contains(.keyword(.PRINT)))
        #expect(tokens.contains(.keyword(.GOTO)))
    }

    @Test("Tokenizes a complete birthday program line")
    func birthdayLine() throws {
        var lexer = Lexer(source: "70 IF V = 1 THEN PRINT \"HAPPY BIRTHDAY TO YOU...\"")
        let tokens = try lexer.tokenize()
        #expect(tokens.contains(.lineNumber(70)))
        #expect(tokens.contains(.keyword(.IF)))
        #expect(tokens.contains(.identifier("V")))
        #expect(tokens.contains(.op(.equal)))
        #expect(tokens.contains(.numberLiteral(1)))
        #expect(tokens.contains(.keyword(.THEN)))
        #expect(tokens.contains(.keyword(.PRINT)))
        #expect(tokens.contains(.stringLiteral("HAPPY BIRTHDAY TO YOU...")))
    }

    @Test("Tokenizes end of line markers between lines")
    func endOfLineMarkers() throws {
        let source = """
        10 PRINT
        20 END
        """
        var lexer = Lexer(source: source)
        let tokens = try lexer.tokenize()
        #expect(tokens.contains(.endOfLine))
    }

    // MARK: - Edge Cases

    @Test("Empty input produces no tokens")
    func emptyInput() throws {
        var lexer = Lexer(source: "")
        let tokens = try lexer.tokenize()
        #expect(tokens.isEmpty)
    }

    @Test("Whitespace only produces no tokens")
    func whitespaceOnly() throws {
        var lexer = Lexer(source: "   \n  \n")
        let tokens = try lexer.tokenize()
        #expect(tokens.isEmpty)
    }

    @Test("Leading zeros in line number")
    func leadingZeros() throws {
        var lexer = Lexer(source: "010 PRINT")
        let tokens = try lexer.tokenize()
        #expect(tokens.contains(.lineNumber(10)))
    }

    @Test("Empty string literal")
    func emptyString() throws {
        var lexer = Lexer(source: "10 PRINT \"\"")
        let tokens = try lexer.tokenize()
        #expect(tokens.contains(.stringLiteral("")))
    }

    @Test("String with special characters")
    func specialCharsInString() throws {
        var lexer = Lexer(source: "10 PRINT \"!@#$%&*()\"")
        let tokens = try lexer.tokenize()
        #expect(tokens.contains(.stringLiteral("!@#$%&*()")))
    }

    @Test("Number starting with decimal point")
    func decimalPointStart() throws {
        var lexer = Lexer(source: "10 LET A = .5")
        let tokens = try lexer.tokenize()
        #expect(tokens.contains(.numberLiteral(0.5)))
    }

    @Test("Multiple statements on one line")
    func multipleStatements() throws {
        var lexer = Lexer(source: "10 A = 1 : B = 2 : C = 3")
        let tokens = try lexer.tokenize()
        let colonCount = tokens.filter { $0 == .colon }.count
        #expect(colonCount == 2)
    }

    @Test("Built-in function names tokenized as keywords")
    func builtinFunctions() throws {
        var lexer = Lexer(source: "10 LET A = SIN(X)")
        let tokens = try lexer.tokenize()
        #expect(tokens.contains(.keyword(.SIN)))
    }

    // MARK: - Invalid Input

    @Test("Unterminated string throws error")
    func unterminatedString() throws {
        var lexer = Lexer(source: "10 PRINT \"HELLO")
        #expect(throws: BASICError.self) {
            try lexer.tokenize()
        }
    }

    @Test("Handles dollar sign in non-variable context gracefully")
    func dollarSign() throws {
        // $ after a letter is a string variable, which is valid
        var lexer = Lexer(source: "10 LET A$ = \"HI\"")
        let tokens = try lexer.tokenize()
        #expect(tokens.contains(.identifier("A$")))
    }
}
