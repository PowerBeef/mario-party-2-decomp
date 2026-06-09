import Foundation

#if os(macOS)
import CoreVideo
#endif
#if os(iOS)
import UIKit
#endif

/// VI retrace replacement — 60 Hz NTSC frame clock.
public class FrameClock: @unchecked Sendable {
    public private(set) var frameIndex: UInt64 = 0
    public let targetFrameDuration: TimeInterval = 1.0 / 60.0

    private var continuations: [CheckedContinuation<Void, Never>] = []
    private let lock = NSLock()

    #if os(macOS)
    private var displayLink: CVDisplayLink?
    #endif

    public init() {}

    public func start() {
        #if os(macOS)
        var link: CVDisplayLink?
        CVDisplayLinkCreateWithActiveCGDisplays(&link)
        guard let displayLink = link else { return }
        self.displayLink = displayLink
        let callback: CVDisplayLinkOutputCallback = { _, _, _, _, _, userInfo -> CVReturn in
            let clock = Unmanaged<FrameClock>.fromOpaque(userInfo!).takeUnretainedValue()
            clock.tick()
            return kCVReturnSuccess
        }
        CVDisplayLinkSetOutputCallback(displayLink, callback, Unmanaged.passUnretained(self).toOpaque())
        CVDisplayLinkStart(displayLink)
        #endif
    }

    public func stop() {
        #if os(macOS)
        if let displayLink {
            CVDisplayLinkStop(displayLink)
        }
        #endif
    }

    public func tick() {
        lock.lock()
        frameIndex += 1
        let waiting = continuations
        continuations.removeAll()
        lock.unlock()
        for c in waiting { c.resume() }
    }

    public func nextFrame() async {
        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            lock.lock()
            continuations.append(cont)
            lock.unlock()
        }
    }

    public func wait(frames: Int32) async {
        guard frames > 0 else { return }
        for _ in 0..<frames {
            await nextFrame()
        }
    }
}

/// CADisplayLink-driven clock for iOS (created from UI layer).
public final class IOSFrameClock: FrameClock {
    #if os(iOS)
    private var link: CADisplayLink?

    public override func start() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let link = CADisplayLink(target: self, selector: #selector(self.onDisplayLink))
            link.preferredFrameRateRange = CAFrameRateRange(minimum: 60, maximum: 60, preferred: 60)
            link.add(to: .main, forMode: .common)
            self.link = link
        }
    }

    @objc private func onDisplayLink() {
        tick()
    }

    public override func stop() {
        link?.invalidate()
        link = nil
    }
    #endif
}
