import Cocoa

// Monitor all keyboard events including modifier changes
func startMonitoring() {
    NSEvent.addGlobalMonitorForEvents(matching: [.flagsChanged, .keyDown, .keyUp]) { event in
        let typeStr: String
        switch event.type {
        case .flagsChanged: typeStr = "FlagsChanged"
        case .keyDown: typeStr = "KeyDown"
        case .keyUp: typeStr = "KeyUp"
        default: typeStr = "Other(\(event.type.rawValue))"
        }

        let flags = event.modifierFlags.rawValue
        let keyCode = event.keyCode

        print("[\(typeStr)] keyCode=0x\(String(keyCode, radix: 16)) flags=0x\(String(flags, radix: 16))")
    }

    print("Monitoring keyboard events. Press Ctrl+C to stop.")
    print("Press Right Control on your physical keyboard, then press RB on gamepad.")
    RunLoop.current.run()
}

startMonitoring()
