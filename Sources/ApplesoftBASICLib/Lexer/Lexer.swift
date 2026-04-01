/// Tokenizes Applesoft BASIC source code into a stream of tokens.
///
/// The lexer handles line numbers, keywords, identifiers, string literals,
/// numeric literals, operators, and punctuation. Keywords are case-insensitive
/// as in original Applesoft BASIC.
public struct Lexer: Sendable {
    private let source: String
    private var characters: [Character]
    private var position: Int
    private var currentLine: Int

    /// Creates a lexer for the given source code.
    ///
    /// - Parameter source: The Applesoft BASIC source code to tokenize.
    public init(source: String) {
        self.source = source
        self.characters = Array(source)
        self.position = 0
        self.currentLine = 0
    }

    /// Tokenizes the source code into an array of tokens.
    ///
    /// - Returns: An array of tokens representing the source code.
    /// - Throws: ``BASICError`` if the source contains invalid syntax.
    public mutating func tokenize() throws -> [Token] {
        var tokens: [Token] = []
        let maxTokens = 100_000

        while position < characters.count {
            guard tokens.count < maxTokens else {
                throw BASICError.outOfMemory("Token limit exceeded")
            }

            skipWhitespace()

            guard position < characters.count else { break }

            let char = characters[position]

            // Newline: end of line
            if char == "\n" || char == "\r" {
                if !tokens.isEmpty {
                    let last = tokens.last
                    if last != .endOfLine {
                        tokens.append(.endOfLine)
                    }
                }
                position += 1
                if char == "\r" && position < characters.count && characters[position] == "\n" {
                    position += 1
                }
                currentLine += 1
                continue
            }

            // Line number at start of line (after newline or at beginning)
            if char.isNumber && isAtLineStart(tokens: tokens) {
                let number = try readLineNumber()
                tokens.append(.lineNumber(number))
                currentLine = number
                continue
            }

            // String literal
            if char == "\"" {
                let string = try readStringLiteral()
                tokens.append(.stringLiteral(string))
                continue
            }

            // Number (digit or leading decimal point)
            if char.isNumber || (char == "." && position + 1 < characters.count && characters[position + 1].isNumber) {
                let number = try readNumber()
                tokens.append(.numberLiteral(number))
                continue
            }

            // Operators and punctuation
            if let token = try readOperatorOrPunctuation() {
                tokens.append(token)
                continue
            }

            // Identifiers and keywords
            if char.isLetter {
                let (identTokens) = try readIdentifierOrKeyword()
                tokens.append(contentsOf: identTokens)
                continue
            }

            // Question mark is shorthand for PRINT
            if char == "?" {
                tokens.append(.keyword(.PRINT))
                position += 1
                continue
            }

            throw BASICError.invalidCharacter(char, line: currentLine)
        }

        // Ensure we end with endOfLine if there are tokens
        if !tokens.isEmpty && tokens.last != .endOfLine {
            tokens.append(.endOfLine)
        }

        return tokens
    }

    // MARK: - Private Helpers

    private func isAtLineStart(tokens: [Token]) -> Bool {
        guard let last = tokens.last else { return true }
        return last == .endOfLine
    }

    private mutating func skipWhitespace() {
        while position < characters.count && characters[position] == " " || (position < characters.count && characters[position] == "\t") {
            position += 1
        }
    }

    private mutating func readLineNumber() throws -> Int {
        var numStr = ""
        while position < characters.count && characters[position].isNumber {
            numStr.append(characters[position])
            position += 1
        }
        guard let number = Int(numStr) else {
            throw BASICError.invalidNumber(numStr, line: currentLine)
        }
        return number
    }

    private mutating func readStringLiteral() throws -> String {
        position += 1 // skip opening quote
        var result = ""
        while position < characters.count && characters[position] != "\"" {
            let char = characters[position]
            if char == "\n" || char == "\r" {
                // Applesoft allows unterminated strings to end at EOL
                // but we'll treat this as an error for correctness
                throw BASICError.unterminatedString(line: currentLine)
            }
            result.append(char)
            position += 1
        }
        guard position < characters.count else {
            throw BASICError.unterminatedString(line: currentLine)
        }
        position += 1 // skip closing quote
        return result
    }

    private mutating func readNumber() throws -> Double {
        var numStr = ""

        // Integer part
        while position < characters.count && characters[position].isNumber {
            numStr.append(characters[position])
            position += 1
        }

        // Decimal part
        if position < characters.count && characters[position] == "." {
            numStr.append(".")
            position += 1
            while position < characters.count && characters[position].isNumber {
                numStr.append(characters[position])
                position += 1
            }
        }

        // Exponent part (E or e)
        if position < characters.count && (characters[position] == "E" || characters[position] == "e") {
            numStr.append("E")
            position += 1
            if position < characters.count && (characters[position] == "+" || characters[position] == "-") {
                numStr.append(characters[position])
                position += 1
            }
            while position < characters.count && characters[position].isNumber {
                numStr.append(characters[position])
                position += 1
            }
        }

        guard let value = Double(numStr) else {
            throw BASICError.invalidNumber(numStr, line: currentLine)
        }
        return value
    }

    private mutating func readOperatorOrPunctuation() throws -> Token? {
        let char = characters[position]

        switch char {
        case "+":
            position += 1
            return .op(.plus)
        case "-":
            position += 1
            return .op(.minus)
        case "*":
            position += 1
            return .op(.multiply)
        case "/":
            position += 1
            return .op(.divide)
        case "^":
            position += 1
            return .op(.power)
        case "=":
            position += 1
            return .op(.equal)
        case "<":
            position += 1
            if position < characters.count {
                if characters[position] == ">" {
                    position += 1
                    return .op(.notEqual)
                } else if characters[position] == "=" {
                    position += 1
                    return .op(.lessThanOrEqual)
                }
            }
            return .op(.lessThan)
        case ">":
            position += 1
            if position < characters.count && characters[position] == "=" {
                position += 1
                return .op(.greaterThanOrEqual)
            }
            return .op(.greaterThan)
        case ",":
            position += 1
            return .comma
        case ";":
            position += 1
            return .semicolon
        case ":":
            position += 1
            return .colon
        case "(":
            position += 1
            return .leftParen
        case ")":
            position += 1
            return .rightParen
        default:
            return nil
        }
    }

    private mutating func readIdentifierOrKeyword() throws -> [Token] {
        var word = ""
        while position < characters.count && (characters[position].isLetter || characters[position].isNumber) {
            word.append(characters[position])
            position += 1
        }

        // Check for $ suffix (string variable)
        let isStringVar = position < characters.count && characters[position] == "$"
        if isStringVar {
            word.append("$")
            position += 1
        }

        let upper = word.uppercased()

        // Handle REM specially — rest of line is comment text
        if upper == "REM" {
            var comment = ""
            while position < characters.count && characters[position] != "\n" && characters[position] != "\r" {
                comment.append(characters[position])
                position += 1
            }
            return [.keyword(.REM), .stringLiteral(comment)]
        }

        // Handle string function keywords: LEFT$, RIGHT$, MID$, CHR$, STR$
        let baseWord = isStringVar ? String(upper.dropLast()) : upper

        // Check for keyword match
        if let keyword = Keyword(rawValue: baseWord) {
            // String functions that end with $ in source
            if isStringVar {
                // This is a string function like LEFT$, RIGHT$, etc.
                return [.keyword(keyword)]
            }
            return [.keyword(keyword)]
        }

        // It's an identifier (variable name)
        return [.identifier(upper + (isStringVar ? "" : ""))]
    }
}
