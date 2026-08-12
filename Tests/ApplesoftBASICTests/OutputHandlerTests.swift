import Testing
@testable import ApplesoftBASICLib

@Suite("Output Handler")
struct OutputHandlerTests {

    // MARK: - Line splitting

    @Test("Splits on plain newlines")
    func splitsOnNewlines() {
        let output = CapturedOutput()
        output.printLine("FIRST")
        output.printLine("SECOND")

        #expect(output.lines == ["FIRST", "SECOND"])
    }

    @Test("Splits on carriage-return line feed pairs")
    func splitsOnCarriageReturnLineFeed() {
        let output = CapturedOutput()
        output.print("FIRST\r\nSECOND\r\n")

        #expect(output.lines == ["FIRST", "SECOND"])
    }

    @Test("Splits on a bare carriage return")
    func splitsOnBareCarriageReturn() {
        let output = CapturedOutput()
        output.print("FIRST\rSECOND")

        #expect(output.lines == ["FIRST", "SECOND"])
    }

    @Test("Keeps empty lines between terminators")
    func keepsEmptyLines() {
        let output = CapturedOutput()
        output.print("FIRST\n\nSECOND\n")

        #expect(output.lines == ["FIRST", "", "SECOND"])
    }

    @Test("Keeps a trailing partial line")
    func keepsTrailingPartialLine() {
        let output = CapturedOutput()
        output.printLine("FIRST")
        output.print("PARTIAL")

        #expect(output.lines == ["FIRST", "PARTIAL"])
    }

    @Test("Empty buffer has no lines")
    func emptyBufferHasNoLines() {
        #expect(CapturedOutput().lines.isEmpty)
    }

    // MARK: - Buffering

    @Test("Clear screen empties the buffer")
    func clearScreenEmptiesBuffer() {
        let output = CapturedOutput()
        output.printLine("GONE")
        output.clearScreen()

        #expect(output.text.isEmpty)
        #expect(output.lines.isEmpty)
    }
}
