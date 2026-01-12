# AtollExtensionKit Quick Start Guide

## ✅ Ready to Use!

**AtollExtensionKit is fully functional and compatible with Atoll (DynamicIsland).** You can now integrate it into your third-party macOS apps.

---

## Installation

### Option 1: Add as Local Package (Recommended for Development)

1. **In your app's Xcode project:**
   - File → Add Package Dependencies...
   - Click "Add Local..."
   - Navigate to `/Users/hariharan/HobbyProjects/AtollExtensionKit`
   - Click "Add Package"
   - Select your app target and click "Add Package"

2. **Verify installation:**
   - Build your project (⌘B)
   - You should see `AtollExtensionKit` under "Package Dependencies" in the project navigator

### Option 2: Add via Package.swift

If you're building a command-line tool or Swift package:

```swift
dependencies: [
    .package(path: "/Users/hariharan/HobbyProjects/AtollExtensionKit")
],
targets: [
    .target(
        name: "YourTarget",
        dependencies: ["AtollExtensionKit"]
    )
]
```

### Common Installation Issues

**"No such module 'AtollExtensionKit'":**
1. Clean build folder: Product → Clean Build Folder (⇧⌘K)
2. Reset package caches: File → Packages → Reset Package Caches
3. Restart Xcode
4. Verify the package appears under "Package Dependencies" in Project Navigator
5. Make sure you selected your app target when adding the package

**Package won't resolve:**
- Ensure `/Users/hariharan/HobbyProjects/AtollExtensionKit` exists
- Check that `Package.swift` exists in that directory
- Try removing and re-adding the package dependency

### Import the Framework

```swift
import AtollExtensionKit
```

---

## Basic Usage

### Step 1: Request Authorization

```swift
let client = AtollClient()

do {
    let granted = try await client.requestAuthorization()
    if granted {
        print("✅ Authorized to use Atoll!")
    } else {
        print("❌ User denied authorization")
    }
} catch {
    print("Error: \(error.localizedDescription)")
}
```

### Step 2: Present a Live Activity

```swift
// Create a simple timer activity
let descriptor = AtollLiveActivityDescriptor(
    id: "my-timer-\(UUID().uuidString)",
    title: "Workout Timer",
    subtitle: "High Intensity Interval",
    leadingIcon: .symbol(name: "figure.run", size: 16),
    accentColor: .accent,
    priority: .normal,
    allowsMusicCoexistence: true
)

do {
    try await client.presentLiveActivity(descriptor)
    print("✅ Live activity presented!")
} catch {
    print("Error: \(error.localizedDescription)")
}
```

### Step 3: Update Activity

```swift
// Update with progress
var updated = descriptor
updated.progressValue = 0.75 // 75% complete

try await client.updateLiveActivity(updated)
```

### Step 4: Dismiss Activity

```swift
try await client.dismissLiveActivity(activityID: "my-timer-123")
```

---

## Lock Screen Widget Example

```swift
let widget = AtollLockScreenWidgetDescriptor(
    id: "weather-widget",
    style: .inline,
    elements: [
        .icon(.symbol(name: "cloud.sun.fill", size: 14), color: .color(red: 1, green: 0.8, blue: 0)),
        .text("72°F", font: .system(size: 14, weight: .semibold)),
        .spacer(width: 8),
        .text("Partly Cloudy", font: .system(size: 12, weight: .regular))
    ],
    backgroundColor: .clear,
    cornerRadius: 12
)

try await client.presentLockScreenWidget(widget)
```

---

## Integration Points with Atoll

### ✅ Server-Side Implementation Complete

1. **XPC Service** (`ExtensionXPCServiceHost`) - Listening on `com.ebullioscopic.Atoll.xpc`
2. **Authorization Manager** - Tracks approved apps in Settings → Extensions
3. **Live Activity Manager** - Renders third-party activities in the notch
4. **Lock Screen Widget Manager** - Displays widgets on lock screen
5. **Settings UI** - Full permission management interface
6. **ContentView Integration** - Extension activities work alongside system activities
7. **Validation Layer** - Security checks, rate limiting, size validation

### User Experience Flow

1. **First Request**: User sees permission dialog in Atoll Settings
2. **Authorization**: User approves/denies access in Settings → Extensions tab
3. **Live Activities**: Appear in closed notch with proper priority handling
4. **Lock Screen Widgets**: Render above system UI when screen is locked
5. **Management**: Users can revoke access, view activity stats, manage scopes

---

## Testing Your Integration

### 1. Build a Test App

```swift
import SwiftUI
import AtollExtensionKit

@main
struct TestApp: App {
    @State private var client = AtollClient()
    
    var body: some Scene {
        WindowGroup {
            ContentView(client: client)
        }
    }
}

struct ContentView: View {
    let client: AtollClient
    @State private var isAuthorized = false
    
    var body: some View {
        VStack(spacing: 20) {
            if isAuthorized {
                Button("Show Timer") {
                    Task {
                        try? await showTimer()
                    }
                }
            } else {
                Button("Request Authorization") {
                    Task {
                        isAuthorized = try await client.requestAuthorization()
                    }
                }
            }
        }
        .padding()
        .frame(width: 400, height: 300)
    }
    
    func showTimer() async throws {
        let timer = AtollLiveActivityDescriptor(
            id: "test-timer",
            title: "Test Timer",
            subtitle: "5:00 remaining",
            leadingIcon: .systemImage("timer"),
            accentColor: .accent,
            priority: .normal,
            allowsMusicCoexistence: true,
            progressValue: 0.5
        )
        try await client.presentLiveActivity(timer)
    }
}
```

### 2. Run Atoll (DynamicIsland)

Make sure Atoll is running before launching your test app.

### 3. Grant Permission

1. Launch your test app
2. Click "Request Authorization"
3. Open Atoll Settings → Extensions
4. Approve your app
5. Return to your test app and click "Show Timer"

### 4. Verify Display

- Live activity should appear in the notch (when closed)
- Check Settings → Extensions for activity stats
- Test updating/dismissing activities

---

## What's Supported

### ✅ Live Activities
- Custom titles, subtitles, body text
- SF Symbols, app icons, Base64 images
- Progress indicators (bar, ring, gauge styles)
- Custom colors and fonts
- Priority system (low/normal/high/critical)
- Music coexistence flag

### ✅ Lock Screen Widgets
- Inline, circular, and custom layouts
- Multiple content elements (text, icons, progress, graphs, gauges)
- Custom positioning and sizing
- Material backgrounds
- Auto-hide on unlock

### ✅ Permission System
- Per-app authorization
- Scope controls (Live Activities, Lock Screen Widgets)
- Revocation support
- Activity rate limiting
- Real-time status updates

---

## Error Handling

```swift
do {
    try await client.presentLiveActivity(descriptor)
} catch AtollExtensionKitError.unauthorized {
    // User hasn't granted permission
    print("Please authorize in Atoll Settings")
} catch AtollExtensionKitError.atollNotRunning {
    // Atoll isn't running
    print("Please launch Atoll first")
} catch AtollExtensionKitError.invalidDescriptor(let reason) {
    // Descriptor validation failed
    print("Invalid descriptor: \(reason)")
} catch AtollExtensionKitError.exceedsCapacity {
    // Too many active activities
    print("Maximum activities reached")
} catch {
    print("Unknown error: \(error)")
}
```

---

## Best Practices

1. **Check authorization early**: Request on first launch
2. **Handle Atoll offline**: Catch `.atollNotRunning` gracefully
3. **Respect rate limits**: Max 1 update/second per activity
4. **Use meaningful IDs**: Makes debugging easier
5. **Set appropriate priorities**: Don't abuse `.critical`
6. **Enable music coexistence**: Unless you need exclusive display
7. **Clean up activities**: Dismiss when no longer relevant
8. **Test permission revocation**: Handle mid-session revocation

---

## Limitations

- **Requires Atoll running**: No offline queuing
- **24-hour max duration**: Activities auto-dismiss after 24h
- **Rate limit**: 1 update/second per activity
- **Size limits**: 5MB for images/animations
- **macOS 13+**: Platform requirement
- **Main actor**: All APIs must be called from main thread

---

## Troubleshooting

### "Atoll not running"
- Launch Atoll (DynamicIsland.app)
- Check if XPC service started (check Atoll logs)

### "Unauthorized"
- Open Atoll Settings → Extensions
- Find your app in the list
- Click "Authorize"

### "Activity not showing"
- Check priority conflicts (system activities may take precedence)
- Verify `allowsMusicCoexistence` if music is playing
- Check Atoll Settings → Live Activities is enabled

### "Widget not appearing on lock screen"
- Ensure Atoll Settings → Extensions → Lock Screen Widgets is enabled
- Verify your app has "Lock Screen Widgets" scope enabled
- Lock screen must be active

---

## Full Documentation

See [API_DOCUMENTATION.md](API_DOCUMENTATION.md) for:
- Complete API reference
- All descriptor properties
- Advanced examples
- Performance guidelines
- Security considerations

---

## Support

For issues or questions:
1. Check Atoll logs: Settings → Extensions → Enable diagnostics logging
2. Verify authorization status in Settings → Extensions
3. Test with the sample code above
4. Review API documentation for parameter constraints

---

**You're all set!** Start building amazing Atoll integrations. 🚀
