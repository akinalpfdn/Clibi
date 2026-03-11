import AppKit

/// Polls NSPasteboard for changes and emits new text or image content.
final class ClipboardMonitor {
    var onNewText: ((String) -> Void)?
    var onNewImage: ((Data, String) -> Void)? // (pngData, fingerprint)

    private var timer: Timer?
    private var lastChangeCount: Int = 0

    func start() {
        lastChangeCount = NSPasteboard.general.changeCount
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.poll()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func poll() {
        let pasteboard = NSPasteboard.general
        guard pasteboard.changeCount != lastChangeCount else { return }
        lastChangeCount = pasteboard.changeCount

        // Prefer text over image when both are present (e.g. rich text copy)
        if let text = pasteboard.string(forType: .string),
           !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            onNewText?(text)
            return
        }

        // Try common image types in order of preference
        let imageTypes: [NSPasteboard.PasteboardType] = [.png, .tiff, NSPasteboard.PasteboardType("public.jpeg")]
        for type in imageTypes {
            if let data = pasteboard.data(forType: type),
               let pngData = normalizedPNG(from: data, type: type) {
                let fingerprint = imageFingerprint(pngData)
                onNewImage?(pngData, fingerprint)
                return
            }
        }
    }

    /// Convert raw pasteboard image data to PNG for consistent storage.
    private func normalizedPNG(from data: Data, type: NSPasteboard.PasteboardType) -> Data? {
        if type == .png { return data }
        guard let image = NSImage(data: data) else { return nil }
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else { return nil }
        return bitmap.representation(using: .png, properties: [:])
    }

    /// Fast fingerprint using data length + first 1 KB of bytes.
    private func imageFingerprint(_ data: Data) -> String {
        let sampleSize = min(data.count, 1024)
        return "\(data.count)-\(data.prefix(sampleSize).hashValue)"
    }
}
