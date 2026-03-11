import AppKit
import Foundation

/// Checks GitHub Releases for a newer version and prompts the user to download it.
enum UpdateChecker {

    // MARK: - Configuration

    /// Your GitHub "owner/repo" slug — update this before releasing.
    private static let repoSlug = "akinalpfdn/Clibi"

    private static var apiURL: URL {
        URL(string: "https://api.github.com/repos/\(repoSlug)/releases/latest")!
    }

    private static var releasesPageURL: URL {
        URL(string: "https://github.com/\(repoSlug)/releases/latest")!
    }

    // MARK: - Public

    static func checkForUpdates() {
        Task {
            guard let latestTag = await fetchLatestTag() else { return }
            let latest = latestTag.hasPrefix("v") ? String(latestTag.dropFirst()) : latestTag
            let current = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"

            guard isNewer(latest, than: current) else { return }

            await MainActor.run { showAlert(current: current, latest: latest) }
        }
    }

    // MARK: - Private

    private static func fetchLatestTag() async -> String? {
        var request = URLRequest(url: apiURL)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")

        guard
            let (data, _) = try? await URLSession.shared.data(for: request),
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let tag = json["tag_name"] as? String
        else { return nil }

        return tag
    }

    /// Returns true if `version` is strictly greater than `current` using semantic versioning.
    private static func isNewer(_ version: String, than current: String) -> Bool {
        let parts = { (s: String) in s.split(separator: ".").compactMap { Int($0) } }
        let lhs = parts(version)
        let rhs = parts(current)
        let count = max(lhs.count, rhs.count)
        for i in 0..<count {
            let l = i < lhs.count ? lhs[i] : 0
            let r = i < rhs.count ? rhs[i] : 0
            if l != r { return l > r }
        }
        return false
    }

    private static func showAlert(current: String, latest: String) {
        NSApp.activate()
        let alert = NSAlert()
        alert.messageText = "Update Available"
        alert.informativeText = "Clibi \(latest) is available — you have \(current).\nWould you like to download it?"
        alert.addButton(withTitle: "Download")
        alert.addButton(withTitle: "Later")

        if alert.runModal() == .alertFirstButtonReturn {
            NSWorkspace.shared.open(releasesPageURL)
        }
    }
}
