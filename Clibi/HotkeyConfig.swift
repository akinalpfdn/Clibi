import Carbon
import AppKit

/// Stores an arbitrary global keyboard shortcut.
struct HotkeyConfig: Codable, Equatable {
    let carbonKeyCode: UInt32
    let carbonModifiers: UInt32
    let displayString: String

    // Default: ⌃V (Control + V)
    static let `default` = HotkeyConfig(
        carbonKeyCode: UInt32(kVK_ANSI_V),
        carbonModifiers: UInt32(controlKey),
        displayString: "⌃V"
    )

    // MARK: - Persistence

    private static let defaultsKey = "hotkeyConfig"

    static var current: HotkeyConfig {
        get {
            guard let data = UserDefaults.standard.data(forKey: defaultsKey),
                  let config = try? JSONDecoder().decode(HotkeyConfig.self, from: data)
            else { return .default }
            return config
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: defaultsKey)
            }
        }
    }

    // MARK: - Build from NSEvent

    /// Returns a config from a key event, or nil if the combination is not valid
    /// (e.g. no meaningful modifier, or modifier-only key press).
    static func from(event: NSEvent) -> HotkeyConfig? {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

        // Require at least one of ⌃ ⌥ ⌘ to avoid blocking regular typing
        let primary = flags.intersection([.control, .option, .command])
        guard !primary.isEmpty else { return nil }

        var carbonMods: UInt32 = 0
        var display = ""

        // Build in canonical display order: ⌃ ⌥ ⇧ ⌘
        if flags.contains(.control) { carbonMods |= UInt32(controlKey); display += "⌃" }
        if flags.contains(.option)  { carbonMods |= UInt32(optionKey);  display += "⌥" }
        if flags.contains(.shift)   { carbonMods |= UInt32(shiftKey);   display += "⇧" }
        if flags.contains(.command) { carbonMods |= UInt32(cmdKey);     display += "⌘" }

        display += keyName(for: event.keyCode)

        return HotkeyConfig(
            carbonKeyCode: UInt32(event.keyCode),
            carbonModifiers: carbonMods,
            displayString: display
        )
    }

    // MARK: - Key name lookup

    static func keyName(for keyCode: UInt16) -> String {
        switch keyCode {
        case 0x00: return "A";  case 0x0B: return "B";  case 0x08: return "C"
        case 0x02: return "D";  case 0x0E: return "E";  case 0x03: return "F"
        case 0x05: return "G";  case 0x04: return "H";  case 0x22: return "I"
        case 0x26: return "J";  case 0x28: return "K";  case 0x25: return "L"
        case 0x2E: return "M";  case 0x2D: return "N";  case 0x1F: return "O"
        case 0x23: return "P";  case 0x0C: return "Q";  case 0x0F: return "R"
        case 0x01: return "S";  case 0x11: return "T";  case 0x20: return "U"
        case 0x09: return "V";  case 0x0D: return "W";  case 0x07: return "X"
        case 0x10: return "Y";  case 0x06: return "Z"
        case 0x12: return "1";  case 0x13: return "2";  case 0x14: return "3"
        case 0x15: return "4";  case 0x17: return "5";  case 0x16: return "6"
        case 0x1A: return "7";  case 0x1C: return "8";  case 0x19: return "9"
        case 0x1D: return "0"
        case 0x7A: return "F1"; case 0x78: return "F2"; case 0x63: return "F3"
        case 0x76: return "F4"; case 0x60: return "F5"; case 0x61: return "F6"
        case 0x62: return "F7"; case 0x64: return "F8"; case 0x65: return "F9"
        case 0x6D: return "F10";case 0x67: return "F11";case 0x6F: return "F12"
        case 0x24: return "↩";  case 0x30: return "⇥";  case 0x31: return "Space"
        case 0x33: return "⌫";  case 0x7B: return "←";  case 0x7C: return "→"
        case 0x7D: return "↓";  case 0x7E: return "↑"
        case 0x1B: return "-";  case 0x18: return "=";  case 0x21: return "["
        case 0x1E: return "]";  case 0x2A: return "\\"; case 0x29: return ";"
        case 0x27: return "'";  case 0x2B: return ",";  case 0x2F: return "."
        case 0x2C: return "/";  case 0x32: return "`"
        default: return "(\(keyCode))"
        }
    }
}
