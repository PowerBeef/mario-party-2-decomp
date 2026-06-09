import Foundation
import GameController
#if os(iOS)
import CoreHaptics
#endif

/// Processed controller state — mirrors D_800D8040 ring output.
public struct ProcessedInput: Sendable {
    public var buttons: UInt16 = 0
    public var buttonsPressed: UInt16 = 0
    public var stickX: Int8 = 0
    public var stickY: Int8 = 0

    public static let a: UInt16 = 0x8000
    public static let b: UInt16 = 0x4000
    public static let z: UInt16 = 0x2000
    public static let start: UInt16 = 0x1000
    public static let dUp: UInt16 = 0x0800
    public static let dDown: UInt16 = 0x0400
    public static let dLeft: UInt16 = 0x0200
    public static let dRight: UInt16 = 0x0100
}

public final class InputManager: @unchecked Sendable {
    public private(set) var pads: [ProcessedInput] = Array(repeating: ProcessedInput(), count: 4)
    private var previousButtons: [UInt16] = Array(repeating: 0, count: 4)

    public init() {
        GCController.startWirelessControllerDiscovery(completionHandler: nil)
    }

    public func poll() {
        let controllers = GCController.controllers().sorted {
            $0.playerIndex.rawValue < $1.playerIndex.rawValue
        }
        for port in 0..<4 {
            var input = ProcessedInput()
            if port < controllers.count {
                let controller = controllers[port]
                if let pad = controller.extendedGamepad {
                    if pad.buttonA.isPressed { input.buttons |= ProcessedInput.a }
                    if pad.buttonB.isPressed { input.buttons |= ProcessedInput.b }
                    if pad.buttonMenu.isPressed { input.buttons |= ProcessedInput.start }
                    if pad.dpad.up.isPressed { input.buttons |= ProcessedInput.dUp }
                    if pad.dpad.down.isPressed { input.buttons |= ProcessedInput.dDown }
                    if pad.dpad.left.isPressed { input.buttons |= ProcessedInput.dLeft }
                    if pad.dpad.right.isPressed { input.buttons |= ProcessedInput.dRight }
                    input.stickX = Int8(clamping: Int(pad.leftThumbstick.xAxis.value * 127))
                    input.stickY = Int8(clamping: Int(pad.leftThumbstick.yAxis.value * 127))
                } else if let micro = controller.microGamepad {
                    if micro.buttonA.isPressed { input.buttons |= ProcessedInput.a }
                    if micro.buttonMenu.isPressed { input.buttons |= ProcessedInput.start }
                }
            }
            input.buttonsPressed = input.buttons & ~previousButtons[port]
            previousButtons[port] = input.buttons
            pads[port] = input
        }
    }

    public func rumble(port: Int, enabled: Bool) {
        #if os(iOS)
        guard enabled, port >= 0, port < GCController.controllers().count else { return }
        let controller = GCController.controllers()[port]
        if let engine = controller.haptics?.createEngine(withLocality: .default) {
            try? engine.start()
        }
        #else
        _ = port
        _ = enabled
        #endif
    }
}

#if os(macOS)
import AppKit

extension InputManager {
    public func pollKeyboard(port: Int = 0) {
        poll()
    }
}
#endif
