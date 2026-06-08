import Foundation
import os
import Synchronization

private let soundLogger = Logger(subsystem: "com.applesoftbasic", category: "sound")

/// Abstraction for sound output — enables muting in tests.
public protocol SoundHandler: AnyObject, Sendable {
    /// Plays a short beep tone (~880Hz, ~150ms).
    func beep()

    /// Plays a tone at the given frequency for the given duration.
    ///
    /// - Parameters:
    ///   - frequency: Tone frequency in Hz (clamped to 20-20000).
    ///   - duration: Duration in seconds (clamped to 0.001-30).
    func playTone(frequency: Double, duration: Double)
}

/// Silent sound handler — used in tests and when audio is unavailable.
public final class MutedSoundHandler: SoundHandler, Sendable {
    /// Creates a muted sound handler that produces no audio.
    public init() {}

    /// No-op. Stores nothing for a single beep.
    public func beep() {}

    /// No-op. Stores nothing for a play tone.
    public func playTone(frequency: Double, duration: Double) {}
}

/// Sound handler that emits terminal BEL character for beep.
/// Fallback when AVAudioEngine is not available.
public final class TerminalBellSoundHandler: SoundHandler, Sendable {
    private let output: any OutputHandler

    /// Creates a terminal bell sound handler.
    ///
    /// - Parameter output: The output handler to send BEL characters to.
    public init(output: any OutputHandler) {
        self.output = output
    }

    /// Sends a BEL character to the output handler.
    public func beep() {
        output.print("\u{07}")
    }

    /// No-op — terminal bell cannot produce arbitrary tones.
    public func playTone(frequency: Double, duration: Double) {}
}

#if canImport(AVFoundation)
@preconcurrency import AVFoundation

/// Produces square-wave tones via AVAudioEngine.
public final class AudioSoundHandler: SoundHandler, Sendable {
    /// Mutable state protected by a single Mutex.
    // Justification: AVAudioEngine/AVAudioSourceNode are not Sendable but access is serialized by Mutex.
    private struct EngineState: @unchecked Sendable {
        var audioEngine: AVAudioEngine?
        var sourceNode: AVAudioSourceNode?
    }

    /// Render state shared with the audio callback, protected by its own Mutex.
    private struct RenderState: Sendable {
        var phase: Double = 0.0
        var currentFrequency: Double = 440.0
    }

    private let engineState = Mutex<EngineState>(EngineState())
    private let renderState = Mutex<RenderState>(RenderState())

    /// Creates an audio sound handler using AVAudioEngine.
    public init() {}

    /// Plays a short 880Hz beep.
    public func beep() {
        playTone(frequency: 880, duration: 0.15)
    }

    /// Plays a square-wave tone at the specified frequency.
    /// Blocks for the full duration of the tone.
    public func playTone(frequency: Double, duration: Double) {
        let freq = max(20, min(frequency, 20000))
        let dur = max(0.001, min(duration, 30))

        renderState.withLock { s in
            s.currentFrequency = freq
            s.phase = 0.0
        }

        startEngine()
        Thread.sleep(forTimeInterval: dur)
        stopEngine()
    }

    private func startEngine() {
        engineState.withLock { es in
            stopEngineUnsafe(&es)

            let engine = AVAudioEngine()
            let sampleRate = engine.outputNode.outputFormat(forBus: 0).sampleRate
            let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)
            guard let format else { return }

            let handler = self
            let node = AVAudioSourceNode(format: format) { _, _, frameCount, bufferList -> OSStatus in
                let ablPointer = UnsafeMutableAudioBufferListPointer(bufferList)
                handler.renderState.withLock { rs in
                    let increment = rs.currentFrequency / sampleRate

                    for frame in 0..<Int(frameCount) {
                        let sample: Float = rs.phase < 0.5 ? 0.12 : -0.12
                        for buffer in ablPointer {
                            buffer.mData?.assumingMemoryBound(to: Float.self)[frame] = sample
                        }
                        rs.phase += increment
                        if rs.phase >= 1.0 { rs.phase -= 1.0 }
                    }
                }
                return noErr
            }

            engine.attach(node)
            engine.connect(node, to: engine.mainMixerNode, format: format)

            do {
                try engine.start()
                es.audioEngine = engine
                es.sourceNode = node
            } catch {
                soundLogger.warning("Audio engine start failed: \(error, privacy: .public)")
            }
        }
    }

    private func stopEngine() {
        engineState.withLock { es in
            stopEngineUnsafe(&es)
        }
    }

    private func stopEngineUnsafe(_ es: inout EngineState) {
        es.audioEngine?.stop()
        if let node = es.sourceNode {
            es.audioEngine?.detach(node)
        }
        es.sourceNode = nil
        es.audioEngine = nil
    }
}
#endif
