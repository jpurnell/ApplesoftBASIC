import Foundation

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
public final class MutedSoundHandler: SoundHandler, @unchecked Sendable {
    /// Creates a muted sound handler that produces no audio.
    public init() {}

    /// No-op.
    public func beep() {}

    /// No-op.
    public func playTone(frequency: Double, duration: Double) {}
}

/// Sound handler that emits terminal BEL character for beep.
/// Fallback when AVAudioEngine is not available.
public final class TerminalBellSoundHandler: SoundHandler, @unchecked Sendable {
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
import AVFoundation

/// Produces square-wave tones via AVAudioEngine.
public final class AudioSoundHandler: SoundHandler, @unchecked Sendable {
    private var audioEngine: AVAudioEngine?
    private var sourceNode: AVAudioSourceNode?
    private nonisolated(unsafe) var phase: Double = 0.0
    private nonisolated(unsafe) var currentFrequency: Double = 440.0
    private let lock = NSLock()

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

        lock.lock()
        currentFrequency = freq
        phase = 0.0
        lock.unlock()

        startEngine()
        Thread.sleep(forTimeInterval: dur)
        stopEngine()
    }

    private func startEngine() {
        lock.lock()
        defer { lock.unlock() }

        stopEngineUnsafe()

        let engine = AVAudioEngine()
        let sampleRate = engine.outputNode.outputFormat(forBus: 0).sampleRate
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)
        guard let format else { return }

        let node = AVAudioSourceNode(format: format) { [weak self] _, _, frameCount, bufferList -> OSStatus in
            guard let self else { return noErr }
            let ablPointer = UnsafeMutableAudioBufferListPointer(bufferList)
            let freq = self.currentFrequency
            let increment = freq / sampleRate

            for frame in 0..<Int(frameCount) {
                let sample: Float = self.phase < 0.5 ? 0.12 : -0.12
                for buffer in ablPointer {
                    buffer.mData?.assumingMemoryBound(to: Float.self)[frame] = sample
                }
                self.phase += increment
                if self.phase >= 1.0 { self.phase -= 1.0 }
            }
            return noErr
        }

        engine.attach(node)
        engine.connect(node, to: engine.mainMixerNode, format: format)

        do {
            try engine.start()
            self.audioEngine = engine
            self.sourceNode = node
        } catch {
            // Silently fail — sound is non-essential
        }
    }

    private func stopEngine() {
        lock.lock()
        defer { lock.unlock() }
        stopEngineUnsafe()
    }

    private func stopEngineUnsafe() {
        audioEngine?.stop()
        if let node = sourceNode {
            audioEngine?.detach(node)
        }
        sourceNode = nil
        audioEngine = nil
    }
}
#endif
