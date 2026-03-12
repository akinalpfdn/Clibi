import SwiftUI
import ServiceManagement

struct SettingsView: View {
    var store: ClipboardStore
    var onHotkeyChanged: (HotkeyConfig) -> Void

    @State private var maxItems: Double = 100
    @State private var hotkeyConfig: HotkeyConfig = .default
    @State private var launchAtStartup: Bool = false
    @State private var showLaunchToast: Bool = true

    var body: some View {
        Form {
            Section("General") {
                Toggle("Launch at startup", isOn: $launchAtStartup)
                    .onChange(of: launchAtStartup) { _, newValue in
                        do {
                            if newValue {
                                try SMAppService.mainApp.register()
                            } else {
                                try SMAppService.mainApp.unregister()
                            }
                        } catch {
                            launchAtStartup = !newValue
                        }
                    }

                Toggle("Show notification on launch", isOn: $showLaunchToast)
                    .onChange(of: showLaunchToast) { _, newValue in
                        UserDefaults.standard.set(newValue, forKey: "showLaunchToast")
                    }
            }

            Section("History") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Maximum items: \(Int(maxItems))")
                    Slider(value: $maxItems, in: 10...500, step: 10) {
                        Text("Max items")
                    }
                    .onChange(of: maxItems) {
                        store.updateMaxItems(Int(maxItems))
                    }
                }
            }

            Section("Shortcut") {
                LabeledContent("Show clipboard history") {
                    HotkeyRecorderView(config: $hotkeyConfig) { newConfig in
                        HotkeyConfig.current = newConfig
                        onHotkeyChanged(newConfig)
                    }
                    .frame(width: 140, height: 26)
                }
                Text("Click the field, then press your desired shortcut. Escape cancels.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                Button("Clear History", role: .destructive) {
                    store.clear()
                }
                Button("Quit Clibi", role: .destructive) {
                    NSApplication.shared.terminate(nil)
                }
            }

            Section("About") {
                LabeledContent(
                    "Version",
                    value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
                )
                LabeledContent("History stored at") {
                    Text("~/Library/Application Support/Clibi/")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 400, height: 460)
        .onAppear {
            maxItems = Double(store.maxItems)
            hotkeyConfig = HotkeyConfig.current
            launchAtStartup = SMAppService.mainApp.status == .enabled
            showLaunchToast = UserDefaults.standard.object(forKey: "showLaunchToast") as? Bool ?? true
        }
    }
}
