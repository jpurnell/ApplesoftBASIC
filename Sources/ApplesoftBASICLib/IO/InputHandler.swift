import Synchronization

/// Abstraction for user input — enables scripted input in tests.
public protocol InputHandler: AnyObject, Sendable {
    /// Reads a line of input, optionally displaying a prompt.
    func readLine(prompt: String) -> String?

    /// Reads a single character (for GET statement).
    func getChar() -> Character?
}

/// Default input handler that reads from standard input.
public final class ConsoleInput: InputHandler, Sendable {

    /// Creates a console input handler that reads from stdin.
    public init() {}

    /// Displays the prompt and reads a line from standard input.
    public func readLine(prompt: String) -> String? {
        Swift.print(prompt, terminator: "")
        return Swift.readLine()
    }

    /// Reads a line from stdin and returns the first character.
    public func getChar() -> Character? {
        // Simple implementation: read a line and take the first character
        guard let line = Swift.readLine(), let first = line.first else {
            return nil
        }
        return first
    }
}

/// Test double that provides scripted input responses.
public final class ScriptedInput: InputHandler, Sendable {
    private struct State: Sendable {
        var responses: [String]
        var charResponses: [Character]
        var responseIndex = 0
        var charIndex = 0
        var receivedPrompts: [String] = []
    }

    private let state: Mutex<State>

    /// The prompts that were displayed, for verification.
    public var receivedPrompts: [String] {
        state.withLock { $0.receivedPrompts }
    }

    /// Creates a scripted input handler with predefined responses.
    ///
    /// - Parameters:
    ///   - responses: Responses to return for `readLine` calls, in order.
    ///   - charResponses: Characters to return for `getChar` calls, in order.
    public init(responses: [String] = [], charResponses: [Character] = []) {
        self.state = Mutex(State(responses: responses, charResponses: charResponses))
    }

    /// Returns the next scripted response, or nil if exhausted.
    public func readLine(prompt: String) -> String? {
        state.withLock { s in
            s.receivedPrompts.append(prompt)
            guard s.responseIndex < s.responses.count else { return nil }
            let response = s.responses[s.responseIndex]
            s.responseIndex += 1
            return response
        }
    }

    /// Returns the next scripted character, or nil if exhausted.
    public func getChar() -> Character? {
        state.withLock { s in
            guard s.charIndex < s.charResponses.count else { return nil }
            let char = s.charResponses[s.charIndex]
            s.charIndex += 1
            return char
        }
    }
}
