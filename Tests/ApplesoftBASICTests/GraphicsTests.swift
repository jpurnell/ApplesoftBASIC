import Foundation
import Testing
@testable import ApplesoftBASICLib

@Suite("Graphics")
struct GraphicsTests {

    // MARK: - Helper

    private func run(_ source: String, maxSteps: Int = 100_000) throws -> CapturedOutput {
        var lexer = Lexer(source: source)
        let tokens = try lexer.tokenize()
        var parser = Parser(tokens: tokens)
        let program = try parser.parse()
        let output = CapturedOutput()
        var rng = SeededGenerator(seed: 42)
        let interpreter = Interpreter(
            program: program, output: output,
            input: ScriptedInput(), maxSteps: maxSteps,
            rng: &rng
        )
        try interpreter.run()
        return output
    }

    // MARK: - GraphicsBuffer Unit Tests

    @Test("GraphicsBuffer starts in text mode")
    func initialMode() {
        let buf = GraphicsBuffer()
        #expect(buf.mode == .text)
    }

    @Test("GR switches to loRes mode")
    func grMode() {
        let buf = GraphicsBuffer()
        buf.switchToLoRes()
        #expect(buf.mode == .loRes)
    }

    @Test("HGR switches to hiRes mode")
    func hgrMode() {
        let buf = GraphicsBuffer()
        buf.switchToHiRes()
        #expect(buf.mode == .hiRes)
    }

    @Test("HGR2 switches to hiResFull mode")
    func hgr2Mode() {
        let buf = GraphicsBuffer()
        buf.switchToHiResFull()
        #expect(buf.mode == .hiResFull)
    }

    @Test("TEXT returns to text mode")
    func textMode() {
        let buf = GraphicsBuffer()
        buf.switchToLoRes()
        buf.switchToText()
        #expect(buf.mode == .text)
    }

    @Test("PLOT sets correct pixel")
    func plotPixel() throws {
        let buf = GraphicsBuffer()
        buf.setColor(5)
        try buf.plot(x: 10, y: 20)
        #expect(buf.loResPixels[20][10] == 5)
    }

    @Test("PLOT out of range throws")
    func plotOutOfRange() {
        let buf = GraphicsBuffer()
        #expect(throws: BASICError.self) {
            try buf.plot(x: 40, y: 0)
        }
        #expect(throws: BASICError.self) {
            try buf.plot(x: 0, y: 48)
        }
        #expect(throws: BASICError.self) {
            try buf.plot(x: -1, y: 0)
        }
    }

    @Test("HLIN draws horizontal line")
    func hlinLine() throws {
        let buf = GraphicsBuffer()
        buf.setColor(3)
        try buf.hlin(x1: 5, x2: 15, y: 10)
        for x in 5...15 {
            #expect(buf.loResPixels[10][x] == 3)
        }
        #expect(buf.loResPixels[10][4] == 0)
        #expect(buf.loResPixels[10][16] == 0)
    }

    @Test("VLIN draws vertical line")
    func vlinLine() throws {
        let buf = GraphicsBuffer()
        buf.setColor(7)
        try buf.vlin(y1: 5, y2: 15, x: 20)
        for y in 5...15 {
            #expect(buf.loResPixels[y][20] == 7)
        }
        #expect(buf.loResPixels[4][20] == 0)
        #expect(buf.loResPixels[16][20] == 0)
    }

    @Test("SCRN reads correct pixel value")
    func scrnRead() throws {
        let buf = GraphicsBuffer()
        buf.setColor(12)
        try buf.plot(x: 5, y: 5)
        #expect(try buf.scrn(x: 5, y: 5) == 12)
        #expect(try buf.scrn(x: 0, y: 0) == 0)
    }

    @Test("HPLOT sets correct hi-res pixel")
    func hplotPixel() throws {
        let buf = GraphicsBuffer()
        buf.setHColor(3)
        try buf.hplot(x: 100, y: 50)
        #expect(buf.hiResPixels[50][100] == 3)
        #expect(buf.lastHPlotX == 100)
        #expect(buf.lastHPlotY == 50)
    }

    @Test("HPLOT out of range throws")
    func hplotOutOfRange() {
        let buf = GraphicsBuffer()
        #expect(throws: BASICError.self) {
            try buf.hplot(x: 280, y: 0)
        }
        #expect(throws: BASICError.self) {
            try buf.hplot(x: 0, y: 192)
        }
    }

    @Test("Bresenham horizontal line")
    func bresenhamHorizontal() throws {
        let buf = GraphicsBuffer()
        buf.setHColor(1)
        try buf.hplotLine(x1: 10, y1: 50, x2: 20, y2: 50)
        for x in 10...20 {
            #expect(buf.hiResPixels[50][x] == 1)
        }
    }

    @Test("Bresenham vertical line")
    func bresenhamVertical() throws {
        let buf = GraphicsBuffer()
        buf.setHColor(2)
        try buf.hplotLine(x1: 50, y1: 10, x2: 50, y2: 30)
        for y in 10...30 {
            #expect(buf.hiResPixels[y][50] == 2)
        }
    }

    @Test("Bresenham diagonal line")
    func bresenhamDiagonal() throws {
        let buf = GraphicsBuffer()
        buf.setHColor(5)
        try buf.hplotLine(x1: 0, y1: 0, x2: 10, y2: 10)
        // All points on diagonal should be set
        for i in 0...10 {
            #expect(buf.hiResPixels[i][i] == 5)
        }
    }

    @Test("HSCRN reads hi-res pixel")
    func hscrnRead() throws {
        let buf = GraphicsBuffer()
        buf.setHColor(6)
        try buf.hplot(x: 200, y: 100)
        #expect(try buf.hscrn(x: 200, y: 100) == 6)
        #expect(try buf.hscrn(x: 0, y: 0) == 0)
    }

    @Test("Dirty tracking works for lo-res")
    func dirtyTracking() throws {
        let buf = GraphicsBuffer()
        buf.setColor(1)
        try buf.plot(x: 0, y: 5)
        #expect(buf.dirtyLoResRows.contains(5))
        buf.clearDirty()
        #expect(buf.dirtyLoResRows.isEmpty)
    }

    // MARK: - GraphicsRenderer Tests

    @Test("Lo-res renderer produces output with ANSI color")
    func loResRender() {
        let buf = GraphicsBuffer()
        buf.setColor(15) // White
        try? buf.plot(x: 0, y: 0)
        let rendered = GraphicsRenderer.renderLoRes(buf)
        // Should contain ANSI escape for white (255;255;255)
        #expect(rendered.contains("255;255;255"))
        // Should contain the half-block character
        #expect(rendered.contains("\u{2580}"))
    }

    @Test("Hi-res renderer produces output with braille characters")
    func hiResRender() {
        let buf = GraphicsBuffer()
        buf.setHColor(1) // Green
        try? buf.hplot(x: 0, y: 0)
        let rendered = GraphicsRenderer.renderHiRes(buf)
        // Should contain ANSI escape for green (20;245;60)
        #expect(rendered.contains("20;245;60"))
    }

    @Test("Lo-res dirty renderer only renders dirty rows")
    func loResDirtyRender() throws {
        let buf = GraphicsBuffer()
        buf.clearDirty() // Clear initial dirty state
        buf.setColor(1)
        try buf.plot(x: 5, y: 10)
        let rendered = GraphicsRenderer.renderLoResDirty(buf)
        // Should position cursor at terminal row 6 (lo-res row 10 / 2 + 1)
        #expect(rendered.contains("[6;1H"))
    }

    // MARK: - Color Palette Tests

    @Test("Lo-res palette has 16 colors")
    func loResPaletteCount() {
        #expect(AppleIIColors.loRes.count == 16)
    }

    @Test("Hi-res palette has 8 colors")
    func hiResPaletteCount() {
        #expect(AppleIIColors.hiRes.count == 8)
    }

    @Test("Lo-res black is 0,0,0")
    func loResBlack() {
        let black = AppleIIColors.loRes[0]
        #expect(black.r == 0 && black.g == 0 && black.b == 0)
    }

    @Test("Lo-res white is 255,255,255")
    func loResWhite() {
        let white = AppleIIColors.loRes[15]
        #expect(white.r == 255 && white.g == 255 && white.b == 255)
    }

    // MARK: - Integration Tests

    @Test("GR and PLOT program runs")
    func grPlotProgram() throws {
        let source = """
        10 GR
        20 COLOR= 12
        30 PLOT 20,24
        40 TEXT
        50 END
        """
        let output = try run(source)
        // Should produce ANSI color output
        #expect(output.text.contains("\u{1B}["))
    }

    @Test("HLIN program runs")
    func hlinProgram() throws {
        let source = """
        10 GR
        20 COLOR= 9
        30 HLIN 0,39 AT 24
        40 TEXT
        50 END
        """
        let output = try run(source)
        #expect(output.text.contains("\u{2580}"))
    }

    @Test("HGR and HPLOT program runs")
    func hgrHplotProgram() throws {
        let source = """
        10 HGR
        20 HCOLOR= 1
        30 HPLOT 0,0 TO 100,100
        40 END
        """
        let output = try run(source)
        #expect(output.text.contains("\u{1B}["))
    }

    @Test("SCRN function returns correct value in program")
    func scrnInProgram() throws {
        let source = """
        10 GR
        20 COLOR= 7
        30 PLOT 5,5
        40 TEXT
        50 PRINT SCRN(5,5)
        60 END
        """
        let output = try run(source)
        #expect(output.text.contains("7"))
    }

    @Test("HSCRN function returns correct value in program")
    func hscrnInProgram() throws {
        let source = """
        10 HGR
        20 HCOLOR= 3
        30 HPLOT 100,50
        40 PRINT HSCRN(100,50)
        50 END
        """
        let output = try run(source)
        #expect(output.text.contains("3"))
    }
}
