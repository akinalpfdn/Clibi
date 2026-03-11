import Carbon
import AppKit

// Global callback for Carbon interop — must be a free function.
nonisolated(unsafe) private var hotkeyAction: (() -> Void)?

private func hotkeyEventHandler(
    _: EventHandlerCallRef?,
    _: EventRef?,
    _: UnsafeMutableRawPointer?
) -> OSStatus {
    hotkeyAction?()
    return noErr
}

/// Registers a system-wide hotkey using the Carbon Event API.
final class HotkeyManager {
    private var hotkeyRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?

    func register(config: HotkeyConfig, action: @escaping () -> Void) {
        hotkeyAction = action

        // Install the event handler once; it persists across re-registrations.
        if handlerRef == nil {
            var eventType = EventTypeSpec(
                eventClass: OSType(kEventClassKeyboard),
                eventKind: UInt32(kEventHotKeyPressed)
            )
            InstallEventHandler(
                GetApplicationEventTarget(),
                hotkeyEventHandler,
                1,
                &eventType,
                nil,
                &handlerRef
            )
        }

        // Unregister any previously registered key before registering the new one.
        if let ref = hotkeyRef {
            UnregisterEventHotKey(ref)
            hotkeyRef = nil
        }

        let hotkeyID = EventHotKeyID(signature: OSType(0x434C4249), id: 1)
        let status = RegisterEventHotKey(
            config.carbonKeyCode,
            config.carbonModifiers,
            hotkeyID,
            GetApplicationEventTarget(),
            0,
            &hotkeyRef
        )

        if status != noErr {
            print("[Clibi] Failed to register hotkey \(config.displayString): \(status)")
        }
    }

    func unregister() {
        if let ref = hotkeyRef {
            UnregisterEventHotKey(ref)
            hotkeyRef = nil
        }
        if let ref = handlerRef {
            RemoveEventHandler(ref)
            handlerRef = nil
        }
        hotkeyAction = nil
    }
}
