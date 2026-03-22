# 🎵 AppTune — Music Automation for macOS

AppTune is a native macOS menu bar app that **automatically plays your music playlists** whenever you open or focus specific apps. Built with SwiftUI, it supports both **Apple Music** and **Spotify**.

---

## ✨ Features

| Feature | Details |
|---|---|
| 🎯 **App-triggered playback** | Set rules: open Xcode → play your coding playlist |
| 🍎 **Apple Music support** | Full playlist library integration via AppleScript |
| 🎧 **Spotify support** | Playback via Spotify AppleScript bridge |
| 🚀 **Login item** | Registers itself at login via `SMAppService` (macOS 13+) |
| 📋 **Menu bar app** | Lives quietly in the menu bar (`LSUIElement = YES`) |
| 🔁 **Trigger modes** | On App Launch, On App Focus, or both |
| 💾 **Persistent rules** | All rules saved to `UserDefaults` and survive restarts |

---

## 📁 Project Structure

```
AppTune/
├── AppTune.xcodeproj/
│   └── project.pbxproj
└── AppTune/
    ├── AppTuneApp.swift          # @main entry, AppDelegate, login item
    ├── Info.plist                # LSUIElement, AppleScript permissions
    ├── AppTune.entitlements      # Sandbox + apple-events entitlements
    ├── Assets.xcassets/
    ├── Models/
    │   └── SettingsStore.swift   # AppRule, Playlist, MusicService models + persistence
    ├── Services/
    │   └── AppMonitorService.swift # NSWorkspace observer, AppleScript bridge
    ├── Views/
    │   ├── SettingsView.swift    # Main settings window (sidebar nav)
    │   ├── RulesView.swift       # Rules list with toggle/edit/delete
    │   ├── AddRuleView.swift     # 3-step wizard to add/edit rules
    │   ├── ServicesView.swift    # Connect Apple Music / Spotify
    │   ├── GeneralView.swift     # Launch at login, monitoring toggle
    │   └── MenuBarView.swift     # Compact menu bar popover
    └── Utilities/
        └── Extensions.swift     # Color(hex:) helper
```

---

## 🛠 Setup in Xcode

### Requirements
- **Xcode 15+**
- **macOS 13.0+** (Ventura or later)
- Apple Developer account (free is fine for local builds)

### Steps

1. **Open the project**
   ```bash
   open AppTune.xcodeproj
   ```

2. **Set your Team**
   - Select the `AppTune` target → Signing & Capabilities
   - Choose your Apple ID team under "Signing"

3. **Update Bundle ID** *(optional)*
   - Change `com.apptune.macos` to something unique like `com.yourname.apptune`
   - This must match in both target settings and entitlements

4. **Build & Run**
   - Press `⌘R` or Product → Run
   - The app will appear in your **menu bar** (top right, music note icon)

---

## 🔐 Permissions

AppTune needs **Automation permissions** to control Music and Spotify:

1. First launch will prompt for permission automatically
2. If denied, go to: **System Settings → Privacy & Security → Automation**
3. Enable AppTune for both **Music** and **Spotify**

The app also uses `SMAppService` to register as a **Login Item** — you'll see it in:  
**System Settings → General → Login Items & Extensions**

---

## 🎵 How It Works

### App Monitoring
```swift
// Watches for app launches via NSWorkspace
NSWorkspace.shared.notificationCenter.addObserver(
    forName: NSWorkspace.didLaunchApplicationNotification, ...
)
```

### Triggering Playback (Apple Music)
```applescript
tell application "Music"
    play playlist "My Coding Playlist"
end tell
```

### Triggering Playback (Spotify)
```applescript
tell application "Spotify"
    play track "spotify:playlist:37i9dQZF1DX..."
end tell
```

### Login Item Registration (macOS 13+)
```swift
try SMAppService.mainApp.register()
```

---

## 📦 Adding Rules

1. Click the **menu bar icon** → Settings (or Cmd+,)
2. Go to **Rules** → click **"Add Rule"**
3. **Step 1**: Pick an app (from running apps or file browser)
4. **Step 2**: Choose Apple Music or Spotify + select a playlist
5. **Step 3**: Set trigger (on launch / on focus)
6. Click **Save Rule** ✓

---

## 🔧 Customization

### Adding More Playlist Sources
Edit `AppMonitorService.fetchAppleMusicPlaylists()` to use `MusicKit` framework for richer metadata (requires an Apple Music API key for full catalog access).

### Spotify Web API (Enhanced)
Replace the hardcoded playlists in `fetchSpotifyPlaylists()` with real Spotify Web API calls using OAuth 2.0 to list the user's actual playlists.

### Custom AppleScript Actions
Modify `playAppleMusicPlaylist()` to shuffle, set volume, or play a specific album instead.

---

## 🐛 Troubleshooting

| Issue | Fix |
|---|---|
| Music doesn't play | Check Privacy → Automation permissions |
| App not starting at login | Toggle Login Item off/on in General tab |
| Playlists not loading | Make sure Music.app is running |
| Spotify not found | Install Spotify desktop app |

---

## 📄 License

MIT — free to use, modify, and distribute.
