# Scratchpad

A 100% vibe coded minimal macOS menu bar app for capturing thoughts quickly.

## Features

- **Global hotkey** — `Cmd+Shift+;` summons the window from anywhere. The cursor lands at the top so you can start typing immediately.
- **Stays out of the way** — lives in the menu bar, not the Dock. Dismiss with the hotkey, `Esc`, or by clicking away.
- **Local data** — No iCloud, no accounts.
- **Plain text** — No rich text, no formatting.
- **Light and dark mode** — automatically aligns with the system appearnace.

## Requirements

- macOS 13 Ventura or later

## Building

From the project's root directory:

```sh
# Debug build
xcodebuild -project Scratchpad.xcodeproj -scheme Scratchpad -configuration Debug build
```

```sh
# Release build
xcodebuild -scheme Scratchpad -configuration Release build
```

The built app lands in `build/Release/Scratchpad.app`.
