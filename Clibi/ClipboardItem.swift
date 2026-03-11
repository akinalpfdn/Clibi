import Foundation

struct ClipboardItem: Codable, Identifiable {
    let id: UUID
    let kind: Kind
    var isPinned: Bool = false

    enum Kind: Codable {
        case text(String)
        /// filename: PNG file stored in the app's Images directory.
        /// fingerprint: first-1024-bytes hash used for deduplication.
        case image(filename: String, fingerprint: String)
    }

    init(text: String) {
        self.id = UUID()
        self.kind = .text(text)
    }

    init(imageFilename: String, fingerprint: String) {
        self.id = UUID()
        self.kind = .image(filename: imageFilename, fingerprint: fingerprint)
    }

    var textContent: String? {
        if case .text(let s) = kind { return s }
        return nil
    }

    var imageFilename: String? {
        if case .image(let name, _) = kind { return name }
        return nil
    }

    var isImage: Bool { imageFilename != nil }

    // Single-line preview used in search and text rows
    var preview: String {
        guard let text = textContent else { return "" }
        let firstLine = text.components(separatedBy: .newlines).first ?? text
        return firstLine.count > 120 ? String(firstLine.prefix(120)) + "…" : firstLine
    }

    var isMultiline: Bool {
        textContent?.contains(where: \.isNewline) ?? false
    }
}
