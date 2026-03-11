import AppKit
import SwiftUI

/// A click-to-record shortcut field. Click to enter recording mode, press
/// the desired key combination, Escape cancels.
struct HotkeyRecorderView: NSViewRepresentable {
    @Binding var config: HotkeyConfig
    var onChanged: (HotkeyConfig) -> Void

    func makeNSView(context: Context) -> HotkeyRecorderControl {
        let view = HotkeyRecorderControl()
        view.config = config
        view.onConfigChanged = { newConfig in
            config = newConfig
            onChanged(newConfig)
        }
        return view
    }

    func updateNSView(_ nsView: HotkeyRecorderControl, context: Context) {
        // Don't overwrite the view's state while it's actively recording
        if !nsView.isRecording {
            nsView.config = config
        }
    }
}

// MARK: - NSControl subclass

final class HotkeyRecorderControl: NSControl {
    var config: HotkeyConfig = .default {
        didSet { needsDisplay = true }
    }
    var onConfigChanged: ((HotkeyConfig) -> Void)?

    private(set) var isRecording = false {
        didSet { needsDisplay = true }
    }

    // Modifier-only keycodes — ignore these during recording
    private static let modifierKeyCodes: Set<UInt16> = [
        54, 55, // Right/Left Command
        56, 60, // Left/Right Shift
        57,     // Caps Lock
        58, 61, // Left/Right Option
        59, 62, // Left/Right Control
        63,     // Fn
    ]

    override var acceptsFirstResponder: Bool { true }
    override var isFlipped: Bool { true }
    override var intrinsicContentSize: NSSize { NSSize(width: 140, height: 26) }

    // MARK: - Interaction

    override func mouseDown(with event: NSEvent) {
        isRecording ? stopRecording(commit: false) : startRecording()
    }

    private func startRecording() {
        isRecording = true
        window?.makeFirstResponder(self)
    }

    private func stopRecording(commit: Bool) {
        isRecording = false
        if !commit { needsDisplay = true }
        // Give focus back to the window so the panel behaves normally
        window?.makeFirstResponder(nil)
    }

    override func resignFirstResponder() -> Bool {
        if isRecording {
            isRecording = false
            needsDisplay = true
        }
        return super.resignFirstResponder()
    }

    override func keyDown(with event: NSEvent) {
        guard isRecording else { super.keyDown(with: event); return }

        // Escape cancels without changing the current shortcut
        if event.keyCode == 53 {
            stopRecording(commit: false)
            return
        }

        // Ignore bare modifier key presses
        guard !HotkeyRecorderControl.modifierKeyCodes.contains(event.keyCode) else { return }

        if let newConfig = HotkeyConfig.from(event: event) {
            config = newConfig
            onConfigChanged?(newConfig)
        }
        stopRecording(commit: true)
    }

    // MARK: - Drawing

    override func draw(_ dirtyRect: NSRect) {
        let rect = bounds.insetBy(dx: 0.5, dy: 0.5)
        let radius: CGFloat = 6

        // Background
        let bg = isRecording
            ? NSColor.controlAccentColor.withAlphaComponent(0.1)
            : NSColor(named: "controlBackground") ?? NSColor.controlBackgroundColor
        bg.setFill()
        NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).fill()

        // Border
        let borderColor = isRecording ? NSColor.controlAccentColor : NSColor.separatorColor
        borderColor.setStroke()
        let border = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
        border.lineWidth = isRecording ? 1.5 : 1.0
        border.stroke()

        // Label
        let label = isRecording ? "Type shortcut…" : config.displayString
        let textColor = isRecording ? NSColor.controlAccentColor : NSColor.labelColor
        let font = NSFont.monospacedSystemFont(ofSize: 13, weight: .medium)
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: textColor]
        let str = NSAttributedString(string: label, attributes: attrs)
        let size = str.size()
        let origin = NSPoint(x: (bounds.width - size.width) / 2, y: (bounds.height - size.height) / 2)
        str.draw(at: origin)
    }
}
