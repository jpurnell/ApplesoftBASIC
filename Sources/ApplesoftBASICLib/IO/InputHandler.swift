/// Abstraction for user input — enables scripted input in tests.
public protocol InputHandler: AnyObject, Sendable {
    /// Reads a line of input, optionally displaying a prompt.
    func readLine(prompt: String) -> String?

    /// Reads a single character (for GET statement).
    func getChar() -> Character?
}

/// Default input handler that reads from standard input.
public final class ConsoleInput: InputHandler, @unchecked Sendable {

    public init() {}

    public func readLine(prompt: String) -> String? {
        Swift.print(prompt, terminator: "")
        return Swift.readLine()
    }

    public func getChar() -> Character? {
        // Simple implementation: read a line and take the first character
        guard let line = Swift.readLine(), let first = line.first else {
            return nil
        }
        return first
    }
}

/// Test double that provides scripted input responses.
public final class ScriptedInput: InputHandler, @unchecked Sendable {
    private var responses: [String]
    private var charResponses: [Character]
    private var responseIndex = 0
    private var charIndex = 0

    /// The prompts that were displayed, for verification.
    public private(set) var receivedPrompts: [String] = []

    /// Creates a scripted input handler with predefined responses.
    ///
    /// - Parameters:
    ///   - responses: Responses to return for `readLine` calls, in order.
    ///   - charResponses: Characters to return for `getChar` calls, in order.
    public init(responses: [String] = [], charResponses: [Character] = []) {
        self.responses = responses
        self.charResponses = charResponses
    }

    public func readLine(prompt: String) -> String? {
        receivedPrompts.append(prompt)
        guard responseIndex < responses.count else { return nil }
        let response = responses[responseIndex]
        responseIndex += 1
        return response
    }

    public func getChar() -> Character? {
        guard charIndex < charResponses.count else { return nil }
        let char = charResponses[charIndex]
        charIndex += 1
        return char
    }
}
