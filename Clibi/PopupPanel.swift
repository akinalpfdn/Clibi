import AppKit
import SwiftUI

private let frameKey = "popupPanelFrame"

/// A floating, non-activating panel that hosts the clipboard history list.
/// Persists its frame (position + size) across sessions.
final class PopupPanel: NSPanel {
    init(contentView: some View) {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 340, height: 460),
            styleMask: [.titled, .closable, .resizable, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        isMovableByWindowBackground = true
        level = .floating
        isFloatingPanel = true
        hidesOnDeactivate = false
        animationBehavior = .utilityWindow
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        minSize = NSSize(width: 280, height: 200)
        maxSize = NSSize(width: 600, height: 800)

        self.contentView = NSHostingView(rootView: contentView)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(persistFrame),
            name: NSWindow.didMoveNotification,
            object: self
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(persistFrame),
            name: NSWindow.didResizeNotification,
            object: self
        )
    }

    override var canBecomeKey: Bool { true }

    override func cancelOperation(_ sender: Any?) {
        close()
    }

    func show() {
        restoreOrCenter()
        makeKeyAndOrderFront(nil)
    }

    // MARK: - Frame persistence

    @objc private func persistFrame() {
        UserDefaults.standard.set(NSStringFromRect(frame), forKey: frameKey)
    }

    private func restoreOrCenter() {
        if let saved = UserDefaults.standard.string(forKey: frameKey) {
            let savedFrame = NSRectFromString(saved)
            // Only restore if the saved frame is still on an available screen
            let isOnScreen = NSScreen.screens.contains { $0.visibleFrame.intersects(savedFrame) }
            if isOnScreen {
                setFrame(savedFrame, display: false)
                return
            }
        }
        centerOnMainScreen()
    }

    private func centerOnMainScreen() {
        guard let screen = NSScreen.main else { return }
        let x = screen.frame.midX - frame.width / 2
        let y = screen.frame.midY - frame.height / 2
        setFrameOrigin(NSPoint(x: x, y: y))
    }
}
