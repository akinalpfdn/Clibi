import AppKit

/// Writes a clipboard item to the system pasteboard and optionally simulates ⌘V.
enum PasteService {

    static func paste(item: ClipboardItem, imagesDir: URL) {
        place(item: item, imagesDir: imagesDir)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            PasteService.simulateCommandV()
        }
    }

    static func place(item: ClipboardItem, imagesDir: URL) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        switch item.kind {
        case .text(let content):
            pasteboard.setString(content, forType: .string)

        case .image(let filename, _):
            let url = imagesDir.appendingPathComponent(filename)
            guard let pngData = try? Data(contentsOf: url) else { return }
            let pngType = NSPasteboard.PasteboardType("public.png")
            pasteboard.declareTypes([pngType, .tiff], owner: nil)
            pasteboard.setData(pngData, forType: pngType)
            if let tiff = NSImage(data: pngData)?.tiffRepresentation {
                pasteboard.setData(tiff, forType: .tiff)
            }
        }
    }

    private static func simulateCommandV() {
        let source = CGEventSource(stateID: .hidSystemState)

        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)

        keyDown?.flags = .maskCommand
        keyUp?.flags = .maskCommand

        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }
}
