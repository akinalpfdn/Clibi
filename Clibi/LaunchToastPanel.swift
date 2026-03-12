import AppKit
import SwiftUI

final class LaunchToastPanel: NSPanel {
    init(hotkey: String) {
        let size = NSSize(width: 270, height: 64)

        super.init(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        level = .floating
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        ignoresMouseEvents = true

        let host = NSHostingView(rootView: LaunchToastView(hotkey: hotkey))
        host.frame = NSRect(origin: .zero, size: size)
        contentView = host

        positionTopRight(size: size)
    }

    private func positionTopRight(size: NSSize) {
        guard let screen = NSScreen.main else { return }
        let margin: CGFloat = 16
        let x = screen.visibleFrame.maxX - size.width - margin
        let y = screen.visibleFrame.maxY - size.height - margin
        setFrameOrigin(NSPoint(x: x, y: y))
    }

    func showAndAutoDismiss(onDismiss: (() -> Void)? = nil) {
        alphaValue = 0
        orderFrontRegardless()

        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.25
            animator().alphaValue = 1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = 0.4
                self?.animator().alphaValue = 0
            } completionHandler: {
                self?.close()
                onDismiss?()
            }
        }
    }
}

private struct LaunchToastView: View {
    let hotkey: String

    var body: some View {
        HStack(spacing: 11) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 38, height: 38)

            VStack(alignment: .leading, spacing: 2) {
                Text("Clibi is running")
                    .font(.system(size: 13, weight: .semibold))
                Text("Press \(hotkey) to open")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .frame(width: 270, height: 64)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 13))
    }
}
