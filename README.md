# AtollExtensionKit

[![Swift](https://img.shields.io/badge/Swift-6.2-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-macOS%2013.0+-lightgrey.svg)](https://www.apple.com/macos/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

**AtollExtensionKit** is a Swift SDK that allows third-party macOS applications to display custom live activities and lock screen widgets inside [Atoll (DynamicIsland)](https://atoll.app).

![AtollExtensionKit Demo](Media/demo.png)

## Features

✨ **Live Activities** - Display real-time information in the closed notch (timer, downloads, workouts, etc.)  
🔒 **Lock Screen Widgets** - Show custom widgets on the macOS lock screen  
🎨 **Full Customization** - Icons, colors, progress indicators, animations, and layout control  
⚡ **XPC Communication** - Fast, secure inter-process communication  
🔐 **Permission System** - User-controlled authorization in Atoll Settings  
📊 **Priority Management** - Smart conflict resolution when multiple activities compete  
✅ **Type-Safe** - Modern Swift API with Codable models and async/await  

---

## Quick Start

### Installation

Add AtollExtensionKit to your project using Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/ebullioscopic/AtollExtensionKit.git", from: "1.0.0")
]
```

### Basic Usage

```swift
import AtollExtensionKit

// 1. Request authorization
let authorized = try await AtollClient.shared.requestAuthorization()

// 2. Create a live activity
let activity = AtollLiveActivityDescriptor(
    id: "my-timer",
    bundleIdentifier: Bundle.main.bundleIdentifier!,
    priority: .normal,
    title: "Timer",
    subtitle: "Focus Session",
    icon: .symbol(name: "timer", color: .blue),
    trailingContent: .countdown(targetDate: Date().addingTimeInterval(1500)),
    progressIndicator: .ring(color: .blue, lineWidth: 3),
    accentColor: .blue
)

// 3. Present it in Atoll
try await AtollClient.shared.presentLiveActivity(activity)
```

---

## Documentation

📖 **[Full API Documentation](API_DOCUMENTATION.md)**

- [Getting Started](API_DOCUMENTATION.md#getting-started)
- [Authorization](API_DOCUMENTATION.md#authorization)
- [Live Activities](API_DOCUMENTATION.md#live-activities)
- [Lock Screen Widgets](API_DOCUMENTATION.md#lock-screen-widgets)
- [Priority System](API_DOCUMENTATION.md#priority-system)
- [Best Practices](API_DOCUMENTATION.md#best-practices)
- [Examples](API_DOCUMENTATION.md#examples)

---

## Examples

### Pomodoro Timer

```swift
let activity = AtollLiveActivityDescriptor(
    id: "pomodoro",
    bundleIdentifier: Bundle.main.bundleIdentifier!,
    priority: .high,
    title: "Focus Time",
    subtitle: "Deep Work",
    icon: .symbol(name: "brain.head.profile", color: .purple),
    trailingContent: .countdown(targetDate: Date().addingTimeInterval(25 * 60)),
    progressIndicator: .ring(color: .purple, lineWidth: 3),
    accentColor: .purple,
    allowMusicCoexistence: true
)

try await AtollClient.shared.presentLiveActivity(activity)
```

### Lock Screen Widget

```swift
let widget = AtollLockScreenWidgetDescriptor(
    id: "weather",
    bundleIdentifier: Bundle.main.bundleIdentifier!,
    layoutStyle: .inline,
    position: .init(alignment: .topCenter, offsetX: 0, offsetY: 100),
    material: .frosted(opacity: 0.85),
    content: [
        .icon(.symbol(name: "cloud.sun.fill", color: .yellow)),
        .text("San Francisco", font: .system(weight: .semibold)),
        .text("72°F", font: .system(weight: .bold), color: .white)
    ]
)

try await AtollClient.shared.presentLockScreenWidget(widget)
```

---

## Requirements

- **macOS 13.0+**
- **Swift 6.2+**
- **Xcode 16.0+**
- **Atoll 1.0.0+** (installed on user's Mac)

---

## Architecture

AtollExtensionKit uses **XPC (Cross-Process Communication)** to securely communicate with the Atoll app:

```
┌─────────────────────┐         XPC          ┌─────────────────────┐
│  Your App           │◄──────────────────►  │  Atoll              │
│  (AtollClient)      │   Mach Service      │  (XPC Service)      │
└─────────────────────┘                      └─────────────────────┘
         │                                              │
         │ Present Activity                             │ Render in Notch
         │ Update Widget                                │ Show on Lock Screen
         │ Check Authorization                          │ Manage Permissions
         └─────────────────────────────────────────────►┘
```

### Key Components

1. **AtollClient** - Main SDK interface (singleton)
2. **Data Models** - Codable descriptors for activities/widgets
3. **XPC Protocols** - Service contract between apps and Atoll
4. **Connection Manager** - Handles XPC lifecycle and retries
5. **Error Handling** - Comprehensive error types with localized messages

---

## Permission System

Users control which apps can display content in Atoll via **Settings → Extensions**:

1. App requests authorization via `requestAuthorization()`
2. Atoll shows permission dialog
3. User approves/denies
4. Status is saved and can be revoked anytime

Apps should handle authorization gracefully:

```swift
do {
    let authorized = try await AtollClient.shared.requestAuthorization()
    if !authorized {
        // Show in-app message explaining why permission is needed
    }
} catch AtollExtensionKitError.atollNotInstalled {
    // Prompt user to install Atoll
} catch {
    print("Authorization error: \(error)")
}
```

---

## Priority System

When multiple activities compete for space, **priority** determines visibility:

| Priority | Use Case |
|----------|----------|
| `.critical` | Urgent alerts (timer ending, critical reminders) |
| `.high` | Important tasks (workouts, cooking timers) |
| `.normal` | Standard activities (music, downloads) |
| `.low` | Background info (syncing, updates) |

**Rules:**
- Higher priority always wins
- Activities can coexist with music if `allowMusicCoexistence = true`
- Equal priority → newest wins
- Users can manually dismiss anything

---

## Best Practices

### ✅ Do

- Use appropriate priorities (most should be `.normal`)
- Keep titles/subtitles concise (1-7 words)
- Update efficiently (max 1/second)
- Listen for `onActivityDismiss` callbacks
- Handle errors gracefully
- Validate descriptors before presenting

### ❌ Don't

- Overuse `.critical` priority
- Present dismissed activities immediately
- Send updates faster than 1/second
- Ignore authorization errors
- Assume Atoll is installed

---

## Size Limits

| Property | Limit |
|----------|-------|
| Live activity title | 50 characters |
| Live activity subtitle | 100 characters |
| Icon image data | 5 MB |
| Lock screen widget size | 500×300 pt max |
| Widget content elements | 20 max |
| Activity duration | 24 hours |

Validation is enforced client-side and server-side.

---

## Error Handling

All SDK methods throw typed errors:

```swift
enum AtollExtensionKitError: LocalizedError {
    case atollNotInstalled          // Atoll not found
    case notAuthorized              // User denied permission
    case serviceUnavailable         // XPC service down
    case connectionFailed(Error)    // Network/XPC issue
    case invalidDescriptor(String)  // Validation failed
    case activityNotFound(String)   // Activity ID not found
    case widgetNotFound(String)     // Widget ID not found
    case unknown(String)            // Other errors
}
```

Each error provides a localized description for user-facing messages.

---

## Callbacks

Listen for events from Atoll:

```swift
// Authorization changed (user toggled in settings)
AtollClient.shared.onAuthorizationChange = { isAuthorized in
    print("Authorization: \(isAuthorized)")
}

// Activity dismissed by user
AtollClient.shared.onActivityDismiss = { activityID in
    print("Activity \(activityID) was dismissed")
}

// Widget dismissed by user
AtollClient.shared.onWidgetDismiss = { widgetID in
    print("Widget \(widgetID) was dismissed")
}
```

---

## Sample Apps

Check out example integrations:

- **PomodoroTimer** - Focus timer with live activity
- **DownloadManager** - Progress tracking in notch
- **CryptoTracker** - Lock screen price widget
- **WorkoutTracker** - Exercise session with heart rate

*(Coming soon in `Examples/` directory)*

---

## Troubleshooting

### "Atoll Not Installed" Error

Users must install Atoll from [atoll.app](https://atoll.app) before using AtollExtensionKit.

### "Service Unavailable" Error

- Ensure Atoll is running
- Check if Atoll is updating
- Restart Atoll if needed

### Activities Not Appearing

1. Check authorization: `try await AtollClient.shared.checkAuthorization()`
2. Verify Atoll Settings → Extensions shows your app as authorized
3. Check priority (higher priority activities hide lower ones)
4. Ensure descriptor validation passes

### XPC Connection Issues

- Mach service requires Atoll to be running
- Connections auto-retry with exponential backoff
- Check Console.app for XPC errors

---

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Submit a pull request

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

---

## License

AtollExtensionKit is available under the **MIT License**. See [LICENSE](LICENSE) for details.

---

## Support

- 📧 **Email:** support@atoll.app
- 🐦 **Twitter:** [@AtollApp](https://twitter.com/AtollApp)
- 💬 **Discord:** [Join Server](https://discord.gg/atoll)
- 🐛 **Issues:** [GitHub Issues](https://github.com/ebullioscopic/AtollExtensionKit/issues)

---

## Credits

Built with ❤️ by the Atoll team.

Special thanks to the community for feedback and contributions!

---

**⭐ If you find AtollExtensionKit useful, please star the repo!**
