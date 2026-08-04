import Foundation
import ApplesoftBASICLib

/// Applesoft BASIC Interpreter — CLI entry point.
///
/// Usage:
///   applesoft              — Launch interactive REPL
///   applesoft filename.bas — Execute a BASIC program file
func main() {
    let args = CommandLine.arguments

    if args.count > 1 {
        // File mode
        let filename = args[1]
        runFile(filename)
    } else {
        // REPL mode
        runREPL()
    }
}

// MARK: - File Execution

func runFile(_ filename: String) {
    let path = (filename as NSString).expandingTildeInPath
    guard FileManager.default.fileExists(atPath: path) else {
        printError("?FILE NOT FOUND: \(filename)")
        return
    }
    guard let source = try? String(contentsOfFile: path, encoding: .utf8) else {
        printError("?UNABLE TO READ: \(filename)")
        return
    }

    do {
        var lexer = Lexer(source: source)
        let tokens = try lexer.tokenize()
        var parser = Parser(tokens: tokens)
        let program = try parser.parse()
        let interpreter = Interpreter(program: program)
        try interpreter.run()
    } catch let error as BASICError {
        printError(error.applesoftMessage)
    } catch {
        printError("?ERROR: \(error)")
    }
}

// MARK: - REPL

func runREPL() {
    print("""
    APPLESOFT BASIC INTERPRETER v\(ApplesoftBASICLib.version)
    SWIFT EDITION — APPLE'S 50TH BIRTHDAY
    \(memorySizeMessage())
    READY.
    """)

    var programLines: [Int: String] = [:]

    while true {
        Swift.print("]", terminator: "")
        guard let line = readLine() else { break }

        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { continue }

        // Check for direct commands
        let upper = trimmed.uppercased()

        if upper == "RUN" {
            runProgram(programLines)
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
            print()
            continue
        }
        if upper.hasPrefix("DEL ") {
            deleteLines(&programLines, range: String(upper.dropFirst(4)))
            continue
        }
        if upper == "BYE" || upper == "QUIT" || upper == "EXIT" {
            break
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
        executeDirect(trimmed, programLines: programLines)
    }
}

func runProgram(_ programLines: [Int: String]) {
    let source = programLines.keys.sorted()
        .compactMap { programLines[$0] }
        .joined(separator: "\n")

    guard !source.isEmpty else {
        print()
        return
    }

    do {
        var lexer = Lexer(source: source)
        let tokens = try lexer.tokenize()
        var parser = Parser(tokens: tokens)
        let program = try parser.parse()
        let interpreter = Interpreter(program: program)
        try interpreter.run()
    } catch let error as BASICError {
        printError(error.applesoftMessage)
    } catch {
        printError("?ERROR: \(error)")
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
                print(line)
            }
        }
    } else {
        for key in sortedKeys {
            if let line = programLines[key] {
                print(line)
            }
        }
    }
    print()
}

func deleteLines(_ programLines: inout [Int: String], range: String) {
    let parts = range.split(separator: "-")
    let start = Int(parts.first ?? "") ?? 0
    let end = parts.count > 1 ? (Int(parts.last ?? "") ?? start) : start

    for key in programLines.keys where key >= start && key <= end {
        programLines.removeValue(forKey: key)
    }
}

func executeDirect(_ line: String, programLines: [Int: String]) {
    // Wrap in a dummy line number for parsing
    let source = "0 \(line)"
    do {
        var lexer = Lexer(source: source)
        let tokens = try lexer.tokenize()
        var parser = Parser(tokens: tokens)
        let program = try parser.parse()
        let interpreter = Interpreter(program: program)
        try interpreter.run()
    } catch let error as BASICError {
        printError(error.applesoftMessage)
    } catch {
        printError("?ERROR: \(error)")
    }
}

func memorySizeMessage() -> String {
    "\(48 * 1024) BYTES FREE"  // Classic Apple II had 48K
}

func printError(_ message: String) {
    print(message)
}

// MARK: - Entry Point

main()
