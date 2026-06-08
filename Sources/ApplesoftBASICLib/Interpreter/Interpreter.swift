import Foundation

/// Executes a parsed Applesoft BASIC program.
///
/// The interpreter walks the AST produced by the ``Parser``, maintaining
/// program state (variables, DATA pointer, call stack) and producing
/// output through the ``OutputHandler`` protocol.
// Justification: Interpreter instances are created and consumed on a single thread; mutable fields (lineIndex, environment, graphicsBuffer) are never shared across threads.
public final class Interpreter: @unchecked Sendable {
    private let program: Program
    private let output: any OutputHandler
    private let input: any InputHandler
    private let sound: any SoundHandler
    private let maxSteps: Int
    private let environment: Environment
    private let graphicsBuffer: GraphicsBuffer
    private var rng: any RandomNumberGenerator

    /// Current line index in the program's lines array.
    private var lineIndex: Int = 0

    /// Current statement index within the current line.
    private var statementIndex: Int = 0

    /// Total steps executed (for infinite loop protection).
    private var stepCount: Int = 0

    /// Current column position for PRINT tab formatting.
    private var printColumn: Int = 0

    /// Creates an interpreter for the given program.
    ///
    /// - Parameters:
    ///   - program: The parsed program to execute.
    ///   - output: Handler for PRINT output. Defaults to ``ConsoleOutput``.
    ///   - input: Handler for INPUT/GET. Defaults to ``ConsoleInput``.
    ///   - sound: Handler for BEEP/SOUND. Defaults to ``MutedSoundHandler``.
    ///   - maxSteps: Maximum execution steps before throwing
    ///     ``BASICError/stepCountExceeded(limit:)``. Defaults to 1,000,000.
    ///   - rng: Random number generator for RND(). Inject a seeded generator for deterministic tests.
    public init<RNG: RandomNumberGenerator>(
        program: Program,
        output: any OutputHandler = ConsoleOutput(),
        input: any InputHandler = ConsoleInput(),
        sound: any SoundHandler = MutedSoundHandler(),
        maxSteps: Int = 1_000_000,
        rng: inout RNG
    ) {
        self.program = program
        self.output = output
        self.input = input
        self.sound = sound
        self.maxSteps = maxSteps
        self.environment = Environment()
        self.graphicsBuffer = GraphicsBuffer()
        self.rng = rng
    }

    /// Runs the program from the first line.
    ///
    /// - Throws: ``BASICError`` if a runtime error occurs.
    public func run() throws {
        // Collect all DATA values first
        collectData()

        lineIndex = 0
        statementIndex = 0
        stepCount = 0

        while lineIndex < program.lines.count {
            stepCount += 1
            guard stepCount <= maxSteps else {
                throw BASICError.stepCountExceeded(limit: maxSteps)
            }

            let line = program.lines[lineIndex]
            guard statementIndex < line.statements.count else {
                lineIndex += 1
                statementIndex = 0
                continue
            }

            let statement = line.statements[statementIndex]
            statementIndex += 1

            let flow = try executeStatement(statement)

            switch flow {
            case .next:
                continue
            case .gotoLine(let targetLine):
                try gotoLine(targetLine)
            case .end:
                return
            }
        }
    }

    // MARK: - Flow Control

    private enum FlowControl {
        case next
        case gotoLine(Int)
        case end
    }

    private func collectData() {
        environment.dataValues.removeAll()
        for line in program.lines {
            for statement in line.statements {
                if case .data(let values) = statement {
                    environment.dataValues.append(contentsOf: values)
                }
            }
        }
    }

    private func gotoLine(_ targetLine: Int) throws {
        guard let index = program.lines.firstIndex(where: { $0.lineNumber == targetLine }) else {
            throw BASICError.undefinedLine(targetLine)
        }
        lineIndex = index
        statementIndex = 0
    }

    // MARK: - Statement Execution

    private func executeStatement(_ statement: Statement) throws -> FlowControl {
        switch statement {
        case .rem:
            return .next

        case .print(let items):
            try executePrint(items)
            return .next

        case .letStatement(let variable, let value):
            try executeAssignment(variable: variable, value: value)
            return .next

        case .goto(let target):
            let lineNum = try evaluateToInt(target)
            return .gotoLine(lineNum)

        case .gosub(let target):
            let lineNum = try evaluateToInt(target)
            guard environment.gosubStack.count < Environment.maxStackDepth else {
                throw BASICError.stackOverflow(depth: environment.gosubStack.count)
            }
            environment.gosubStack.append((lineIndex: lineIndex, statementIndex: statementIndex))
            return .gotoLine(lineNum)

        case .returnStatement:
            guard let returnAddr = environment.gosubStack.popLast() else {
                throw BASICError.returnWithoutGosub
            }
            lineIndex = returnAddr.lineIndex
            statementIndex = returnAddr.statementIndex
            return .next

        case .ifThen(let condition, let body):
            let value = try evaluateNumeric(condition)
            // In Applesoft, any nonzero value is true
            if value != 0 {
                switch body {
                case .lineNumber(let expr):
                    let lineNum = try evaluateToInt(expr)
                    return .gotoLine(lineNum)
                case .statement(let stmt):
                    return try executeStatement(stmt)
                }
            }
            return .next

        case .forStatement(let variable, let start, let end, let step):
            let startVal = try evaluateNumeric(start)
            let endVal = try evaluateNumeric(end)
            let stepVal: Double
            if let step {
                stepVal = try evaluateNumeric(step)
            } else {
                stepVal = 1.0
            }
            environment.numericVariables[variable] = startVal
            environment.forLoops[variable] = ForLoopState(
                variable: variable,
                limit: endVal,
                step: stepVal,
                lineIndex: lineIndex,
                statementIndex: statementIndex
            )
            return .next

        case .next(let variable):
            return try executeNext(variable: variable)

        case .input(let prompt, let variables):
            try executeInput(prompt: prompt, variables: variables)
            return .next

        case .get(let variable):
            try executeGet(variable: variable)
            return .next

        case .dim(let declarations):
            try executeDim(declarations)
            return .next

        case .data:
            // DATA is collected at program start, skip during execution
            return .next

        case .read(let variables):
            try executeRead(variables: variables)
            return .next

        case .restore:
            environment.dataPointer = 0
            return .next

        case .onGoto(let expr, let targets):
            let index = try evaluateToInt(expr)
            if index >= 1 && index <= targets.count {
                let targetLine = try evaluateToInt(targets[index - 1])
                return .gotoLine(targetLine)
            }
            return .next

        case .onGosub(let expr, let targets):
            let index = try evaluateToInt(expr)
            if index >= 1 && index <= targets.count {
                let targetLine = try evaluateToInt(targets[index - 1])
                guard environment.gosubStack.count < Environment.maxStackDepth else {
                    throw BASICError.stackOverflow(depth: environment.gosubStack.count)
                }
                environment.gosubStack.append((lineIndex: lineIndex, statementIndex: statementIndex))
                return .gotoLine(targetLine)
            }
            return .next

        case .defFn(let name, let parameter, let body):
            environment.userFunctions[name] = UserFunction(parameterName: parameter, body: body)
            return .next

        case .home:
            output.clearScreen()
            printColumn = 0
            return .next

        case .htab(let expr):
            let col = try evaluateToInt(expr)
            let spaces = max(0, col - 1 - printColumn)
            if spaces > 0 {
                output.print(String(repeating: " ", count: spaces))
                printColumn += spaces
            }
            return .next

        case .vtab:
            // VTAB is screen-specific — output newlines to approximate
            return .next

        case .inverse, .normal, .flash:
            // Text mode changes — no-op in terminal mode
            return .next

        case .text:
            graphicsBuffer.switchToText()
            return .next

        case .gr:
            graphicsBuffer.switchToLoRes()
            output.clearScreen()
            let rendered = GraphicsRenderer.renderLoRes(graphicsBuffer)
            output.print(rendered)
            return .next

        case .colorSet(let expr):
            let color = try evaluateToInt(expr)
            graphicsBuffer.setColor(UInt8(max(0, min(color, 15))))
            return .next

        case .plot(let xExpr, let yExpr):
            let x = try evaluateToInt(xExpr)
            let y = try evaluateToInt(yExpr)
            try graphicsBuffer.plot(x: x, y: y)
            let rendered = GraphicsRenderer.renderLoResDirty(graphicsBuffer)
            if !rendered.isEmpty { output.print(rendered) }
            graphicsBuffer.clearDirty()
            return .next

        case .hlin(let x1Expr, let x2Expr, let yExpr):
            let x1 = try evaluateToInt(x1Expr)
            let x2 = try evaluateToInt(x2Expr)
            let y = try evaluateToInt(yExpr)
            try graphicsBuffer.hlin(x1: x1, x2: x2, y: y)
            let rendered = GraphicsRenderer.renderLoResDirty(graphicsBuffer)
            if !rendered.isEmpty { output.print(rendered) }
            graphicsBuffer.clearDirty()
            return .next

        case .vlin(let y1Expr, let y2Expr, let xExpr):
            let y1 = try evaluateToInt(y1Expr)
            let y2 = try evaluateToInt(y2Expr)
            let x = try evaluateToInt(xExpr)
            try graphicsBuffer.vlin(y1: y1, y2: y2, x: x)
            let rendered = GraphicsRenderer.renderLoResDirty(graphicsBuffer)
            if !rendered.isEmpty { output.print(rendered) }
            graphicsBuffer.clearDirty()
            return .next

        case .hgr:
            graphicsBuffer.switchToHiRes()
            output.clearScreen()
            return .next

        case .hgr2:
            graphicsBuffer.switchToHiResFull()
            output.clearScreen()
            return .next

        case .hcolorSet(let expr):
            let color = try evaluateToInt(expr)
            graphicsBuffer.setHColor(UInt8(max(0, min(color, 7))))
            return .next

        case .hplot(let points):
            guard let first = points.first else { return .next }
            let x0 = try evaluateToInt(first.x)
            let y0 = try evaluateToInt(first.y)
            var prevX: Int
            var prevY: Int
            if x0 == -1 && y0 == -1 {
                // HPLOT TO — continue from last position
                prevX = graphicsBuffer.lastHPlotX
                prevY = graphicsBuffer.lastHPlotY
            } else {
                try graphicsBuffer.hplot(x: x0, y: y0)
                prevX = x0
                prevY = y0
            }
            for point in points.dropFirst() {
                let x = try evaluateToInt(point.x)
                let y = try evaluateToInt(point.y)
                try graphicsBuffer.hplotLine(x1: prevX, y1: prevY, x2: x, y2: y)
                prevX = x
                prevY = y
            }
            let rendered = GraphicsRenderer.renderHiResDirty(graphicsBuffer)
            if !rendered.isEmpty { output.print(rendered) }
            graphicsBuffer.clearDirty()
            return .next

        case .beep:
            sound.beep()
            return .next

        case .sound(let freqExpr, let durExpr):
            let freq = try evaluateNumeric(freqExpr)
            let dur = try evaluateNumeric(durExpr)
            guard freq >= 0 else { throw BASICError.illegalQuantity(freq) }
            guard dur >= 0 else { throw BASICError.illegalQuantity(dur) }
            sound.playTone(frequency: freq, duration: max(0.001, min(dur, 30)))
            return .next

        case .end, .stop:
            return .end
        }
    }

    // MARK: - PRINT

    private func executePrint(_ items: [PrintItem]) throws {
        for item in items {
            if let expr = item.expression {
                // Check for TAB and SPC
                if case .tab(let tabExpr) = expr {
                    let col = try evaluateToInt(tabExpr)
                    let spaces = max(0, col - 1 - printColumn)
                    if spaces > 0 {
                        output.print(String(repeating: " ", count: spaces))
                        printColumn += spaces
                    }
                } else if case .spc(let spcExpr) = expr {
                    let count = try evaluateToInt(spcExpr)
                    if count > 0 {
                        output.print(String(repeating: " ", count: count))
                        printColumn += count
                    }
                } else if isStringExpression(expr) {
                    let str = try evaluateString(expr)
                    // Detect BEL character for beep
                    if str.contains("\u{07}") {
                        sound.beep()
                        let cleaned = str.replacingOccurrences(of: "\u{07}", with: "")
                        if !cleaned.isEmpty {
                            output.print(cleaned)
                            printColumn += cleaned.count
                        }
                    } else {
                        output.print(str)
                        printColumn += str.count
                    }
                } else {
                    let num = try evaluateNumeric(expr)
                    let str = formatNumber(num)
                    output.print(str)
                    printColumn += str.count
                }
            }

            switch item.separator {
            case .semicolon:
                break // No spacing
            case .comma:
                // Advance to next 16-character tab stop
                let nextTab = ((printColumn / 16) + 1) * 16
                let spaces = nextTab - printColumn
                output.print(String(repeating: " ", count: spaces))
                printColumn = nextTab
            case .newline:
                output.print("\n")
                printColumn = 0
            }
        }
    }

    private func formatNumber(_ value: Double) -> String {
        BuiltInFunctions.formatNumber(value)
    }

    // MARK: - Assignment

    private func executeAssignment(variable: LValue, value: Expression) throws {
        switch variable {
        case .variable(let name):
            if name.hasSuffix("$") {
                environment.stringVariables[name] = try evaluateString(value)
            } else {
                environment.numericVariables[name] = try evaluateNumeric(value)
            }
        case .arrayElement(let name, let indices):
            let evaluatedIndices = try indices.map { try evaluateToInt($0) }
            if name.hasSuffix("$") {
                try setStringArrayElement(name: name, indices: evaluatedIndices, value: try evaluateString(value))
            } else {
                try setNumericArrayElement(name: name, indices: evaluatedIndices, value: try evaluateNumeric(value))
            }
        }
    }

    // MARK: - FOR / NEXT

    private func executeNext(variable: String?) throws -> FlowControl {
        // Find the matching FOR loop
        let loopVar: String
        if let v = variable {
            loopVar = v
        } else {
            // NEXT without variable: use the most recently opened FOR
            guard let lastLoop = environment.forLoops.values.first else {
                throw BASICError.nextWithoutFor(variable: nil)
            }
            loopVar = lastLoop.variable
        }

        guard let loop = environment.forLoops[loopVar] else {
            throw BASICError.nextWithoutFor(variable: loopVar)
        }

        guard var currentVal = environment.numericVariables[loopVar] else {
            throw BASICError.undefinedVariable(loopVar)
        }

        currentVal += loop.step
        environment.numericVariables[loopVar] = currentVal

        // Check loop condition
        let done: Bool
        if loop.step > 0 {
            done = currentVal > loop.limit
        } else if loop.step < 0 {
            done = currentVal < loop.limit
        } else {
            done = false // Step 0: infinite loop (caught by step limit)
        }

        if done {
            environment.forLoops.removeValue(forKey: loopVar)
            return .next
        } else {
            // Loop back to the statement after FOR
            lineIndex = loop.lineIndex
            statementIndex = loop.statementIndex
            return .next
        }
    }

    // MARK: - INPUT / GET

    private func executeInput(prompt: String?, variables: [LValue]) throws {
        let displayPrompt: String
        if let prompt {
            displayPrompt = prompt + "? "
        } else {
            displayPrompt = "? "
        }
        guard let response = input.readLine(prompt: displayPrompt) else {
            return
        }

        // Split response by commas for multiple variables
        let values = response.split(separator: ",", omittingEmptySubsequences: false).map {
            String($0).trimmingCharacters(in: .whitespaces)
        }

        for (i, lvalue) in variables.enumerated() {
            let valueStr = i < values.count ? values[i] : ""
            switch lvalue {
            case .variable(let name):
                if name.hasSuffix("$") {
                    environment.stringVariables[name] = valueStr
                } else {
                    environment.numericVariables[name] = Double(valueStr) ?? 0
                }
            case .arrayElement:
                break // Simplified: skip array input for now
            }
        }
    }

    private func executeGet(variable: LValue) throws {
        let char = input.getChar()
        switch variable {
        case .variable(let name):
            if name.hasSuffix("$") {
                environment.stringVariables[name] = char.map(String.init) ?? ""
            } else {
                if let char, let ascii = char.asciiValue {
                    environment.numericVariables[name] = Double(ascii)
                } else {
                    environment.numericVariables[name] = 0
                }
            }
        case .arrayElement:
            break
        }
    }

    // MARK: - DIM

    private func executeDim(_ declarations: [DimDeclaration]) throws {
        for decl in declarations {
            let dims = try decl.dimensions.map { try evaluateToInt($0) + 1 } // Applesoft DIM(10) creates 0...10

            // Validate dimensions
            for dim in dims {
                guard dim > 0 && dim <= Environment.maxArrayDimension else {
                    throw BASICError.dimensionError(decl.name)
                }
            }

            if decl.name.hasSuffix("$") {
                guard environment.stringArrays[decl.name] == nil else {
                    throw BASICError.redimensionError(decl.name)
                }
                environment.stringArrays[decl.name] = BASICStringArray(dimensions: dims)
            } else {
                guard environment.numericArrays[decl.name] == nil else {
                    throw BASICError.redimensionError(decl.name)
                }
                environment.numericArrays[decl.name] = BASICArray(dimensions: dims)
            }
        }
    }

    // MARK: - READ

    private func executeRead(variables: [LValue]) throws {
        for lvalue in variables {
            guard environment.dataPointer < environment.dataValues.count else {
                throw BASICError.outOfData
            }
            let dataVal = environment.dataValues[environment.dataPointer]
            environment.dataPointer += 1

            switch lvalue {
            case .variable(let name):
                if name.hasSuffix("$") {
                    switch dataVal {
                    case .string(let s): environment.stringVariables[name] = s
                    case .number(let n): environment.stringVariables[name] = formatNumber(n)
                    }
                } else {
                    switch dataVal {
                    case .number(let n): environment.numericVariables[name] = n
                    case .string(let s): environment.numericVariables[name] = Double(s) ?? 0
                    }
                }
            case .arrayElement:
                break // Simplified
            }
        }
    }

    // MARK: - Array Access

    private func getArrayIndex(name: String, indices: [Int], array dimensions: [Int]) throws -> Int {
        guard indices.count == dimensions.count else {
            throw BASICError.dimensionError(name)
        }
        var flatIndex = 0
        var multiplier = 1
        for i in stride(from: dimensions.count - 1, through: 0, by: -1) {
            guard indices[i] >= 0 && indices[i] < dimensions[i] else {
                throw BASICError.badSubscript(index: indices[i], bound: dimensions[i] - 1)
            }
            flatIndex += indices[i] * multiplier
            multiplier *= dimensions[i]
        }
        return flatIndex
    }

    private func setNumericArrayElement(name: String, indices: [Int], value: Double) throws {
        // Auto-DIM if not dimensioned (Applesoft creates 0..10 by default)
        if environment.numericArrays[name] == nil {
            let dims = indices.map { _ in 11 } // Default size 0..10
            environment.numericArrays[name] = BASICArray(dimensions: dims)
        }

        guard var array = environment.numericArrays[name] else {
            throw BASICError.dimensionError(name)
        }
        let index = try getArrayIndex(name: name, indices: indices, array: array.dimensions)
        array.storage[index] = value
        environment.numericArrays[name] = array
    }

    private func setStringArrayElement(name: String, indices: [Int], value: String) throws {
        if environment.stringArrays[name] == nil {
            let dims = indices.map { _ in 11 }
            environment.stringArrays[name] = BASICStringArray(dimensions: dims)
        }

        guard var array = environment.stringArrays[name] else {
            throw BASICError.dimensionError(name)
        }
        let index = try getArrayIndex(name: name, indices: indices, array: array.dimensions)
        array.storage[index] = value
        environment.stringArrays[name] = array
    }

    private func getNumericArrayElement(name: String, indices: [Int]) throws -> Double {
        if environment.numericArrays[name] == nil {
            let dims = indices.map { _ in 11 }
            environment.numericArrays[name] = BASICArray(dimensions: dims)
        }
        guard let array = environment.numericArrays[name] else {
            throw BASICError.dimensionError(name)
        }
        let index = try getArrayIndex(name: name, indices: indices, array: array.dimensions)
        return array.storage[index]
    }

    private func getStringArrayElement(name: String, indices: [Int]) throws -> String {
        if environment.stringArrays[name] == nil {
            let dims = indices.map { _ in 11 }
            environment.stringArrays[name] = BASICStringArray(dimensions: dims)
        }
        guard let array = environment.stringArrays[name] else {
            throw BASICError.dimensionError(name)
        }
        let index = try getArrayIndex(name: name, indices: indices, array: array.dimensions)
        return array.storage[index]
    }

    // MARK: - Expression Evaluation

    private func isStringExpression(_ expr: Expression) -> Bool {
        switch expr {
        case .stringLiteral:
            return true
        case .variable(let name):
            return name.hasSuffix("$")
        case .arrayAccess(let name, _):
            return name.hasSuffix("$")
        case .functionCall(let name, _):
            return name.hasSuffix("$")
        case .binary(let left, let op, _):
            if op == .plus { return isStringExpression(left) }
            return false
        default:
            return false
        }
    }

    private func evaluateToInt(_ expr: Expression) throws -> Int {
        let value = try evaluateNumeric(expr)
        return Int(value)
    }

    func evaluateNumeric(_ expr: Expression) throws -> Double {
        switch expr {
        case .numberLiteral(let value):
            return value

        case .stringLiteral:
            throw BASICError.typeMismatch(expected: "number", got: "string")

        case .variable(let name):
            if name.hasSuffix("$") {
                throw BASICError.typeMismatch(expected: "number", got: "string")
            }
            return environment.numericVariables[name] ?? 0

        case .arrayAccess(let name, let indices):
            let evaluatedIndices = try indices.map { try evaluateToInt($0) }
            if name.hasSuffix("$") {
                throw BASICError.typeMismatch(expected: "number", got: "string")
            }
            return try getNumericArrayElement(name: name, indices: evaluatedIndices)

        case .binary(let left, let op, let right):
            // Handle string comparisons (A$ = "Y", etc.)
            if isStringExpression(left) || isStringExpression(right) {
                return try evaluateStringComparison(left, op, right)
            }
            let lhs = try evaluateNumeric(left)
            let rhs = try evaluateNumeric(right)
            return try evaluateBinaryOp(lhs, op, rhs)

        case .unary(let op, let operand):
            let value = try evaluateNumeric(operand)
            switch op {
            case .negate: return -value
            case .not: return value == 0 ? 1 : 0
            }

        case .functionCall(let name, let args):
            return try evaluateFunction(name: name, args: args)

        case .userFunctionCall(let name, let argument):
            return try evaluateUserFunction(name: name, argument: argument)

        case .and(let left, let right):
            let lhs = try evaluateNumeric(left)
            let rhs = try evaluateNumeric(right)
            return (lhs != 0 && rhs != 0) ? 1 : 0

        case .or(let left, let right):
            let lhs = try evaluateNumeric(left)
            let rhs = try evaluateNumeric(right)
            return (lhs != 0 || rhs != 0) ? 1 : 0

        case .tab, .spc:
            return 0
        }
    }

    func evaluateString(_ expr: Expression) throws -> String {
        switch expr {
        case .stringLiteral(let value):
            return value

        case .variable(let name):
            if name.hasSuffix("$") {
                return environment.stringVariables[name] ?? ""
            }
            throw BASICError.typeMismatch(expected: "string", got: "number")

        case .arrayAccess(let name, let indices):
            let evaluatedIndices = try indices.map { try evaluateToInt($0) }
            if name.hasSuffix("$") {
                return try getStringArrayElement(name: name, indices: evaluatedIndices)
            }
            throw BASICError.typeMismatch(expected: "string", got: "number")

        case .binary(let left, let op, let right):
            if op == .plus {
                let lhs = try evaluateString(left)
                let rhs = try evaluateString(right)
                return lhs + rhs
            }
            // String comparison returns numeric, not string
            throw BASICError.typeMismatch(expected: "string", got: "number")

        case .functionCall(let name, let args):
            return try evaluateStringFunction(name: name, args: args)

        default:
            throw BASICError.typeMismatch(expected: "string", got: "number")
        }
    }

    private func evaluateStringComparison(_ left: Expression, _ op: Operator, _ right: Expression) throws -> Double {
        let lhs = try evaluateString(left)
        let rhs = try evaluateString(right)
        switch op {
        case .equal: return lhs == rhs ? 1 : 0
        case .notEqual: return lhs != rhs ? 1 : 0
        case .lessThan: return lhs < rhs ? 1 : 0
        case .greaterThan: return lhs > rhs ? 1 : 0
        case .lessThanOrEqual: return lhs <= rhs ? 1 : 0
        case .greaterThanOrEqual: return lhs >= rhs ? 1 : 0
        case .plus:
            throw BASICError.typeMismatch(expected: "number", got: "string")
        default:
            throw BASICError.typeMismatch(expected: "number", got: "string")
        }
    }

    private func evaluateBinaryOp(_ lhs: Double, _ op: Operator, _ rhs: Double) throws -> Double {
        switch op {
        case .plus: return lhs + rhs
        case .minus: return lhs - rhs
        case .multiply: return lhs * rhs
        case .divide:
            guard abs(rhs) > Double.ulpOfOne else {
                throw BASICError.divisionByZero
            }
            return lhs / rhs
        case .power: return pow(lhs, rhs)
        case .equal: return lhs == rhs ? 1 : 0
        case .notEqual: return lhs != rhs ? 1 : 0
        case .lessThan: return lhs < rhs ? 1 : 0
        case .greaterThan: return lhs > rhs ? 1 : 0
        case .lessThanOrEqual: return lhs <= rhs ? 1 : 0
        case .greaterThanOrEqual: return lhs >= rhs ? 1 : 0
        }
    }

    private func evaluateFunction(name: String, args: [Expression]) throws -> Double {
        // Graphics screen read functions
        switch name {
        case "SCRN":
            guard args.count == 2 else { throw BASICError.illegalQuantity(0) }
            let x = try evaluateToInt(args[0])
            let y = try evaluateToInt(args[1])
            return Double(try graphicsBuffer.scrn(x: x, y: y))
        case "HSCRN":
            guard args.count == 2 else { throw BASICError.illegalQuantity(0) }
            let x = try evaluateToInt(args[0])
            let y = try evaluateToInt(args[1])
            return Double(try graphicsBuffer.hscrn(x: x, y: y))
        default:
            break
        }

        // String functions that return numeric values
        switch name {
        case "LEN":
            let str = try evaluateString(args[0])
            return Double(str.count)
        case "ASC":
            let str = try evaluateString(args[0])
            guard let first = str.first, let ascii = first.asciiValue else {
                throw BASICError.illegalQuantity(0)
            }
            return Double(ascii)
        case "VAL":
            let str = try evaluateString(args[0])
            return Double(str.trimmingCharacters(in: .whitespaces)) ?? 0
        default:
            let evaluatedArgs = try args.map { try evaluateNumeric($0) }
            return try BuiltInFunctions.evaluateNumeric(name: name, args: evaluatedArgs, rng: &rng)
        }
    }

    private func evaluateStringFunction(name: String, args: [Expression]) throws -> String {
        switch name {
        case "LEFT$":
            let str = try evaluateString(args[0])
            let count = try evaluateNumeric(args[1])
            return try BuiltInFunctions.evaluateString(
                name: name, stringArgs: [str], numericArgs: [count]
            )
        case "RIGHT$":
            let str = try evaluateString(args[0])
            let count = try evaluateNumeric(args[1])
            return try BuiltInFunctions.evaluateString(
                name: name, stringArgs: [str], numericArgs: [count]
            )
        case "MID$":
            let str = try evaluateString(args[0])
            var numArgs: [Double] = [try evaluateNumeric(args[1])]
            if args.count > 2 {
                numArgs.append(try evaluateNumeric(args[2]))
            }
            return try BuiltInFunctions.evaluateString(
                name: name, stringArgs: [str], numericArgs: numArgs
            )
        case "CHR$":
            let code = try evaluateNumeric(args[0])
            return try BuiltInFunctions.evaluateString(
                name: name, stringArgs: [], numericArgs: [code]
            )
        case "STR$":
            let num = try evaluateNumeric(args[0])
            return try BuiltInFunctions.evaluateString(
                name: name, stringArgs: [], numericArgs: [num]
            )
        default:
            throw BASICError.undefinedVariable("FN \(name)")
        }
    }

    private func evaluateUserFunction(name: String, argument: Expression) throws -> Double {
        guard let fn = environment.userFunctions[name] else {
            throw BASICError.undefinedVariable("FN \(name)")
        }
        let argValue = try evaluateNumeric(argument)
        // Save the parameter, evaluate the body, restore
        let saved = environment.numericVariables[fn.parameterName]
        environment.numericVariables[fn.parameterName] = argValue
        let result = try evaluateNumeric(fn.body)
        if let saved {
            environment.numericVariables[fn.parameterName] = saved
        } else {
            environment.numericVariables.removeValue(forKey: fn.parameterName)
        }
        return result
    }
}
