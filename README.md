# Scratchpad

A minimal macOS menu bar app for capturing thoughts quickly. One note, always a keystroke away.

## Features

- **Global hotkey** — `Cmd+Shift+;` summons the window from anywhere. The cursor lands at the top so you can start typing immediately.
- **Stays out of the way** — lives in the menu bar, not the Dock. Dismiss with the hotkey, `Esc`, or by clicking away.
- **Follows your focus** — on multi-monitor setups the window appears on whichever display your cursor is on.
- **Persists automatically** — text and window size/position are saved locally and survive reboots. No iCloud, no accounts.
- **Plain text** — 15pt monospaced font (MesloLGS-Regular → Menlo → system fallback). No rich text, no formatting.
- **Light and dark mode** — appearance follows the system automatically.

## Requirements

- macOS 13 Ventura or later

## Building

Open `Scratchpad.xcodeproj` in Xcode and press `Cmd+R`, or build from the command line:

```sh
xcodebuild -scheme Scratchpad -configuration Release build
```

The built app lands in `build/Release/Scratchpad.app`.

## Usage

| Action | How |
|---|---|
| Show / hide | `Cmd+Shift+;` |
| Dismiss | `Esc` or click away |
| Select all | `Cmd+A` |
| Cut / Copy / Paste | `Cmd+X` / `Cmd+C` / `Cmd+V` |

Click the menu bar icon for **About**, a link to this page, or **Quit**.
