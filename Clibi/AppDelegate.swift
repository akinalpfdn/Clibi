import AppKit
import SwiftUI
import Observation

@Observable
final class AppDelegate: NSObject, NSApplicationDelegate {
    var settingsRequestCount = 0
    let store = ClipboardStore()

    private let monitor = ClipboardMonitor()
    private let hotkeyManager = HotkeyManager()
    private var panel: PopupPanel?
    private var toastPanel: LaunchToastPanel?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Run as a background agent — no Dock icon, no menu bar icon
        NSApp.setActivationPolicy(.accessory)

        setupClipboardMonitor()
        setupHotkey()
        UpdateChecker.checkForUpdates()
        showLaunchToastIfNeeded()
    }

    // MARK: - Clipboard monitor

    private func setupClipboardMonitor() {
        monitor.onNewText = { [weak self] text in
            self?.store.add(text: text)
        }
        monitor.onNewImage = { [weak self] data, fingerprint in
            self?.store.add(imageData: data, fingerprint: fingerprint)
        }
        monitor.start()
    }

    // MARK: - Hotkey

    private func setupHotkey() {
        registerHotkey(config: HotkeyConfig.current)
    }

    private func registerHotkey(config: HotkeyConfig) {
        hotkeyManager.register(config: config) { [weak self] in
            self?.togglePanel()
        }
    }

    func updateHotkey(_ config: HotkeyConfig) {
        registerHotkey(config: config)
    }

    // MARK: - Panel

    @objc func togglePanel() {
        if let panel, panel.isVisible {
            panel.close()
            self.panel = nil
            return
        }

        let listView = ClipboardListView(
            store: store,
            onSelect: { [weak self] item in self?.selectItem(item) },
            onOpenSettings: { [weak self] in self?.openSettings() },
            onQuit: { NSApplication.shared.terminate(nil) }
        )

        let newPanel = PopupPanel(contentView: listView)
        newPanel.show()
        self.panel = newPanel
    }

    private func selectItem(_ item: ClipboardItem) {
        panel?.close()
        panel = nil

        // Let the previously active app reclaim focus before simulating paste
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self else { return }
            PasteService.paste(item: item, imagesDir: store.imagesDir)
        }
    }

    private func openSettings() {
        panel?.close()
        panel = nil
        NSApp.activate()
        settingsRequestCount += 1
    }

    // MARK: - Launch toast

    private func showLaunchToastIfNeeded() {
        guard UserDefaults.standard.object(forKey: "showLaunchToast") as? Bool ?? true else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            let toast = LaunchToastPanel(hotkey: HotkeyConfig.current.displayString)
            self?.toastPanel = toast
            toast.showAndAutoDismiss { [weak self] in
                self?.toastPanel = nil
            }
        }
    }
}
