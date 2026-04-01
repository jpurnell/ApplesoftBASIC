/// Abstraction for PRINT output — enables capturing output in tests.
public protocol OutputHandler: AnyObject, Sendable {
    /// Prints text without a trailing newline.
    func print(_ text: String)

    /// Prints text followed by a newline.
    func printLine(_ text: String)

    /// Clears the screen (HOME command).
    func clearScreen()
}

/// Default output handler that writes to standard output.
public final class ConsoleOutput: OutputHandler, @unchecked Sendable {

    public init() {}

    public func print(_ text: String) {
        Swift.print(text, terminator: "")
    }

    public func printLine(_ text: String) {
        Swift.print(text)
    }

    public func clearScreen() {
        // ANSI escape: clear screen and move cursor to top-left
        Swift.print("\u{1B}[2J\u{1B}[H", terminator: "")
    }
}

/// Test double that captures all output for verification.
public final class CapturedOutput: OutputHandler, @unchecked Sendable {
    /// All text that has been output, in order.
    public private(set) var text: String = ""

    /// Each complete line that has been output.
    public var lines: [String] {
        guard !text.isEmpty else { return [] }
        let result = text.split(separator: "\n", omittingEmptySubsequences: false)
            .map(String.init)
        // If text ends with newline, the last empty element is trailing
        if text.hasSuffix("\n") {
            return Array(result.dropLast())
        }
        return result
    }

    public init() {}

    public func print(_ text: String) {
        self.text += text
    }

    public func printLine(_ text: String) {
        self.text += text + "\n"
    }

    public func clearScreen() {
        self.text = ""
    }
}
