import Foundation
import Synchronization

/// Executes a parsed Applesoft BASIC program.
///
/// The interpreter walks the AST produced by the ``Parser``, maintaining
/// program state (variables, DATA pointer, call stack) and producing
/// output through the ``OutputHandler`` protocol.
public final class Interpreter: Sendable {
    private let program: Program
    private let output: any OutputHandler
    private let input: any InputHandler
    private let sound: any SoundHandler
    private let maxSteps: Int
    private let environment: Environment
    private let graphicsBuffer: GraphicsBuffer

    /// Mutable execution state, protected by a Mutex.
    private struct RunState: Sendable {
        /// Current line index in the program's lines array.
        var lineIndex: Int = 0
        /// Current statement index within the current line.
        var statementIndex: Int = 0
        /// Total steps executed (for infinite loop protection).
        var stepCount: Int = 0
        /// Current column position for PRINT tab formatting.
        var printColumn: Int = 0
        /// Random number generator for RND().
        var rng: any RandomNumberGenerator & Sendable
    }

    private let _state: Mutex<RunState>

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
    public init<RNG: RandomNumberGenerator & Sendable>(
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
        self._state = Mutex(RunState(rng: rng))
    }

    /// Runs the program from the first line.
    ///
    /// - Throws: ``BASICError`` if a runtime error occurs.
    public func run() throws {
        // Collect all DATA values first
        collectData()

        // Extract mutable state from the Mutex for the duration of execution.
        // We copy it out, run the interpreter loop, and discard it when done.
        // This is safe because run() is synchronous and called at most once.
        var rs = _state.withLock { $0 }
        rs.lineIndex = 0
        rs.statementIndex = 0
        rs.stepCount = 0

        try runLoop(&rs)
    }

    private func runLoop(_ rs: inout RunState) throws {
        while rs.lineIndex < program.lines.count {
            rs.stepCount += 1
            guard rs.stepCount <= maxSteps else {
                throw BASICError.stepCountExceeded(limit: maxSteps)
            }

            let line = program.lines[rs.lineIndex]
            guard rs.statementIndex < line.statements.count else {
                rs.lineIndex += 1
                rs.statementIndex = 0
                continue
            }

            let statement = line.statements[rs.statementIndex]
            rs.statementIndex += 1

            let flow = try executeStatement(statement, rs: &rs)

            switch flow {
            case .next:
                continue
            case .gotoLine(let targetLine):
                try gotoLine(targetLine, rs: &rs)
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
        environment.withState { env in
            env.dataValues.removeAll()
            for line in program.lines {
                for statement in line.statements {
                    if case .data(let values) = statement {
                        env.dataValues.append(contentsOf: values)
                    }
                }
            }
        }
    }

    private func gotoLine(_ targetLine: Int, rs: inout RunState) throws {
        guard let index = program.lines.firstIndex(where: { $0.lineNumber == targetLine }) else {
            throw BASICError.undefinedLine(targetLine)
        }
        rs.lineIndex = index
        rs.statementIndex = 0
    }

    // MARK: - Statement Execution

    // swiftlint:disable:next cyclomatic_complexity function_body_length
    private func executeStatement(_ statement: Statement, rs: inout RunState) throws -> FlowControl {
        switch statement {
        case .rem:
            return .next

        case .print(let items):
            try executePrint(items, rs: &rs)
            return .next

        case .letStatement(let variable, let value):
            try executeAssignment(variable: variable, value: value, rs: &rs)
            return .next

        case .goto(let target):
            let lineNum = try evaluateToInt(target, rs: &rs)
            return .gotoLine(lineNum)

        case .gosub(let target):
            let lineNum = try evaluateToInt(target, rs: &rs)
            try environment.withState { env in
                guard env.gosubStack.count < Environment.maxStackDepth else {
                    throw BASICError.stackOverflow(depth: env.gosubStack.count)
                }
                env.gosubStack.append(GosubEntry(lineIndex: rs.lineIndex, statementIndex: rs.statementIndex))
            }
            return .gotoLine(lineNum)

        case .returnStatement:
            let returnAddr: GosubEntry = try environment.withState { env in
                guard let entry = env.gosubStack.popLast() else {
                    throw BASICError.returnWithoutGosub
                }
                return entry
            }
            rs.lineIndex = returnAddr.lineIndex
            rs.statementIndex = returnAddr.statementIndex
            return .next

        case .ifThen(let condition, let body):
            let value = try evaluateNumeric(condition, rs: &rs)
            // In Applesoft, any nonzero value is true
            if value != 0 {
                switch body {
                case .lineNumber(let expr):
                    let lineNum = try evaluateToInt(expr, rs: &rs)
                    return .gotoLine(lineNum)
                case .statement(let stmt):
                    return try executeStatement(stmt, rs: &rs)
                }
            }
            return .next

        case .forStatement(let variable, let start, let end, let step):
            let startVal = try evaluateNumeric(start, rs: &rs)
            let endVal = try evaluateNumeric(end, rs: &rs)
            let stepVal: Double
            if let step {
                stepVal = try evaluateNumeric(step, rs: &rs)
            } else {
                stepVal = 1.0
            }
            environment.withState { env in
                env.numericVariables[variable] = startVal
                env.forLoops[variable] = ForLoopState(
                    variable: variable,
                    limit: endVal,
                    step: stepVal,
                    lineIndex: rs.lineIndex,
                    statementIndex: rs.statementIndex
                )
            }
            return .next

        case .next(let variable):
            return try executeNext(variable: variable, rs: &rs)

        case .input(let prompt, let variables):
            try executeInput(prompt: prompt, variables: variables, rs: &rs)
            return .next

        case .get(let variable):
            try executeGet(variable: variable, rs: &rs)
            return .next

        case .dim(let declarations):
            try executeDim(declarations, rs: &rs)
            return .next

        case .data:
            // DATA is collected at program start, skip during execution
            return .next

        case .read(let variables):
            try executeRead(variables: variables, rs: &rs)
            return .next

        case .restore:
            environment.withState { env in env.dataPointer = 0 }
            return .next

        case .onGoto(let expr, let targets):
            let index = try evaluateToInt(expr, rs: &rs)
            if index >= 1 && index <= targets.count {
                let targetLine = try evaluateToInt(targets[index - 1], rs: &rs)
                return .gotoLine(targetLine)
            }
            return .next

        case .onGosub(let expr, let targets):
            let index = try evaluateToInt(expr, rs: &rs)
            if index >= 1 && index <= targets.count {
                let targetLine = try evaluateToInt(targets[index - 1], rs: &rs)
                try environment.withState { env in
                    guard env.gosubStack.count < Environment.maxStackDepth else {
                        throw BASICError.stackOverflow(depth: env.gosubStack.count)
                    }
                    env.gosubStack.append(GosubEntry(lineIndex: rs.lineIndex, statementIndex: rs.statementIndex))
                }
                return .gotoLine(targetLine)
            }
            return .next

        case .defFn(let name, let parameter, let body):
            environment.withState { env in
                env.userFunctions[name] = UserFunction(parameterName: parameter, body: body)
            }
            return .next

        case .home:
            output.clearScreen()
            rs.printColumn = 0
            return .next

        case .htab(let expr):
            let col = try evaluateToInt(expr, rs: &rs)
            let spaces = max(0, col - 1 - rs.printColumn)
            if spaces > 0 {
                output.print(String(repeating: " ", count: spaces))
                rs.printColumn += spaces
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
            let color = try evaluateToInt(expr, rs: &rs)
            graphicsBuffer.setColor(UInt8(max(0, min(color, 15))))
            return .next

        case .plot(let xExpr, let yExpr):
            let x = try evaluateToInt(xExpr, rs: &rs)
            let y = try evaluateToInt(yExpr, rs: &rs)
            try graphicsBuffer.plot(x: x, y: y)
            let rendered = GraphicsRenderer.renderLoResDirty(graphicsBuffer)
            if !rendered.isEmpty { output.print(rendered) }
            graphicsBuffer.clearDirty()
            return .next

        case .hlin(let x1Expr, let x2Expr, let yExpr):
            let x1 = try evaluateToInt(x1Expr, rs: &rs)
            let x2 = try evaluateToInt(x2Expr, rs: &rs)
            let y = try evaluateToInt(yExpr, rs: &rs)
            try graphicsBuffer.hlin(x1: x1, x2: x2, y: y)
            let rendered = GraphicsRenderer.renderLoResDirty(graphicsBuffer)
            if !rendered.isEmpty { output.print(rendered) }
            graphicsBuffer.clearDirty()
            return .next

        case .vlin(let y1Expr, let y2Expr, let xExpr):
            let y1 = try evaluateToInt(y1Expr, rs: &rs)
            let y2 = try evaluateToInt(y2Expr, rs: &rs)
            let x = try evaluateToInt(xExpr, rs: &rs)
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
            let color = try evaluateToInt(expr, rs: &rs)
            graphicsBuffer.setHColor(UInt8(max(0, min(color, 7))))
            return .next

        case .hplot(let points):
            guard let first = points.first else { return .next }
            let x0 = try evaluateToInt(first.x, rs: &rs)
            let y0 = try evaluateToInt(first.y, rs: &rs)
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
                let x = try evaluateToInt(point.x, rs: &rs)
                let y = try evaluateToInt(point.y, rs: &rs)
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
            let freq = try evaluateNumeric(freqExpr, rs: &rs)
            let dur = try evaluateNumeric(durExpr, rs: &rs)
            guard freq >= 0 else { throw BASICError.illegalQuantity(freq) }
            guard dur >= 0 else { throw BASICError.illegalQuantity(dur) }
            sound.playTone(frequency: freq, duration: max(0.001, min(dur, 30)))
            return .next

        case .end, .stop:
            return .end
        }
    }

    // MARK: - PRINT

    private func executePrint(_ items: [PrintItem], rs: inout RunState) throws {
        for item in items {
            if let expr = item.expression {
                // Check for TAB and SPC
                if case .tab(let tabExpr) = expr {
                    let col = try evaluateToInt(tabExpr, rs: &rs)
                    let spaces = max(0, col - 1 - rs.printColumn)
                    if spaces > 0 {
                        output.print(String(repeating: " ", count: spaces))
                        rs.printColumn += spaces
                    }
                } else if case .spc(let spcExpr) = expr {
                    let count = try evaluateToInt(spcExpr, rs: &rs)
                    if count > 0 {
                        output.print(String(repeating: " ", count: count))
                        rs.printColumn += count
                    }
                } else if isStringExpression(expr) {
                    let str = try evaluateString(expr, rs: &rs)
                    // Detect BEL character for beep
                    if str.contains("\u{07}") {
                        sound.beep()
                        let cleaned = str.replacingOccurrences(of: "\u{07}", with: "")
                        if !cleaned.isEmpty {
                            output.print(cleaned)
                            rs.printColumn += cleaned.count
                        }
                    } else {
                        output.print(str)
                        rs.printColumn += str.count
                    }
                } else {
                    let num = try evaluateNumeric(expr, rs: &rs)
                    let str = formatNumber(num)
                    output.print(str)
                    rs.printColumn += str.count
                }
            }

            switch item.separator {
            case .semicolon:
                break // No spacing
            case .comma:
                // Advance to next 16-character tab stop
                let nextTab = ((rs.printColumn / 16) + 1) * 16
                let spaces = nextTab - rs.printColumn
                output.print(String(repeating: " ", count: spaces))
                rs.printColumn = nextTab
            case .newline:
                output.print("\n")
                rs.printColumn = 0
            }
        }
    }

    private func formatNumber(_ value: Double) -> String {
        BuiltInFunctions.formatNumber(value)
    }

    // MARK: - Assignment

    private func executeAssignment(variable: LValue, value: Expression, rs: inout RunState) throws {
        switch variable {
        case .variable(let name):
            if name.hasSuffix("$") {
                let val = try evaluateString(value, rs: &rs)
                environment.withState { env in env.stringVariables[name] = val }
            } else {
                let val = try evaluateNumeric(value, rs: &rs)
                environment.withState { env in env.numericVariables[name] = val }
            }
        case .arrayElement(let name, let indices):
            let evaluatedIndices = try indices.map { try evaluateToInt($0, rs: &rs) }
            if name.hasSuffix("$") {
                let val = try evaluateString(value, rs: &rs)
                try setStringArrayElement(name: name, indices: evaluatedIndices, value: val)
            } else {
                let val = try evaluateNumeric(value, rs: &rs)
                try setNumericArrayElement(name: name, indices: evaluatedIndices, value: val)
            }
        }
    }

    // MARK: - FOR / NEXT

    private func executeNext(variable: String?, rs: inout RunState) throws -> FlowControl {
        try environment.withState { env in
            // Find the matching FOR loop
            let loopVar: String
            if let v = variable {
                loopVar = v
            } else {
                // NEXT without variable: use the most recently opened FOR
                guard let lastLoop = env.forLoops.values.first else {
                    throw BASICError.nextWithoutFor(variable: nil)
                }
                loopVar = lastLoop.variable
            }

            guard let loop = env.forLoops[loopVar] else {
                throw BASICError.nextWithoutFor(variable: loopVar)
            }

            guard var currentVal = env.numericVariables[loopVar] else {
                throw BASICError.undefinedVariable(loopVar)
            }

            currentVal += loop.step
            env.numericVariables[loopVar] = currentVal

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
                env.forLoops.removeValue(forKey: loopVar)
                return .next
            } else {
                // Loop back to the statement after FOR
                rs.lineIndex = loop.lineIndex
                rs.statementIndex = loop.statementIndex
                return .next
            }
        }
    }

    // MARK: - INPUT / GET

    private func executeInput(prompt: String?, variables: [LValue], rs: inout RunState) throws {
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

        environment.withState { env in
            for (i, lvalue) in variables.enumerated() {
                let valueStr = i < values.count ? values[i] : ""
                switch lvalue {
                case .variable(let name):
                    if name.hasSuffix("$") {
                        env.stringVariables[name] = valueStr
                    } else {
                        env.numericVariables[name] = Double(valueStr) ?? 0
                    }
                case .arrayElement:
                    break // Simplified: skip array input for now
                }
            }
        }
    }

    private func executeGet(variable: LValue, rs: inout RunState) throws {
        let char = input.getChar()
        environment.withState { env in
            switch variable {
            case .variable(let name):
                if name.hasSuffix("$") {
                    env.stringVariables[name] = char.map(String.init) ?? ""
                } else {
                    if let char, let ascii = char.asciiValue {
                        env.numericVariables[name] = Double(ascii)
                    } else {
                        env.numericVariables[name] = 0
                    }
                }
            case .arrayElement:
                break
            }
        }
    }

    // MARK: - DIM

    private func executeDim(_ declarations: [DimDeclaration], rs: inout RunState) throws {
        for decl in declarations {
            let dims = try decl.dimensions.map { try evaluateToInt($0, rs: &rs) + 1 } // Applesoft DIM(10) creates 0...10

            // Validate dimensions
            for dim in dims {
                guard dim > 0 && dim <= Environment.maxArrayDimension else {
                    throw BASICError.dimensionError(decl.name)
                }
            }

            try environment.withState { env in
                if decl.name.hasSuffix("$") {
                    guard env.stringArrays[decl.name] == nil else {
                        throw BASICError.redimensionError(decl.name)
                    }
                    env.stringArrays[decl.name] = BASICStringArray(dimensions: dims)
                } else {
                    guard env.numericArrays[decl.name] == nil else {
                        throw BASICError.redimensionError(decl.name)
                    }
                    env.numericArrays[decl.name] = BASICArray(dimensions: dims)
                }
            }
        }
    }

    // MARK: - READ

    private func executeRead(variables: [LValue], rs: inout RunState) throws {
        try environment.withState { env in
            for lvalue in variables {
                guard env.dataPointer < env.dataValues.count else {
                    throw BASICError.outOfData
                }
                let dataVal = env.dataValues[env.dataPointer]
                env.dataPointer += 1

                switch lvalue {
                case .variable(let name):
                    if name.hasSuffix("$") {
                        switch dataVal {
                        case .string(let s): env.stringVariables[name] = s
                        case .number(let n): env.stringVariables[name] = formatNumber(n)
                        }
                    } else {
                        switch dataVal {
                        case .number(let n): env.numericVariables[name] = n
                        case .string(let s): env.numericVariables[name] = Double(s) ?? 0
                        }
                    }
                case .arrayElement:
                    break // Simplified
                }
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
        try environment.withState { env in
            // Auto-DIM if not dimensioned (Applesoft creates 0..10 by default)
            if env.numericArrays[name] == nil {
                let dims = indices.map { _ in 11 } // Default size 0..10
                env.numericArrays[name] = BASICArray(dimensions: dims)
            }

            guard var array = env.numericArrays[name] else {
                throw BASICError.dimensionError(name)
            }
            let index = try getArrayIndex(name: name, indices: indices, array: array.dimensions)
            array.storage[index] = value
            env.numericArrays[name] = array
        }
    }

    private func setStringArrayElement(name: String, indices: [Int], value: String) throws {
        try environment.withState { env in
            if env.stringArrays[name] == nil {
                let dims = indices.map { _ in 11 }
                env.stringArrays[name] = BASICStringArray(dimensions: dims)
            }

            guard var array = env.stringArrays[name] else {
                throw BASICError.dimensionError(name)
            }
            let index = try getArrayIndex(name: name, indices: indices, array: array.dimensions)
            array.storage[index] = value
            env.stringArrays[name] = array
        }
    }

    private func getNumericArrayElement(name: String, indices: [Int]) throws -> Double {
        try environment.withState { env in
            if env.numericArrays[name] == nil {
                let dims = indices.map { _ in 11 }
                env.numericArrays[name] = BASICArray(dimensions: dims)
            }
            guard let array = env.numericArrays[name] else {
                throw BASICError.dimensionError(name)
            }
            let index = try getArrayIndex(name: name, indices: indices, array: array.dimensions)
            return array.storage[index]
        }
    }

    private func getStringArrayElement(name: String, indices: [Int]) throws -> String {
        try environment.withState { env in
            if env.stringArrays[name] == nil {
                let dims = indices.map { _ in 11 }
                env.stringArrays[name] = BASICStringArray(dimensions: dims)
            }
            guard let array = env.stringArrays[name] else {
                throw BASICError.dimensionError(name)
            }
            let index = try getArrayIndex(name: name, indices: indices, array: array.dimensions)
            return array.storage[index]
        }
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

    private func evaluateToInt(_ expr: Expression, rs: inout RunState) throws -> Int {
        let value = try evaluateNumeric(expr, rs: &rs)
        return Int(value)
    }

    private func evaluateNumeric(_ expr: Expression, rs: inout RunState) throws -> Double {
        switch expr {
        case .numberLiteral(let value):
            return value

        case .stringLiteral:
            throw BASICError.typeMismatch(expected: "number", got: "string")

        case .variable(let name):
            if name.hasSuffix("$") {
                throw BASICError.typeMismatch(expected: "number", got: "string")
            }
            return environment.withState { env in env.numericVariables[name] ?? 0 }

        case .arrayAccess(let name, let indices):
            let evaluatedIndices = try indices.map { try evaluateToInt($0, rs: &rs) }
            if name.hasSuffix("$") {
                throw BASICError.typeMismatch(expected: "number", got: "string")
            }
            return try getNumericArrayElement(name: name, indices: evaluatedIndices)

        case .binary(let left, let op, let right):
            // Handle string comparisons (A$ = "Y", etc.)
            if isStringExpression(left) || isStringExpression(right) {
                return try evaluateStringComparison(left, op, right, rs: &rs)
            }
            let lhs = try evaluateNumeric(left, rs: &rs)
            let rhs = try evaluateNumeric(right, rs: &rs)
            return try evaluateBinaryOp(lhs, op, rhs)

        case .unary(let op, let operand):
            let value = try evaluateNumeric(operand, rs: &rs)
            switch op {
            case .negate: return -value
            case .not: return value == 0 ? 1 : 0
            }

        case .functionCall(let name, let args):
            return try evaluateFunction(name: name, args: args, rs: &rs)

        case .userFunctionCall(let name, let argument):
            return try evaluateUserFunction(name: name, argument: argument, rs: &rs)

        case .and(let left, let right):
            let lhs = try evaluateNumeric(left, rs: &rs)
            let rhs = try evaluateNumeric(right, rs: &rs)
            return (lhs != 0 && rhs != 0) ? 1 : 0

        case .or(let left, let right):
            let lhs = try evaluateNumeric(left, rs: &rs)
            let rhs = try evaluateNumeric(right, rs: &rs)
            return (lhs != 0 || rhs != 0) ? 1 : 0

        case .tab, .spc:
            return 0
        }
    }

    private func evaluateString(_ expr: Expression, rs: inout RunState) throws -> String {
        switch expr {
        case .stringLiteral(let value):
            return value

        case .variable(let name):
            if name.hasSuffix("$") {
                return environment.withState { env in env.stringVariables[name] ?? "" }
            }
            throw BASICError.typeMismatch(expected: "string", got: "number")

        case .arrayAccess(let name, let indices):
            let evaluatedIndices = try indices.map { try evaluateToInt($0, rs: &rs) }
            if name.hasSuffix("$") {
                return try getStringArrayElement(name: name, indices: evaluatedIndices)
            }
            throw BASICError.typeMismatch(expected: "string", got: "number")

        case .binary(let left, let op, let right):
            if op == .plus {
                let lhs = try evaluateString(left, rs: &rs)
                let rhs = try evaluateString(right, rs: &rs)
                return lhs + rhs
            }
            // String comparison returns numeric, not string
            throw BASICError.typeMismatch(expected: "string", got: "number")

        case .functionCall(let name, let args):
            return try evaluateStringFunction(name: name, args: args, rs: &rs)

        default:
            throw BASICError.typeMismatch(expected: "string", got: "number")
        }
    }

    private func evaluateStringComparison(
        _ left: Expression, _ op: Operator, _ right: Expression, rs: inout RunState
    ) throws -> Double {
        let lhs = try evaluateString(left, rs: &rs)
        let rhs = try evaluateString(right, rs: &rs)
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

    private func evaluateFunction(name: String, args: [Expression], rs: inout RunState) throws -> Double {
        // Graphics screen read functions
        switch name {
        case "SCRN":
            guard args.count == 2 else { throw BASICError.illegalQuantity(0) }
            let x = try evaluateToInt(args[0], rs: &rs)
            let y = try evaluateToInt(args[1], rs: &rs)
            return Double(try graphicsBuffer.scrn(x: x, y: y))
        case "HSCRN":
            guard args.count == 2 else { throw BASICError.illegalQuantity(0) }
            let x = try evaluateToInt(args[0], rs: &rs)
            let y = try evaluateToInt(args[1], rs: &rs)
            return Double(try graphicsBuffer.hscrn(x: x, y: y))
        default:
            break
        }

        // String functions that return numeric values
        switch name {
        case "LEN":
            let str = try evaluateString(args[0], rs: &rs)
            return Double(str.count)
        case "ASC":
            let str = try evaluateString(args[0], rs: &rs)
            guard let first = str.first, let ascii = first.asciiValue else {
                throw BASICError.illegalQuantity(0)
            }
            return Double(ascii)
        case "VAL":
            let str = try evaluateString(args[0], rs: &rs)
            return Double(str.trimmingCharacters(in: .whitespaces)) ?? 0
        default:
            let evaluatedArgs = try args.map { try evaluateNumeric($0, rs: &rs) }
            return try BuiltInFunctions.evaluateNumeric(name: name, args: evaluatedArgs, rng: &rs.rng)
        }
    }

    private func evaluateStringFunction(name: String, args: [Expression], rs: inout RunState) throws -> String {
        switch name {
        case "LEFT$":
            let str = try evaluateString(args[0], rs: &rs)
            let count = try evaluateNumeric(args[1], rs: &rs)
            return try BuiltInFunctions.evaluateString(
                name: name, stringArgs: [str], numericArgs: [count]
            )
        case "RIGHT$":
            let str = try evaluateString(args[0], rs: &rs)
            let count = try evaluateNumeric(args[1], rs: &rs)
            return try BuiltInFunctions.evaluateString(
                name: name, stringArgs: [str], numericArgs: [count]
            )
        case "MID$":
            let str = try evaluateString(args[0], rs: &rs)
            var numArgs: [Double] = [try evaluateNumeric(args[1], rs: &rs)]
            if args.count > 2 {
                numArgs.append(try evaluateNumeric(args[2], rs: &rs))
            }
            return try BuiltInFunctions.evaluateString(
                name: name, stringArgs: [str], numericArgs: numArgs
            )
        case "CHR$":
            let code = try evaluateNumeric(args[0], rs: &rs)
            return try BuiltInFunctions.evaluateString(
                name: name, stringArgs: [], numericArgs: [code]
            )
        case "STR$":
            let num = try evaluateNumeric(args[0], rs: &rs)
            return try BuiltInFunctions.evaluateString(
                name: name, stringArgs: [], numericArgs: [num]
            )
        default:
            throw BASICError.undefinedVariable("FN \(name)")
        }
    }

    private func evaluateUserFunction(name: String, argument: Expression, rs: inout RunState) throws -> Double {
        let fn: UserFunction = try environment.withState { env in
            guard let fn = env.userFunctions[name] else {
                throw BASICError.undefinedVariable("FN \(name)")
            }
            return fn
        }
        let argValue = try evaluateNumeric(argument, rs: &rs)
        // Save the parameter, evaluate the body, restore
        let saved: Double? = environment.withState { env in
            let saved = env.numericVariables[fn.parameterName]
            env.numericVariables[fn.parameterName] = argValue
            return saved
        }
        let result = try evaluateNumeric(fn.body, rs: &rs)
        environment.withState { env in
            if let saved {
                env.numericVariables[fn.parameterName] = saved
            } else {
                env.numericVariables.removeValue(forKey: fn.parameterName)
            }
        }
        return result
    }
}
