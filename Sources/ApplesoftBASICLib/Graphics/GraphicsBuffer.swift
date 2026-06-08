import Synchronization

/// Stores the pixel state for lo-res and hi-res graphics modes.
///
/// The buffer maintains an in-memory grid of pixels and tracks the current
/// drawing color, graphics mode, and cursor position for HPLOT TO.
public final class GraphicsBuffer: Sendable {

    /// The active graphics mode.
    public enum Mode: Sendable, Equatable {
        /// Text-only mode (no graphics).
        case text
        /// Lo-res graphics: 40x48, 16 colors (bottom 8 rows may show text).
        case loRes
        /// Hi-res graphics page 1: 280x160 + 4 text lines at bottom.
        case hiRes
        /// Hi-res graphics page 2: 280x192, full screen.
        case hiResFull
    }

    /// Lo-res screen dimensions.
    public static let loResWidth = 40
    /// Lo-res screen height.
    public static let loResHeight = 48

    /// Hi-res screen width.
    public static let hiResWidth = 280
    /// Hi-res screen height.
    public static let hiResHeight = 192

    /// All mutable graphics state, protected by a single Mutex.
    struct State: Sendable {
        /// The current graphics mode.
        var mode: Mode = .text
        /// Lo-res pixel grid (40x48), each value 0-15.
        var loResPixels: [[UInt8]]
        /// Hi-res pixel grid (280x192), each value 0-7.
        var hiResPixels: [[UInt8]]
        /// Current lo-res drawing color (0-15).
        var currentColor: UInt8 = 0
        /// Current hi-res drawing color (0-7).
        var currentHColor: UInt8 = 0
        /// Last HPLOT position for HPLOT TO continuation.
        var lastHPlotX: Int = 0
        /// Last HPLOT position for HPLOT TO continuation.
        var lastHPlotY: Int = 0
        /// Rows that have been modified since last render (for differential rendering).
        var dirtyLoResRows: Set<Int> = []
        /// Rows that have been modified since last render (for differential rendering).
        var dirtyHiResRows: Set<Int> = []
    }

    private let _state: Mutex<State>

    // MARK: - Public read-only accessors

    /// The current graphics mode.
    public var mode: Mode { _state.withLock { $0.mode } }

    /// Lo-res pixel grid (40x48), each value 0-15.
    public var loResPixels: [[UInt8]] { _state.withLock { $0.loResPixels } }

    /// Hi-res pixel grid (280x192), each value 0-7.
    public var hiResPixels: [[UInt8]] { _state.withLock { $0.hiResPixels } }

    /// Current lo-res drawing color (0-15).
    public var currentColor: UInt8 { _state.withLock { $0.currentColor } }

    /// Current hi-res drawing color (0-7).
    public var currentHColor: UInt8 { _state.withLock { $0.currentHColor } }

    /// Last HPLOT position for HPLOT TO continuation.
    public var lastHPlotX: Int { _state.withLock { $0.lastHPlotX } }

    /// Last HPLOT position for HPLOT TO continuation.
    public var lastHPlotY: Int { _state.withLock { $0.lastHPlotY } }

    /// Rows that have been modified since last render (for differential rendering).
    public var dirtyLoResRows: Set<Int> { _state.withLock { $0.dirtyLoResRows } }

    /// Rows that have been modified since last render (for differential rendering).
    public var dirtyHiResRows: Set<Int> { _state.withLock { $0.dirtyHiResRows } }

    /// Creates a new graphics buffer with cleared screens.
    public init() {
        let loRes = Array(
            repeating: Array(repeating: UInt8(0), count: Self.loResWidth),
            count: Self.loResHeight
        )
        let hiRes = Array(
            repeating: Array(repeating: UInt8(0), count: Self.hiResWidth),
            count: Self.hiResHeight
        )
        _state = Mutex(State(loResPixels: loRes, hiResPixels: hiRes))
    }

    // MARK: - Mode Switching

    /// Switches to lo-res graphics mode and clears the lo-res screen.
    public func switchToLoRes() {
        _state.withLock { s in
            s.mode = .loRes
            Self.clearLoResState(&s)
        }
    }

    /// Switches to hi-res graphics mode (page 1, mixed with text).
    public func switchToHiRes() {
        _state.withLock { s in
            s.mode = .hiRes
            Self.clearHiResState(&s)
        }
    }

    /// Switches to full hi-res graphics mode (page 2, no text).
    public func switchToHiResFull() {
        _state.withLock { s in
            s.mode = .hiResFull
            Self.clearHiResState(&s)
        }
    }

    /// Returns to text mode.
    public func switchToText() {
        _state.withLock { s in s.mode = .text }
    }

    // MARK: - Lo-Res Operations

    /// Sets the lo-res drawing color.
    public func setColor(_ color: UInt8) {
        _state.withLock { s in s.currentColor = min(color, 15) }
    }

    /// Plots a single lo-res pixel.
    ///
    /// - Throws: ``BASICError/illegalQuantity(_:)`` if coordinates are out of range.
    public func plot(x: Int, y: Int) throws {
        try _state.withLock { s in
            guard x >= 0 && x < Self.loResWidth else {
                throw BASICError.illegalQuantity(Double(x))
            }
            guard y >= 0 && y < Self.loResHeight else {
                throw BASICError.illegalQuantity(Double(y))
            }
            s.loResPixels[y][x] = s.currentColor
            s.dirtyLoResRows.insert(y)
        }
    }

    /// Draws a horizontal line in lo-res mode.
    public func hlin(x1: Int, x2: Int, y: Int) throws {
        try _state.withLock { s in
            guard y >= 0 && y < Self.loResHeight else {
                throw BASICError.illegalQuantity(Double(y))
            }
            let startX = max(0, min(x1, x2))
            let endX = min(Self.loResWidth - 1, max(x1, x2))
            for x in startX...endX {
                s.loResPixels[y][x] = s.currentColor
            }
            s.dirtyLoResRows.insert(y)
        }
    }

    /// Draws a vertical line in lo-res mode.
    public func vlin(y1: Int, y2: Int, x: Int) throws {
        try _state.withLock { s in
            guard x >= 0 && x < Self.loResWidth else {
                throw BASICError.illegalQuantity(Double(x))
            }
            let startY = max(0, min(y1, y2))
            let endY = min(Self.loResHeight - 1, max(y1, y2))
            for y in startY...endY {
                s.loResPixels[y][x] = s.currentColor
                s.dirtyLoResRows.insert(y)
            }
        }
    }

    /// Reads the color of a lo-res pixel.
    public func scrn(x: Int, y: Int) throws -> UInt8 {
        try _state.withLock { s in
            guard x >= 0 && x < Self.loResWidth else {
                throw BASICError.illegalQuantity(Double(x))
            }
            guard y >= 0 && y < Self.loResHeight else {
                throw BASICError.illegalQuantity(Double(y))
            }
            return s.loResPixels[y][x]
        }
    }

    // MARK: - Hi-Res Operations

    /// Sets the hi-res drawing color.
    public func setHColor(_ color: UInt8) {
        _state.withLock { s in s.currentHColor = min(color, 7) }
    }

    /// Plots a single hi-res pixel.
    public func hplot(x: Int, y: Int) throws {
        try _state.withLock { s in
            guard x >= 0 && x < Self.hiResWidth else {
                throw BASICError.illegalQuantity(Double(x))
            }
            guard y >= 0 && y < Self.hiResHeight else {
                throw BASICError.illegalQuantity(Double(y))
            }
            s.hiResPixels[y][x] = s.currentHColor
            s.dirtyHiResRows.insert(y)
            s.lastHPlotX = x
            s.lastHPlotY = y
        }
    }

    /// Draws a line between two hi-res points using Bresenham's algorithm.
    public func hplotLine(x1: Int, y1: Int, x2: Int, y2: Int) throws {
        _state.withLock { s in
            var cx = x1
            var cy = y1
            let dx = abs(x2 - x1)
            let dy = -abs(y2 - y1)
            let sx = x1 < x2 ? 1 : -1
            let sy = y1 < y2 ? 1 : -1
            var err = dx + dy

            let maxSteps = dx - dy + 1000 // Safety limit
            var steps = 0

            while steps < maxSteps {
                steps += 1
                if cx >= 0 && cx < Self.hiResWidth && cy >= 0 && cy < Self.hiResHeight {
                    s.hiResPixels[cy][cx] = s.currentHColor
                    s.dirtyHiResRows.insert(cy)
                }
                if cx == x2 && cy == y2 { break }
                let e2 = 2 * err
                if e2 >= dy {
                    err += dy
                    cx += sx
                }
                if e2 <= dx {
                    err += dx
                    cy += sy
                }
            }
            s.lastHPlotX = x2
            s.lastHPlotY = y2
        }
    }

    /// Reads the color of a hi-res pixel (extension, not in original Applesoft).
    public func hscrn(x: Int, y: Int) throws -> UInt8 {
        try _state.withLock { s in
            guard x >= 0 && x < Self.hiResWidth else {
                throw BASICError.illegalQuantity(Double(x))
            }
            guard y >= 0 && y < Self.hiResHeight else {
                throw BASICError.illegalQuantity(Double(y))
            }
            return s.hiResPixels[y][x]
        }
    }

    // MARK: - Clear

    /// Clears the lo-res screen to black.
    public func clearLoRes() {
        _state.withLock { s in Self.clearLoResState(&s) }
    }

    /// Clears the hi-res screen to black.
    public func clearHiRes() {
        _state.withLock { s in Self.clearHiResState(&s) }
    }

    /// Clears dirty tracking after rendering.
    public func clearDirty() {
        _state.withLock { s in
            s.dirtyLoResRows.removeAll()
            s.dirtyHiResRows.removeAll()
        }
    }

    /// Provides exclusive access to the graphics state for bulk reads (e.g., rendering).
    func withState<R>(_ body: (inout State) -> R) -> R {
        _state.withLock { state in
            body(&state)
        }
    }

    // MARK: - Private helpers (called within withLock)

    private static func clearLoResState(_ s: inout State) {
        for y in 0..<loResHeight {
            for x in 0..<loResWidth {
                s.loResPixels[y][x] = 0
            }
            s.dirtyLoResRows.insert(y)
        }
    }

    private static func clearHiResState(_ s: inout State) {
        for y in 0..<hiResHeight {
            for x in 0..<hiResWidth {
                s.hiResPixels[y][x] = 0
            }
            s.dirtyHiResRows.insert(y)
        }
    }
}
