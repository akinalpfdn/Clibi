import SwiftUI
import AppKit

struct ClipboardListView: View {
    var store: ClipboardStore
    var onSelect: (ClipboardItem) -> Void
    var onOpenSettings: () -> Void
    var onQuit: () -> Void

    @State private var searchText = ""
    @State private var hoveredItemID: UUID?

    private var filteredItems: [ClipboardItem] {
        guard !searchText.isEmpty else { return store.items }
        // Image items have no text to match — only search text items
        return store.items.filter { item in
            item.textContent?.localizedCaseInsensitiveContains(searchText) == true
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            searchBar
            Divider()
            itemList
            Divider()
            footer
        }
        .background(.ultraThinMaterial)
        .frame(minWidth: 280, minHeight: 200)
    }

    // MARK: - Search bar

    private var searchBar: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search…", text: $searchText)
                .textFieldStyle(.plain)
            if !searchText.isEmpty {
                Button { searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
    }

    // MARK: - Item list

    private var itemList: some View {
        Group {
            if filteredItems.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(filteredItems) { item in
                            ClipboardRowView(
                                item: item,
                                imagesDir: store.imagesDir,
                                isHovered: hoveredItemID == item.id
                            )
                            .onTapGesture { onSelect(item) }
                            .onHover { hoveredItemID = $0 ? item.id : nil }
                            .contextMenu {
                                Button("Paste") { onSelect(item) }
                                Button("Copy Only") {
                                    PasteService.place(item: item, imagesDir: store.imagesDir)
                                }
                                Divider()
                                Button("Delete", role: .destructive) {
                                    store.remove(item)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                }
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label(
                store.items.isEmpty ? "No Clipboard History" : "No Results",
                systemImage: store.items.isEmpty ? "clipboard" : "magnifyingglass"
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: 12) {
            Text("\(store.items.count) items")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            Button(role: .destructive) { store.clear() } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .help("Clear all history")

            Button { onOpenSettings() } label: {
                Image(systemName: "gearshape")
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .help("Settings")

            Button { onQuit() } label: {
                Image(systemName: "power")
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .help("Quit Clibi")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
    }
}

// MARK: - Row

struct ClipboardRowView: View {
    let item: ClipboardItem
    let imagesDir: URL
    let isHovered: Bool

    var body: some View {
        Group {
            if item.isImage {
                imageRow
            } else {
                textRow
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            isHovered ? Color.accentColor.opacity(0.15) : Color.clear,
            in: RoundedRectangle(cornerRadius: 6)
        )
        .contentShape(Rectangle())
    }

    private var textRow: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(item.preview)
                .font(.system(.body, design: .monospaced))
                .lineLimit(2)
                .truncationMode(.tail)

            if item.isMultiline {
                Text("multiline")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(.quaternary, in: Capsule())
            }
        }
    }

    private var imageRow: some View {
        HStack(spacing: 8) {
            if let filename = item.imageFilename,
               let nsImage = NSImage(contentsOf: imagesDir.appendingPathComponent(filename)) {
                Image(nsImage: nsImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 120, maxHeight: 72)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            } else {
                Image(systemName: "photo")
                    .foregroundStyle(.secondary)
            }
            Text("Image")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }
}
