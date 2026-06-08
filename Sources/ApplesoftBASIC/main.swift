import Foundation
import os
import ApplesoftBASICLib
#if canImport(CLineEditor)
import CLineEditor
#endif

private let logger = Logger(subsystem: "com.applesoftbasic", category: "repl")

/// Applesoft BASIC Interpreter — CLI entry point.
///
/// Usage:
///   applesoft              — Launch interactive REPL
///   applesoft filename.bas — Execute a BASIC program file
func main<RNG: RandomNumberGenerator & Sendable>(rng: inout RNG) {
    let args = CommandLine.arguments

    if args.count > 1 {
        // File mode
        let filename = args[1]
        runFile(filename, rng: &rng)
    } else {
        // REPL mode
        runREPL(rng: &rng)
    }
}

// MARK: - File Execution

func runFile<RNG: RandomNumberGenerator & Sendable>(_ filename: String, rng: inout RNG) {
    let fileURL = URL(fileURLWithPath: (filename as NSString).expandingTildeInPath).standardized
    guard !fileURL.pathComponents.contains("..") else {
        replOutput("?INVALID PATH: \(filename)")
        return
    }
    guard (try? fileURL.checkResourceIsReachable()) == true else { // silent: reachability check — failure handled by guard
        replOutput("?FILE NOT FOUND: \(filename)")
        return
    }
    do {
        let source = try String(contentsOf: fileURL, encoding: .utf8)

        var lexer = Lexer(source: source)
        let tokens = try lexer.tokenize()
        var parser = Parser(tokens: tokens)
        let program = try parser.parse()
        #if canImport(AVFoundation)
        let sound: any SoundHandler = AudioSoundHandler()
        #else
        let sound: any SoundHandler = MutedSoundHandler()
        #endif
        let interpreter = Interpreter(program: program, sound: sound, rng: &rng)
        try interpreter.run()
    } catch let error as BASICError {
        logger.error("\(error.applesoftMessage, privacy: .public)")
    } catch {
        logger.error("?ERROR: \(error, privacy: .public)")
    }
}

// MARK: - Line Editor

/// Reads a line from the terminal using editline, with history and editing support.
/// Returns nil on EOF (Ctrl+D).
func readLineWithEditor(prompt: String) -> String? {
    #if canImport(CLineEditor)
    guard let cString = readline(prompt) else {
        return nil
    }
    let line = String(cString: cString)
    if !line.trimmingCharacters(in: .whitespaces).isEmpty {
        add_history(cString)
    }
    free(cString)
    return line
    #else
    Swift.print(prompt, terminator: "")
    return Swift.readLine()
    #endif
}

// MARK: - REPL Output

func replOutput(_ text: String) {
    Swift.print(text)
}

// MARK: - REPL

func runREPL<RNG: RandomNumberGenerator & Sendable>(rng: inout RNG) {
    replOutput("""
    APPLESOFT BASIC INTERPRETER v\(ApplesoftBASICLib.version)
    SWIFT EDITION — APPLE'S 50TH BIRTHDAY
    \(memorySizeMessage())
    READY.
    """)

    var programLines: [Int: String] = [:]
    var running = true

    while running {
        guard let line = readLineWithEditor(prompt: "]") else {
            replOutput("")
            running = false
            continue
        }

        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { continue }

        // Check for direct commands
        let upper = trimmed.uppercased()

        if upper == "RUN" {
            runProgram(programLines, rng: &rng)
            continue
        }
        if upper == "LIST" {
            listProgram(programLines)
            continue
        }
        if upper.hasPrefix("LIST ") {
            listProgram(programLines, range: String(upper.dropFirst(5)))
            continue
        }
        if upper == "NEW" {
            programLines.removeAll()
            replOutput("")
            continue
        }
        if upper.hasPrefix("DEL ") {
            deleteLines(&programLines, range: String(upper.dropFirst(4)))
            continue
        }
        if upper == "BYE" || upper == "QUIT" || upper == "EXIT" {
            running = false
            continue
        }

        // Check if it starts with a line number
        if let firstChar = trimmed.first, firstChar.isNumber {
            // Extract line number
            var numStr = ""
            var rest = trimmed[trimmed.startIndex...]
            while let char = rest.first, char.isNumber {
                numStr.append(char)
                rest = rest.dropFirst()
            }
            if let lineNum = Int(numStr) {
                let lineContent = String(rest).trimmingCharacters(in: .whitespaces)
                if lineContent.isEmpty {
                    // Delete line
                    programLines.removeValue(forKey: lineNum)
                } else {
                    // Store line
                    programLines[lineNum] = "\(lineNum) \(lineContent)"
                }
                continue
            }
        }

        // Direct execution (no line number)
        executeDirect(trimmed, programLines: programLines, rng: &rng)
    }
}

func runProgram<RNG: RandomNumberGenerator & Sendable>(_ programLines: [Int: String], rng: inout RNG) {
    let source = programLines.keys.sorted()
        .compactMap { programLines[$0] }
        .joined(separator: "\n")

    guard !source.isEmpty else {
        replOutput("")
        return
    }

    do {
        var lexer = Lexer(source: source)
        let tokens = try lexer.tokenize()
        var parser = Parser(tokens: tokens)
        let program = try parser.parse()
        let interpreter = Interpreter(program: program, rng: &rng)
        try interpreter.run()
    } catch let error as BASICError {
        logger.error("\(error.applesoftMessage, privacy: .public)")
    } catch {
        logger.error("?ERROR: \(error, privacy: .public)")
    }
}

func listProgram(_ programLines: [Int: String], range: String? = nil) {
    let sortedKeys = programLines.keys.sorted()

    if let range {
        let parts = range.split(separator: "-")
        let start = Int(parts.first ?? "") ?? 0
        let end = parts.count > 1 ? (Int(parts.last ?? "") ?? Int.max) : start

        for key in sortedKeys where key >= start && key <= end {
            if let line = programLines[key] {
                replOutput(line)
            }
        }
    } else {
        for key in sortedKeys {
            if let line = programLines[key] {
                replOutput(line)
            }
        }
    }
    replOutput("")
}

func deleteLines(_ programLines: inout [Int: String], range: String) {
    let parts = range.split(separator: "-")
    let start = Int(parts.first ?? "") ?? 0
    let end = parts.count > 1 ? (Int(parts.last ?? "") ?? start) : start

    for key in programLines.keys where key >= start && key <= end {
        programLines.removeValue(forKey: key)
    }
}

func executeDirect<RNG: RandomNumberGenerator & Sendable>(_ line: String, programLines: [Int: String], rng: inout RNG) {
    // Wrap in a dummy line number for parsing
    let source = "0 \(line)"
    do {
        var lexer = Lexer(source: source)
        let tokens = try lexer.tokenize()
        var parser = Parser(tokens: tokens)
        let program = try parser.parse()
        let interpreter = Interpreter(program: program, rng: &rng)
        try interpreter.run()
    } catch let error as BASICError {
        logger.error("\(error.applesoftMessage, privacy: .public)")
    } catch {
        logger.error("?ERROR: \(error, privacy: .public)")
    }
}

func memorySizeMessage() -> String {
    "\(48 * 1024) BYTES FREE"  // Classic Apple II had 48K
}

// MARK: - Entry Point

var entryRNG: SystemRandomNumberGenerator = .init()
main(rng: &entryRNG)
