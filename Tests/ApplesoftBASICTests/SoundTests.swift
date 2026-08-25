import SwiftDeterminism
import Testing
@testable import ApplesoftBASICLib

/// Test spy that records sound calls.
// Justification: Test-only spy; each test creates its own instance and accesses it from a single task, so no concurrent mutation occurs.
final class SpySoundHandler: SoundHandler, @unchecked Sendable {
    var beepCount = 0
    var tones: [(frequency: Double, duration: Double)] = []

    func beep() { beepCount += 1 }
    func playTone(frequency: Double, duration: Double) {
        tones.append((frequency, duration))
    }
}

@Suite("Sound")
struct SoundTests {

    // MARK: - Helper

    private func run(_ source: String, sound: SpySoundHandler = SpySoundHandler()) throws -> (CapturedOutput, SpySoundHandler) {
        var lexer = Lexer(source: source)
        let tokens = try lexer.tokenize()
        var parser = Parser(tokens: tokens)
        let program = try parser.parse()
        let output = CapturedOutput()
        var rng = SplitMix64(seed: 42)
        let interpreter = Interpreter(
            program: program, output: output,
            input: ScriptedInput(), sound: sound,
            rng: &rng
        )
        try interpreter.run()
        return (output, sound)
    }

    // MARK: - MutedSoundHandler

    @Test("MutedSoundHandler does not crash")
    func mutedNoCrash() {
        let muted = MutedSoundHandler()
        muted.beep()
        muted.playTone(frequency: 440, duration: 0.5)
        var completed = false
        completed = true
        #expect(completed)
    }

    // MARK: - BEEP Statement

    @Test("BEEP calls sound.beep()")
    func beepStatement() throws {
        let spy = SpySoundHandler()
        let (_, sound) = try run("10 BEEP\n20 END", sound: spy)
        #expect(sound.beepCount == 1)
    }

    @Test("Multiple BEEPs")
    func multipleBeeeps() throws {
        let spy = SpySoundHandler()
        let source = """
        10 BEEP
        20 BEEP
        30 BEEP
        40 END
        """
        let (_, sound) = try run(source, sound: spy)
        #expect(sound.beepCount == 3)
    }

    // MARK: - SOUND Statement

    @Test("SOUND calls playTone with correct values")
    func soundStatement() throws {
        let spy = SpySoundHandler()
        let (_, sound) = try run("10 SOUND 440,0.5\n20 END", sound: spy)
        #expect(sound.tones.count == 1)
        #expect(abs(sound.tones[0].frequency - 440) < 0.01)
        #expect(abs(sound.tones[0].duration - 0.5) < 0.01)
    }

    @Test("SOUND with expression arguments")
    func soundExpressions() throws {
        let spy = SpySoundHandler()
        let source = """
        10 LET F = 880
        20 SOUND F,0.25
        30 END
        """
        let (_, sound) = try run(source, sound: spy)
        #expect(abs(sound.tones[0].frequency - 880) < 0.01)
    }

    @Test("SOUND with negative frequency throws")
    func soundNegativeFreq() {
        let spy = SpySoundHandler()
        #expect(throws: BASICError.self) {
            try run("10 SOUND -1,0.5\n20 END", sound: spy)
        }
    }

    @Test("SOUND with negative duration throws")
    func soundNegativeDur() {
        let spy = SpySoundHandler()
        #expect(throws: BASICError.self) {
            try run("10 SOUND 440,-1\n20 END", sound: spy)
        }
    }

    // MARK: - CHR$(7) BEL Detection

    @Test("PRINT CHR$(7) triggers beep")
    func chrSevenBeep() throws {
        let spy = SpySoundHandler()
        let (_, sound) = try run("10 PRINT CHR$(7)\n20 END", sound: spy)
        #expect(sound.beepCount == 1)
    }
}
