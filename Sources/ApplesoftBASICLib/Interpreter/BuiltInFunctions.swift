import Foundation

/// Built-in functions for the Applesoft BASIC interpreter.
enum BuiltInFunctions {

    /// Evaluates a built-in numeric function.
    ///
    /// - Parameters:
    ///   - name: The function name (e.g., "SIN", "ABS").
    ///   - args: The evaluated arguments.
    ///   - rng: Random number generator for RND.
    /// - Returns: The result of the function call.
    /// - Throws: ``BASICError`` if the function call is invalid.
    static func evaluateNumeric(
        name: String,
        args: [Double],
        rng: inout any RandomNumberGenerator
    ) throws -> Double {
        guard let firstArg = args.first else {
            throw BASICError.illegalQuantity(0)
        }

        switch name {
        case "ABS":
            return abs(firstArg)
        case "INT":
            return floor(firstArg)
        case "SQR":
            guard firstArg >= 0 else {
                throw BASICError.illegalQuantity(firstArg)
            }
            return sqrt(firstArg)
        case "SGN":
            if firstArg > 0 { return 1 }
            if firstArg < 0 { return -1 }
            return 0
        case "SIN":
            return sin(firstArg)
        case "COS":
            return cos(firstArg)
        case "TAN":
            return tan(firstArg)
        case "ATN":
            return atan(firstArg)
        case "LOG":
            guard firstArg > 0 else {
                throw BASICError.illegalQuantity(firstArg)
            }
            return log(firstArg)
        case "EXP":
            return exp(firstArg)
        case "RND":
            if firstArg > 0 {
                return Double.random(in: 0.0..<1.0, using: &rng)
            } else if firstArg < 0 {
                // Negative: seed-based (deterministic in original Applesoft)
                return Double.random(in: 0.0..<1.0, using: &rng)
            } else {
                // Zero: repeat last random number (we'll just generate a new one)
                return Double.random(in: 0.0..<1.0, using: &rng)
            }
        case "PEEK":
            // Not implemented — return 0
            return 0
        case "FRE":
            // Not implemented — return a large number
            return 32768
        case "POS":
            // Not implemented — return 0
            return 0
        case "ASC":
            // This is actually handled separately for strings
            throw BASICError.typeMismatch(expected: "string", got: "number")
        case "LEN":
            throw BASICError.typeMismatch(expected: "string", got: "number")
        case "VAL":
            throw BASICError.typeMismatch(expected: "string", got: "number")
        default:
            throw BASICError.undefinedVariable("FN \(name)")
        }
    }

    /// Evaluates a built-in string function.
    ///
    /// - Parameters:
    ///   - name: The function name (e.g., "LEFT$", "CHR$").
    ///   - stringArgs: String arguments.
    ///   - numericArgs: Numeric arguments.
    /// - Returns: The result of the function call.
    /// - Throws: ``BASICError`` if the function call is invalid.
    static func evaluateString(
        name: String,
        stringArgs: [String],
        numericArgs: [Double]
    ) throws -> String {
        switch name {
        case "LEFT$":
            guard let str = stringArgs.first else {
                throw BASICError.typeMismatch(expected: "string", got: "number")
            }
            guard let count = numericArgs.first else {
                throw BASICError.illegalQuantity(0)
            }
            let n = Int(count)
            guard n >= 0 else {
                throw BASICError.illegalQuantity(count)
            }
            let endIndex = min(n, str.count)
            return String(str.prefix(endIndex))

        case "RIGHT$":
            guard let str = stringArgs.first else {
                throw BASICError.typeMismatch(expected: "string", got: "number")
            }
            guard let count = numericArgs.first else {
                throw BASICError.illegalQuantity(0)
            }
            let n = Int(count)
            guard n >= 0 else {
                throw BASICError.illegalQuantity(count)
            }
            let startIndex = max(0, str.count - n)
            return String(str.suffix(str.count - startIndex))

        case "MID$":
            guard let str = stringArgs.first else {
                throw BASICError.typeMismatch(expected: "string", got: "number")
            }
            guard numericArgs.count >= 1 else {
                throw BASICError.illegalQuantity(0)
            }
            let start = Int(numericArgs[0])
            guard start >= 1 else {
                throw BASICError.illegalQuantity(numericArgs[0])
            }
            let adjustedStart = start - 1 // BASIC is 1-indexed
            if numericArgs.count >= 2 {
                let length = Int(numericArgs[1])
                let endPos = min(adjustedStart + length, str.count)
                if adjustedStart >= str.count { return "" }
                let startIdx = str.index(str.startIndex, offsetBy: adjustedStart)
                let endIdx = str.index(str.startIndex, offsetBy: endPos)
                return String(str[startIdx..<endIdx])
            } else {
                // MID$ with 2 args: from start to end
                if adjustedStart >= str.count { return "" }
                let startIdx = str.index(str.startIndex, offsetBy: adjustedStart)
                return String(str[startIdx...])
            }

        case "CHR$":
            guard let code = numericArgs.first else {
                throw BASICError.illegalQuantity(0)
            }
            let intCode = Int(code)
            guard intCode >= 0 && intCode <= 127 else {
                throw BASICError.illegalQuantity(code)
            }
            guard let scalar = Unicode.Scalar(intCode) else {
                throw BASICError.illegalQuantity(code)
            }
            return String(Character(scalar))

        case "STR$":
            guard let num = numericArgs.first else {
                throw BASICError.illegalQuantity(0)
            }
            return formatNumber(num)

        default:
            throw BASICError.undefinedVariable("FN \(name)")
        }
    }

    /// Formats a number for PRINT output, matching Applesoft conventions.
    static func formatNumber(_ value: Double) -> String {
        if value == floor(value) && abs(value) < 1e15 {
            // Integer: no decimal point
            return String(Int(value))
        }
        // Floating point
        return String(value)
    }
}
