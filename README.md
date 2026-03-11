# Clibi

A lightweight clipboard manager for macOS. Keeps your last 100 copied items accessible with a single shortcut.

![macOS](https://img.shields.io/badge/macOS-14.0%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange)
![License](https://img.shields.io/badge/license-MIT-green)

## Features

- **Clipboard History** — Automatically stores the last 100 text items you copy (configurable up to 500)
- **Quick Access** — Press `⌥V` (Option+V) to open the history popup anywhere
- **Search** — Filter your clipboard history by typing in the search field
- **Smart Paste** — Select an item to paste it directly into the focused app. If no input field is focused, the item is copied to your clipboard
- **Lightweight** — Lives in the menu bar, no dock icon, minimal resource usage
- **Persistent** — History survives app restarts (stored as JSON in Application Support)
- **Resizable** — The popup window can be resized and moved to your preference

## Installation

### Build from Source

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/Clibi.git
   ```
2. Open `Clibi.xcodeproj` in Xcode
3. Build and run (⌘R)

### Requirements

- macOS 14.0 or later
- Xcode 15.0 or later (to build)

## Setup

On first launch, macOS will ask you to grant **Accessibility** permission. This is required for:

- Registering the global `⌥V` shortcut
- Simulating paste (⌘V) into the focused app

Go to **System Settings → Privacy & Security → Accessibility** and enable Clibi.

## Usage

| Action | How |
|--------|-----|
| Open clipboard history | Press `⌥V` or click the menu bar icon → Show History |
| Select an item | Click on it — pastes into the focused app |
| Search | Start typing in the search field |
| Delete an item | Right-click → Delete |
| Copy without pasting | Right-click → Copy |
| Close popup | Press `Escape` or click outside |
| Clear all history | Menu bar icon → Clear History, or in Settings |
| Adjust max items | Menu bar icon → Settings |

## Architecture

```
Clibi/
├── ClibiApp.swift          # App entry point
├── AppDelegate.swift       # Menu bar, hotkey, and panel coordination
├── ClipboardItem.swift     # Data model
├── ClipboardStore.swift    # JSON persistence + history management
├── ClipboardMonitor.swift  # Polls NSPasteboard for changes
├── HotkeyManager.swift     # Global ⌥V shortcut (Carbon API)
├── PasteService.swift      # Clipboard write + ⌘V simulation
├── PopupPanel.swift        # Floating NSPanel
├── ClipboardListView.swift # SwiftUI list with search
└── SettingsView.swift      # Preferences window
```

**Key decisions:**

- **No external dependencies** — Pure Swift + AppKit + SwiftUI
- **Carbon hotkey API** — Reliable global shortcut that consumes the key event (prevents `√` from being typed)
- **NSPanel (non-activating)** — Popup appears without stealing focus from the active app
- **Timer-based polling** — Checks NSPasteboard every 0.5s for changes. Simple and reliable
- **JSON persistence** — Stored in `~/Library/Application Support/Clibi/history.json`

## Privacy

Clibi stores clipboard history **locally only**. No data is sent anywhere. The history file is plain JSON at:

```
~/Library/Application Support/Clibi/history.json
```

Delete this file to remove all history.

## License

MIT — see [LICENSE](LICENSE) for details.
