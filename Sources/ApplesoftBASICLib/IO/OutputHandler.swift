import Synchronization

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
public final class ConsoleOutput: OutputHandler, Sendable {

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
public final class CapturedOutput: OutputHandler, Sendable {
    private let _text = Mutex<String>("")

    /// All text that has been output, in order.
    public var text: String {
        _text.withLock { $0 }
    }

    /// Each complete line that has been output.
    public var lines: [String] {
        let current = text
        guard !current.isEmpty else { return [] }
        let result = current
            .split(omittingEmptySubsequences: false, whereSeparator: \.isNewline)
            .map(String.init)
        if current.last?.isNewline == true {
            return Array(result.dropLast())
        }
        return result
    }

    /// Creates an empty captured output buffer.
    public init() {}

    /// Appends text to the buffer.
    public func print(_ text: String) {
        _text.withLock { $0 += text }
    }

    /// Appends text plus a newline to the buffer.
    public func printLine(_ text: String) {
        _text.withLock { $0 += text + "\n" }
    }

    /// Clears the buffer (simulates HOME).
    public func clearScreen() {
        _text.withLock { $0 = "" }
    }
}
