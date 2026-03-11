import Foundation
import AppKit

@Observable
final class ClipboardStore {
    private(set) var items: [ClipboardItem] = []
    private(set) var maxItems: Int = 100

    private let historyURL: URL
    let imagesDir: URL

    init() {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        let appDir = appSupport.appendingPathComponent("Clibi", isDirectory: true)
        let imgDir = appDir.appendingPathComponent("Images", isDirectory: true)

        try? FileManager.default.createDirectory(at: imgDir, withIntermediateDirectories: true)

        self.historyURL = appDir.appendingPathComponent("history.json")
        self.imagesDir = imgDir

        let saved = UserDefaults.standard.integer(forKey: "maxHistoryCount")
        self.maxItems = saved > 0 ? saved : 100

        load()
    }

    // MARK: - Adding items

    func add(text: String) {
        if items.first?.textContent == text { return }
        items.removeAll { $0.textContent == text }
        items.insert(ClipboardItem(text: text), at: 0)
        trimAndSave()
    }

    func add(imageData: Data, fingerprint: String) {
        // Skip if the topmost item is already this image
        if case .image(_, let fp) = items.first?.kind, fp == fingerprint { return }

        // Remove any existing entry with the same fingerprint
        for item in items {
            if case .image(let filename, let fp) = item.kind, fp == fingerprint {
                deleteImageFile(named: filename)
            }
        }
        items.removeAll {
            if case .image(_, let fp) = $0.kind { return fp == fingerprint }
            return false
        }

        let filename = UUID().uuidString + ".png"
        let fileURL = imagesDir.appendingPathComponent(filename)
        guard (try? imageData.write(to: fileURL, options: .atomic)) != nil else { return }

        items.insert(ClipboardItem(imageFilename: filename, fingerprint: fingerprint), at: 0)
        trimAndSave()
    }

    // MARK: - Removing items

    func remove(_ item: ClipboardItem) {
        if let filename = item.imageFilename {
            deleteImageFile(named: filename)
        }
        items.removeAll { $0.id == item.id }
        save()
    }

    func togglePin(_ item: ClipboardItem) {
        guard let idx = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[idx].isPinned.toggle()
        save()
    }

    func clear() {
        // Pinned items survive a clear; only their image files are kept on disk.
        for item in items where !item.isPinned {
            if let filename = item.imageFilename {
                deleteImageFile(named: filename)
            }
        }
        items.removeAll { !$0.isPinned }
        save()
    }

    func updateMaxItems(_ count: Int) {
        maxItems = max(count, 10)
        UserDefaults.standard.set(maxItems, forKey: "maxHistoryCount")
        trimAndSave()
    }

    // MARK: - Private helpers

    private func trimAndSave() {
        // Only non-pinned items count against the limit; pinned items are never evicted.
        var nonPinnedCount = items.filter { !$0.isPinned }.count
        while nonPinnedCount > maxItems {
            // Remove the oldest (last) non-pinned item.
            guard let idx = items.indices.reversed().first(where: { !items[$0].isPinned }) else { break }
            let dropped = items.remove(at: idx)
            if let filename = dropped.imageFilename {
                deleteImageFile(named: filename)
            }
            nonPinnedCount -= 1
        }
        save()
    }

    private func deleteImageFile(named filename: String) {
        let url = imagesDir.appendingPathComponent(filename)
        try? FileManager.default.removeItem(at: url)
    }

    // MARK: - Persistence

    private func save() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(items) else { return }
        try? data.write(to: historyURL, options: .atomic)
    }

    private func load() {
        guard let data = try? Data(contentsOf: historyURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let loaded = (try? decoder.decode([ClipboardItem].self, from: data)) ?? []

        // Drop image items whose files no longer exist on disk
        items = loaded.filter { item in
            guard let filename = item.imageFilename else { return true }
            return FileManager.default.fileExists(
                atPath: imagesDir.appendingPathComponent(filename).path
            )
        }
    }
}
