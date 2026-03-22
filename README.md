# AppTune 🎵
 
> Automatically play your favorite music when you open specific apps on macOS.
 
![Platform](https://img.shields.io/badge/platform-macOS%2013%2B-lightgrey?style=flat-square)
![Swift](https://img.shields.io/badge/swift-5.9-orange?style=flat-square)
![License](https://img.shields.io/badge/license-MIT-blue?style=flat-square)
 
---
 
## What is AppTune?
 
AppTune is a native macOS menu bar app that bridges your workflow and your music. Set rules like:
 
- Open **Xcode** → Play your *Deep Focus* playlist on Spotify
- Open **Notion** → Play *Lo-fi Beats* on Apple Music
- Open **Final Cut Pro** → Play *Epic Scores* on Spotify
 
It runs silently in your menu bar, monitors app launches, and triggers playback automatically — no manual switching needed.
 
---
 
## Features
 
- 🎯 **App-triggered playback** — set rules per app, per playlist
- 🍎 **Apple Music** — full playlist library integration
- 🎧 **Spotify** — OAuth login, fetches your real personal playlists
- 🚀 **Launches at login** — registers as a macOS Login Item automatically
- 📋 **Menu bar app** — lives quietly in your menu bar, zero Dock presence
- 🔁 **Two trigger modes** — on App Launch, on App Focus, or both
- 💾 **Persistent rules** — all rules saved and survive restarts
- 🔐 **Secure token storage** — Spotify tokens stored in Keychain
 
---
 
## Requirements
 
- macOS 13.0 (Ventura) or later
- Apple Music and/or Spotify desktop app installed
- Spotify account (free or premium) for Spotify integration
 
---
 
## Installation
 
### Option 1 — Download (Recommended)
1. Go to [Releases](https://github.com/HitarthTrivedi/AppTune/releases)
2. Download `AppTune.zip`
3. Unzip and drag `AppTune.app` to your `/Applications` folder
4. Launch it — the music note icon will appear in your menu bar
 
### Option 2 — Build from source
```bash
git clone https://github.com/HitarthTrivedi/AppTune.git
cd AppTune
open AppTune.xcodeproj
```
Then build and run in Xcode (`⌘R`).

### Option 3 — Homebrew
```bash
brew tap HitarthTrivedi/apptune
brew install --cask apptune
```

---
---
 
## Setup
 
### Apple Music
1. Open AppTune → Settings → Services
2. Apple Music is ready if Music.app is installed
3. Grant Automation permissions when prompted:
   **System Settings → Privacy & Security → Automation**
 
### Spotify
1. Open AppTune → Settings → Services
2. Click **Connect Spotify**
3. Log in with your Spotify account in the browser
4. Your playlists will load automatically
 
---
 
## Adding Rules
 
1. Click the menu bar icon → **Settings**
2. Go to **Rules** → click **Add Rule**
3. **Step 1** — Pick an app (from running apps or file browser)
4. **Step 2** — Choose Apple Music or Spotify + select a playlist
5. **Step 3** — Set trigger (on launch / on focus)
6. Click **Save Rule** ✓
 
---
 
## Project Structure
 
```
AppTune/
├── AppTuneApp.swift              # @main entry, AppDelegate, login item
├── Info.plist                    # LSUIElement, AppleScript permissions
├── AppTune.entitlements          # Sandbox + apple-events entitlements
├── Models/
│   └── SettingsStore.swift       # AppRule, Playlist, MusicService + persistence
├── Services/
│   ├── AppMonitorService.swift   # NSWorkspace observer, AppleScript bridge
│   └── SpotifyService.swift      # OAuth 2.0, Keychain token storage, playlist API
├── Views/
│   ├── SettingsView.swift        # Main settings window (sidebar nav)
│   ├── RulesView.swift           # Rules list with toggle/edit/delete
│   ├── AddRuleView.swift         # 3-step wizard to add/edit rules
│   ├── ServicesView.swift        # Connect Apple Music / Spotify
│   ├── GeneralView.swift         # Launch at login, monitoring toggle
│   └── MenuBarView.swift         # Compact menu bar popover
└── Utilities/
    ├── Extensions.swift          # Color(hex:) helper
    └── WindowManager.swift       # NSWindow settings opener
```
 
---
 
## Tech Stack
 
| Technology | Usage |
|---|---|
| SwiftUI | Entire UI — settings window, menu bar popover |
| AppKit | NSWorkspace monitoring, NSWindow management |
| NSAppleScript | Apple Music + Spotify playback control |
| Spotify Web API | OAuth 2.0, personal playlist fetching |
| Security Keychain | Secure token storage |
| SMAppService | Login item registration (macOS 13+) |
| UserDefaults | Rule persistence |
 
---
 
## Permissions Required
 
| Permission | Why |
|---|---|
| Automation | Controls Music.app and Spotify.app via AppleScript |
| Login Items | Launches AppTune at login |
 
---
 
## Roadmap
 
- [ ] MusicKit integration (App Store ready Apple Music)
- [ ] Spotify Web Playback SDK
- [ ] Volume control per rule
- [ ] Delay trigger (wait N seconds after app opens)
- [ ] Notifications when music triggers
- [ ] App Store release
 
---
 
## License
 
MIT — free to use, modify, and distribute.
 
---
 
## Author
 
**Hitarth Trivedi**
- GitHub: [@HitarthTrivedi](https://github.com/HitarthTrivedi)
 
---
 
> Built with SwiftUI for macOS — because your music should match your workflow.
