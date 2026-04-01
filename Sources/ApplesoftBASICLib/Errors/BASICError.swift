/// All errors that the Applesoft BASIC interpreter can produce.
///
/// This is the single source of truth for all error types in the interpreter.
/// Errors map to classic Applesoft BASIC error messages for REPL display,
/// with detailed descriptions available via the ``description`` property.
public enum BASICError: Error, Sendable, Equatable {

    // MARK: - Lexer Errors

    /// An unterminated string literal was found.
    case unterminatedString(line: Int)

    /// An invalid character was encountered during tokenization.
    case invalidCharacter(Character, line: Int)

    /// A malformed number literal was found.
    case invalidNumber(String, line: Int)

    // MARK: - Parser Errors

    /// A line number was expected but not found.
    case expectedLineNumber

    /// An unexpected token was encountered during parsing.
    case unexpectedToken(String, expected: String)

    /// Input ended unexpectedly during parsing.
    case unexpectedEndOfInput

    // MARK: - Runtime Errors

    /// A variable was referenced before assignment.
    case undefinedVariable(String)

    /// A GOTO or GOSUB targeted a line that does not exist.
    case undefinedLine(Int)

    /// A type mismatch occurred (e.g., string used where number expected).
    case typeMismatch(expected: String, got: String)

    /// Division by zero was attempted.
    case divisionByZero

    /// A READ statement was executed but no DATA remains.
    case outOfData

    /// A RETURN was executed without a matching GOSUB.
    case returnWithoutGosub

    /// A NEXT was executed without a matching FOR.
    case nextWithoutFor(variable: String?)

    /// A numeric overflow occurred.
    case overflow

    /// A function received an argument outside its valid range.
    case illegalQuantity(Double)

    /// An array was used before being dimensioned, or dimensions are invalid.
    case dimensionError(String)

    /// An attempt was made to re-DIM an already-dimensioned array.
    case redimensionError(String)

    /// A memory limit was exceeded.
    case outOfMemory(String)

    /// An expression exceeded the maximum nesting depth.
    case formulaTooComplex

    /// A string exceeded the maximum length (255 characters in Applesoft).
    case stringTooLong

    /// An array subscript was out of bounds.
    case badSubscript(index: Int, bound: Int)

    /// The program exceeded the maximum step count (infinite loop protection).
    case stepCountExceeded(limit: Int)

    /// The GOSUB call stack exceeded the maximum depth.
    case stackOverflow(depth: Int)

    // MARK: - I/O Errors

    /// The user pressed Ctrl+C to interrupt execution.
    case breakInterrupt
}

extension BASICError: CustomStringConvertible {

    /// Applesoft-style terse error message for REPL display.
    public var applesoftMessage: String {
        switch self {
        case .unterminatedString: return "?SYNTAX ERROR"
        case .invalidCharacter: return "?SYNTAX ERROR"
        case .invalidNumber: return "?SYNTAX ERROR"
        case .expectedLineNumber: return "?SYNTAX ERROR"
        case .unexpectedToken: return "?SYNTAX ERROR"
        case .unexpectedEndOfInput: return "?SYNTAX ERROR"
        case .undefinedVariable: return "?UNDEF'D FUNCTION ERROR"
        case .undefinedLine: return "?UNDEF'D STATEMENT ERROR"
        case .typeMismatch: return "?TYPE MISMATCH ERROR"
        case .divisionByZero: return "?DIVISION BY ZERO ERROR"
        case .outOfData: return "?OUT OF DATA ERROR"
        case .returnWithoutGosub: return "?RETURN WITHOUT GOSUB ERROR"
        case .nextWithoutFor: return "?NEXT WITHOUT FOR ERROR"
        case .overflow: return "?OVERFLOW ERROR"
        case .illegalQuantity: return "?ILLEGAL QUANTITY ERROR"
        case .dimensionError: return "?BAD SUBSCRIPT ERROR"
        case .redimensionError: return "?REDIM'D ARRAY ERROR"
        case .outOfMemory: return "?OUT OF MEMORY ERROR"
        case .formulaTooComplex: return "?FORMULA TOO COMPLEX ERROR"
        case .stringTooLong: return "?STRING TOO LONG ERROR"
        case .badSubscript: return "?BAD SUBSCRIPT ERROR"
        case .stepCountExceeded: return "?BREAK"
        case .stackOverflow: return "?OUT OF MEMORY ERROR"
        case .breakInterrupt: return "?BREAK"
        }
    }

    /// Detailed error description for programmatic use.
    public var description: String {
        switch self {
        case .unterminatedString(let line):
            return "Unterminated string literal at line \(line)"
        case .invalidCharacter(let char, let line):
            return "Invalid character '\(char)' at line \(line)"
        case .invalidNumber(let text, let line):
            return "Invalid number '\(text)' at line \(line)"
        case .expectedLineNumber:
            return "Expected a line number"
        case .unexpectedToken(let token, let expected):
            return "Unexpected token '\(token)', expected \(expected)"
        case .unexpectedEndOfInput:
            return "Unexpected end of input"
        case .undefinedVariable(let name):
            return "Undefined variable '\(name)'"
        case .undefinedLine(let line):
            return "Undefined line \(line)"
        case .typeMismatch(let expected, let got):
            return "Type mismatch: expected \(expected), got \(got)"
        case .divisionByZero:
            return "Division by zero"
        case .outOfData:
            return "Out of DATA"
        case .returnWithoutGosub:
            return "RETURN without GOSUB"
        case .nextWithoutFor(let variable):
            if let variable {
                return "NEXT \(variable) without FOR"
            }
            return "NEXT without FOR"
        case .overflow:
            return "Numeric overflow"
        case .illegalQuantity(let value):
            return "Illegal quantity: \(value)"
        case .dimensionError(let name):
            return "Bad dimension for array '\(name)'"
        case .redimensionError(let name):
            return "Array '\(name)' already dimensioned"
        case .outOfMemory(let context):
            return "Out of memory: \(context)"
        case .formulaTooComplex:
            return "Formula too complex (expression nesting limit exceeded)"
        case .stringTooLong:
            return "String too long (max 255 characters)"
        case .badSubscript(let index, let bound):
            return "Bad subscript: index \(index) out of bounds (0...\(bound))"
        case .stepCountExceeded(let limit):
            return "Execution exceeded \(limit) steps (possible infinite loop)"
        case .stackOverflow(let depth):
            return "Stack overflow at depth \(depth)"
        case .breakInterrupt:
            return "Program interrupted by user"
        }
    }
}
