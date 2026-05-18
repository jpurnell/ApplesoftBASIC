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
// Justification: Stateless — all methods delegate to Swift.print() which is thread-safe.
public final class ConsoleOutput: OutputHandler, @unchecked Sendable {

    /// Creates a console output handler that writes to stdout.
    public init() {}

    /// Writes text to stdout without a trailing newline.
    public func print(_ text: String) {
        Swift.print(text, terminator: "")
    }

    /// Writes text to stdout followed by a newline.
    public func printLine(_ text: String) {
        Swift.print(text)
    }

    /// Clears the terminal using ANSI escape sequences.
    public func clearScreen() {
        Swift.print("\u{1B}[2J\u{1B}[H", terminator: "")
    }
}

/// Test double that captures all output for verification.
// Justification: Only used within single-threaded test execution; no concurrent access.
public final class CapturedOutput: OutputHandler, @unchecked Sendable {
    /// All text that has been output, in order.
    public private(set) var text: String = ""

    /// Each complete line that has been output.
    public var lines: [String] {
        guard !text.isEmpty else { return [] }
        let result = text.split(separator: "\n", omittingEmptySubsequences: false)
            .map(String.init)
        if text.hasSuffix("\n") {
            return Array(result.dropLast())
        }
        return result
    }

    /// Creates an empty captured output buffer.
    public init() {}

    /// Appends text to the buffer.
    public func print(_ text: String) {
        self.text += text
    }

    /// Appends text plus a newline to the buffer.
    public func printLine(_ text: String) {
        self.text += text + "\n"
    }

    /// Clears the buffer (simulates HOME).
    public func clearScreen() {
        self.text = ""
    }
}
