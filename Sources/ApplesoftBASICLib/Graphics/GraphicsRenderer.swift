/// Renders the graphics buffer to terminal escape sequences.
///
/// Lo-res uses Unicode half-block characters (`▀`) with 24-bit ANSI color.
/// Hi-res uses Unicode braille characters with 24-bit ANSI color.
public struct GraphicsRenderer: Sendable {

    /// Renders the entire lo-res screen (40x48 → 40 cols x 24 rows).
    ///
    /// Each terminal character represents 2 vertical lo-res pixels using
    /// the upper-half-block `▀` with foreground = top pixel, background = bottom pixel.
    public static func renderLoRes(_ buffer: GraphicsBuffer) -> String {
        var output = ""
        // Move cursor to top-left
        output += "\u{1B}[H"

        for row in 0..<24 {
            let topY = row * 2
            let botY = topY + 1
            for x in 0..<GraphicsBuffer.loResWidth {
                let topColor = buffer.loResPixels[topY][x]
                let botColor = buffer.loResPixels[botY][x]
                let top = AppleIIColors.loRes[Int(topColor)]
                let bot = AppleIIColors.loRes[Int(botColor)]
                // Foreground = top pixel, background = bottom pixel
                output += "\u{1B}[38;2;\(top.r);\(top.g);\(top.b)m"
                output += "\u{1B}[48;2;\(bot.r);\(bot.g);\(bot.b)m"
                output += "\u{2580}" // ▀
            }
            output += "\u{1B}[0m\n"
        }
        return output
    }

    /// Renders only the dirty rows of the lo-res screen.
    public static func renderLoResDirty(_ buffer: GraphicsBuffer) -> String {
        guard !buffer.dirtyLoResRows.isEmpty else { return "" }

        var output = ""
        // Determine which terminal rows need updating
        var dirtyTermRows: Set<Int> = []
        for loResRow in buffer.dirtyLoResRows {
            dirtyTermRows.insert(loResRow / 2)
        }

        for row in dirtyTermRows.sorted() {
            let topY = row * 2
            let botY = topY + 1
            // Position cursor at this terminal row
            output += "\u{1B}[\(row + 1);1H"
            for x in 0..<GraphicsBuffer.loResWidth {
                let topColor = buffer.loResPixels[topY][x]
                let botColor = buffer.loResPixels[botY][x]
                let top = AppleIIColors.loRes[Int(topColor)]
                let bot = AppleIIColors.loRes[Int(botColor)]
                output += "\u{1B}[38;2;\(top.r);\(top.g);\(top.b)m"
                output += "\u{1B}[48;2;\(bot.r);\(bot.g);\(bot.b)m"
                output += "\u{2580}"
            }
            output += "\u{1B}[0m"
        }
        return output
    }

    /// Renders the entire hi-res screen using braille characters (280x192 → 140 cols x 48 rows).
    ///
    /// Each braille character encodes a 2x4 dot pattern. Non-black pixels are set as dots,
    /// colored with the most common non-black color in the 2x4 cell.
    public static func renderHiRes(_ buffer: GraphicsBuffer) -> String {
        var output = ""
        output += "\u{1B}[H"

        let maxY = buffer.mode == .hiResFull ? 192 : 160

        for cellRow in 0..<(maxY / 4) {
            for cellCol in 0..<140 {
                let (brailleChar, color) = hiResBrailleCell(
                    buffer: buffer,
                    cellCol: cellCol,
                    cellRow: cellRow
                )
                if let color {
                    output += "\u{1B}[38;2;\(color.r);\(color.g);\(color.b)m"
                    output += String(brailleChar)
                    output += "\u{1B}[0m"
                } else {
                    output += String(brailleChar)
                }
            }
            output += "\n"
        }
        return output
    }

    /// Renders only dirty rows of the hi-res screen.
    public static func renderHiResDirty(_ buffer: GraphicsBuffer) -> String {
        guard !buffer.dirtyHiResRows.isEmpty else { return "" }

        var output = ""
        var dirtyCellRows: Set<Int> = []
        for hiResRow in buffer.dirtyHiResRows {
            dirtyCellRows.insert(hiResRow / 4)
        }

        for cellRow in dirtyCellRows.sorted() {
            output += "\u{1B}[\(cellRow + 1);1H"
            for cellCol in 0..<140 {
                let (brailleChar, color) = hiResBrailleCell(
                    buffer: buffer,
                    cellCol: cellCol,
                    cellRow: cellRow
                )
                if let color {
                    output += "\u{1B}[38;2;\(color.r);\(color.g);\(color.b)m"
                    output += String(brailleChar)
                    output += "\u{1B}[0m"
                } else {
                    output += String(brailleChar)
                }
            }
        }
        return output
    }

    // MARK: - Braille Helpers

    /// Computes the braille character and color for a 2x4 cell of hi-res pixels.
    private static func hiResBrailleCell(
        buffer: GraphicsBuffer,
        cellCol: Int,
        cellRow: Int
    ) -> (Character, AppleIIColors.RGB?) {
        let px = cellCol * 2
        let py = cellRow * 4

        // Braille dot positions map:
        // Col0: dots 1,2,3,7 (bits 0,1,2,6)
        // Col1: dots 4,5,6,8 (bits 3,4,5,7)
        var brailleValue: UInt8 = 0
        var dominantColor: UInt8 = 0
        var colorCounts = [UInt8: Int]()

        // Column offsets for braille dot mapping
        let dotMap: [(col: Int, row: Int, bit: Int)] = [
            (0, 0, 0), (0, 1, 1), (0, 2, 2),
            (1, 0, 3), (1, 1, 4), (1, 2, 5),
            (0, 3, 6), (1, 3, 7),
        ]

        for dot in dotMap {
            let x = px + dot.col
            let y = py + dot.row
            guard x < GraphicsBuffer.hiResWidth && y < GraphicsBuffer.hiResHeight else { continue }
            let pixel = buffer.hiResPixels[y][x]
            if pixel != 0 { // Non-black
                brailleValue |= UInt8(1 << dot.bit)
                colorCounts[pixel, default: 0] += 1
            }
        }

        // Find most common non-black color
        if let (color, _) = colorCounts.max(by: { $0.value < $1.value }) {
            dominantColor = color
        }

        // Unicode braille base: U+2800
        let scalar = Unicode.Scalar(0x2800 + UInt32(brailleValue))
        let char = Character(scalar!)

        if brailleValue == 0 {
            return (" ", nil) // All black — use space, no color
        }
        let rgb = AppleIIColors.hiRes[Int(dominantColor)]
        return (char, rgb)
    }
}
