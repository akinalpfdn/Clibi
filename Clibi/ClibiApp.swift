import SwiftUI

@main
struct ClibiApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.openSettings) private var openSettings

    var body: some Scene {
        Settings {
            SettingsView(store: appDelegate.store) { config in
                appDelegate.updateHotkey(config)
            }
        }
        .onChange(of: appDelegate.settingsRequestCount) {
            openSettings()
        }
    }
}
