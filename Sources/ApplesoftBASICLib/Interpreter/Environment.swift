/// Runtime environment for the BASIC interpreter.
///
/// Stores variables, arrays, DATA values, the GOSUB return stack,
/// FOR loop state, and user-defined functions.
public final class Environment: @unchecked Sendable {

    /// Maximum number of variables allowed.
    public static let maxVariables = 1_000

    /// Maximum GOSUB call stack depth.
    public static let maxStackDepth = 256

    /// Maximum array size per dimension.
    public static let maxArrayDimension = 10_000

    /// Maximum total DATA items.
    public static let maxDataItems = 10_000

    // MARK: - Variable Storage

    /// Numeric variables (A, X1, etc.).
    var numericVariables: [String: Double] = [:]

    /// String variables (A$, N$, etc.).
    var stringVariables: [String: String] = [:]

    // MARK: - Arrays

    /// Numeric arrays, keyed by name with flat storage and dimension sizes.
    var numericArrays: [String: BASICArray] = [:]

    /// String arrays.
    var stringArrays: [String: BASICStringArray] = [:]

    // MARK: - DATA / READ

    /// All DATA values collected from the program.
    var dataValues: [DataValue] = []

    /// Current position in the DATA list for READ.
    var dataPointer: Int = 0

    // MARK: - GOSUB Stack

    /// Return addresses for GOSUB calls: (lineIndex, statementIndex).
    var gosubStack: [(lineIndex: Int, statementIndex: Int)] = []

    // MARK: - FOR Loop Stack

    /// Active FOR loops, keyed by variable name.
    var forLoops: [String: ForLoopState] = [:]

    // MARK: - User-Defined Functions

    /// User-defined functions from DEF FN.
    var userFunctions: [String: UserFunction] = [:]

    public init() {}

    /// Resets all state.
    func reset() {
        numericVariables.removeAll()
        stringVariables.removeAll()
        numericArrays.removeAll()
        stringArrays.removeAll()
        dataValues.removeAll()
        dataPointer = 0
        gosubStack.removeAll()
        forLoops.removeAll()
        userFunctions.removeAll()
    }
}

/// Storage for a numeric BASIC array.
struct BASICArray: Sendable {
    let dimensions: [Int]
    var storage: [Double]

    init(dimensions: [Int]) {
        self.dimensions = dimensions
        let totalSize = dimensions.reduce(1, *)
        self.storage = Array(repeating: 0.0, count: totalSize)
    }
}

/// Storage for a string BASIC array.
struct BASICStringArray: Sendable {
    let dimensions: [Int]
    var storage: [String]

    init(dimensions: [Int]) {
        self.dimensions = dimensions
        let totalSize = dimensions.reduce(1, *)
        self.storage = Array(repeating: "", count: totalSize)
    }
}

/// State of an active FOR loop.
struct ForLoopState: Sendable {
    let variable: String
    let limit: Double
    let step: Double
    let lineIndex: Int
    let statementIndex: Int
}

/// A user-defined function from DEF FN.
struct UserFunction: Sendable {
    let parameterName: String
    let body: Expression
}
