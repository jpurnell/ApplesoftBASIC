/// Stores the pixel state for lo-res and hi-res graphics modes.
///
/// The buffer maintains an in-memory grid of pixels and tracks the current
/// drawing color, graphics mode, and cursor position for HPLOT TO.
// Justification: GraphicsBuffer is owned by a single Interpreter and mutated only during sequential statement execution; pixel data and drawing state are never accessed concurrently.
public final class GraphicsBuffer: @unchecked Sendable {

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

    /// The current graphics mode.
    public private(set) var mode: Mode = .text

    /// Lo-res pixel grid (40x48), each value 0-15.
    public private(set) var loResPixels: [[UInt8]]

    /// Hi-res pixel grid (280x192), each value 0-7.
    public private(set) var hiResPixels: [[UInt8]]

    /// Current lo-res drawing color (0-15).
    public private(set) var currentColor: UInt8 = 0

    /// Current hi-res drawing color (0-7).
    public private(set) var currentHColor: UInt8 = 0

    /// Last HPLOT position for HPLOT TO continuation.
    public private(set) var lastHPlotX: Int = 0

    /// Last HPLOT position for HPLOT TO continuation.
    public private(set) var lastHPlotY: Int = 0

    /// Rows that have been modified since last render (for differential rendering).
    public private(set) var dirtyLoResRows: Set<Int> = []

    /// Rows that have been modified since last render (for differential rendering).
    public private(set) var dirtyHiResRows: Set<Int> = []

    /// Creates a new graphics buffer with cleared screens.
    public init() {
        loResPixels = Array(
            repeating: Array(repeating: UInt8(0), count: Self.loResWidth),
            count: Self.loResHeight
        )
        hiResPixels = Array(
            repeating: Array(repeating: UInt8(0), count: Self.hiResWidth),
            count: Self.hiResHeight
        )
    }

    // MARK: - Mode Switching

    /// Switches to lo-res graphics mode and clears the lo-res screen.
    public func switchToLoRes() {
        mode = .loRes
        clearLoRes()
    }

    /// Switches to hi-res graphics mode (page 1, mixed with text).
    public func switchToHiRes() {
        mode = .hiRes
        clearHiRes()
    }

    /// Switches to full hi-res graphics mode (page 2, no text).
    public func switchToHiResFull() {
        mode = .hiResFull
        clearHiRes()
    }

    /// Returns to text mode.
    public func switchToText() {
        mode = .text
    }

    // MARK: - Lo-Res Operations

    /// Sets the lo-res drawing color.
    public func setColor(_ color: UInt8) {
        currentColor = min(color, 15)
    }

    /// Plots a single lo-res pixel.
    ///
    /// - Throws: ``BASICError/illegalQuantity(_:)`` if coordinates are out of range.
    public func plot(x: Int, y: Int) throws {
        guard x >= 0 && x < Self.loResWidth else {
            throw BASICError.illegalQuantity(Double(x))
        }
        guard y >= 0 && y < Self.loResHeight else {
            throw BASICError.illegalQuantity(Double(y))
        }
        loResPixels[y][x] = currentColor
        dirtyLoResRows.insert(y)
    }

    /// Draws a horizontal line in lo-res mode.
    public func hlin(x1: Int, x2: Int, y: Int) throws {
        guard y >= 0 && y < Self.loResHeight else {
            throw BASICError.illegalQuantity(Double(y))
        }
        let startX = max(0, min(x1, x2))
        let endX = min(Self.loResWidth - 1, max(x1, x2))
        for x in startX...endX {
            loResPixels[y][x] = currentColor
        }
        dirtyLoResRows.insert(y)
    }

    /// Draws a vertical line in lo-res mode.
    public func vlin(y1: Int, y2: Int, x: Int) throws {
        guard x >= 0 && x < Self.loResWidth else {
            throw BASICError.illegalQuantity(Double(x))
        }
        let startY = max(0, min(y1, y2))
        let endY = min(Self.loResHeight - 1, max(y1, y2))
        for y in startY...endY {
            loResPixels[y][x] = currentColor
            dirtyLoResRows.insert(y)
        }
    }

    /// Reads the color of a lo-res pixel.
    public func scrn(x: Int, y: Int) throws -> UInt8 {
        guard x >= 0 && x < Self.loResWidth else {
            throw BASICError.illegalQuantity(Double(x))
        }
        guard y >= 0 && y < Self.loResHeight else {
            throw BASICError.illegalQuantity(Double(y))
        }
        return loResPixels[y][x]
    }

    // MARK: - Hi-Res Operations

    /// Sets the hi-res drawing color.
    public func setHColor(_ color: UInt8) {
        currentHColor = min(color, 7)
    }

    /// Plots a single hi-res pixel.
    public func hplot(x: Int, y: Int) throws {
        guard x >= 0 && x < Self.hiResWidth else {
            throw BASICError.illegalQuantity(Double(x))
        }
        guard y >= 0 && y < Self.hiResHeight else {
            throw BASICError.illegalQuantity(Double(y))
        }
        hiResPixels[y][x] = currentHColor
        dirtyHiResRows.insert(y)
        lastHPlotX = x
        lastHPlotY = y
    }

    /// Draws a line between two hi-res points using Bresenham's algorithm.
    public func hplotLine(x1: Int, y1: Int, x2: Int, y2: Int) throws {
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
                hiResPixels[cy][cx] = currentHColor
                dirtyHiResRows.insert(cy)
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
        lastHPlotX = x2
        lastHPlotY = y2
    }

    /// Reads the color of a hi-res pixel (extension, not in original Applesoft).
    public func hscrn(x: Int, y: Int) throws -> UInt8 {
        guard x >= 0 && x < Self.hiResWidth else {
            throw BASICError.illegalQuantity(Double(x))
        }
        guard y >= 0 && y < Self.hiResHeight else {
            throw BASICError.illegalQuantity(Double(y))
        }
        return hiResPixels[y][x]
    }

    // MARK: - Clear

    /// Clears the lo-res screen to black.
    public func clearLoRes() {
        for y in 0..<Self.loResHeight {
            for x in 0..<Self.loResWidth {
                loResPixels[y][x] = 0
            }
            dirtyLoResRows.insert(y)
        }
    }

    /// Clears the hi-res screen to black.
    public func clearHiRes() {
        for y in 0..<Self.hiResHeight {
            for x in 0..<Self.hiResWidth {
                hiResPixels[y][x] = 0
            }
            dirtyHiResRows.insert(y)
        }
    }

    /// Clears dirty tracking after rendering.
    public func clearDirty() {
        dirtyLoResRows.removeAll()
        dirtyHiResRows.removeAll()
    }
}
