import Foundation
import AVFoundation
import MP2Assets

/// PlaySound path — AVAudioEngine replacement for libaudio + AI DMA.
public final class AudioEngine: @unchecked Sendable {
    private let engine = AVAudioEngine()
    private var players: [AVAudioPlayerNode] = []
    private var buffers: [Int: AVAudioPCMBuffer] = [:]
    private let lock = NSLock()

    public init() {
        for _ in 0..<8 {
            let node = AVAudioPlayerNode()
            players.append(node)
            engine.attach(node)
            engine.connect(node, to: engine.mainMixerNode, format: nil)
        }
        try? engine.start()
    }

    public func loadWAV(index: Int, url: URL) {
        guard let file = try? AVAudioFile(forReading: url),
              let buf = AVAudioPCMBuffer(
                pcmFormat: file.processingFormat,
                frameCapacity: AVAudioFrameCount(file.length)
              ) else { return }
        try? file.read(into: buf)
        lock.lock()
        buffers[index] = buf
        lock.unlock()
    }

    public func playSound(_ index: Int) {
        lock.lock()
        let buffer = buffers[index]
        lock.unlock()
        guard let buffer else { return }
        guard let node = players.first(where: { !$0.isPlaying }) ?? players.first else { return }
        node.scheduleBuffer(buffer, completionHandler: nil)
        node.play()
    }

    public func playCharacterSound(_ index: Int, character: Int) {
        playSound(index * 10 + character)
    }

    public func stopAll() {
        for p in players { p.stop() }
    }

    public func mixFrame() {
        // Per-frame mix hook — alAudioFrame equivalent; AVAudioEngine runs asynchronously.
    }
}
