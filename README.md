# AtollExtensionKit

[![Swift](https://img.shields.io/badge/Swift-6.2-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-macOS%2013.0+-lightgrey.svg)](https://www.apple.com/macos/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

**AtollExtensionKit** is a Swift SDK that allows third-party macOS applications to display custom live activities and lock screen widgets inside [Atoll (DynamicIsland)](https://atoll.app).

![AtollExtensionKit Demo](Media/demo.png)

## Features

✨ **Live Activities** - Display real-time information in the closed notch (timer, downloads, workouts, etc.)  
🔒 **Lock Screen Widgets** - Show custom widgets on the macOS lock screen  
🫧 **Sneak Peek Alignment** - Route titles/subtitles into Atoll's inline HUD so text never hides under the notch with configurable duration and modes  
🎨 **Full Customization** - Icons, colors, progress indicators, leading overrides, marquee/countdown trailing text, center styles, and sneak peek configuration  
🪟 **Transparent Web Widgets** - Liquid glass materials, custom borders/shadows, and sandboxed transparent web views for bespoke lock screen chrome  
⚡ **XPC Communication** - Fast, secure inter-process communication  
🔐 **Permission System** - User-controlled authorization in Atoll Settings  
📊 **Priority Management** - Smart conflict resolution when multiple activities compete  
✅ **Type-Safe** - Modern Swift API with Codable models and async/await  
🎬 **Smooth Animations** - Spring-based scale transitions for appear/dismiss with customizable sneak peek behavior

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

// 2. Create a live activity with sneak peek
let activity = AtollLiveActivityDescriptor(
    id: "my-timer",
    bundleIdentifier: Bundle.main.bundleIdentifier!,
    priority: .normal,
    title: "Timer",
    subtitle: "Focus Session",
    leadingIcon: .symbol(name: "timer", color: .blue),
    trailingContent: .countdownText(
        targetDate: Date().addingTimeInterval(1500),
        color: .blue
    ),
    centerTextStyle: .inline,
    accentColor: .blue,
    allowsMusicCoexistence: true,
    sneakPeekConfig: .inline(duration: 2.5),  // Show title/subtitle in HUD for 2.5 seconds
    sneakPeekTitle: "Deep focus",
    sneakPeekSubtitle: "Session 1"
)

// 3. Present it in Atoll
try await AtollClient.shared.presentLiveActivity(activity)
```

> ℹ️ If you omit `sneakPeekConfig`, Atoll defaults to the `.default` behavior (enabled, duration inherited from the host) so your title/subtitle still display in the Sneak Peek HUD while the notch stays clear. Pass `.disabled` to opt out and keep center text visible inside the notch.

> 🎯 Want a ring/bar/percentage on the right wing? Set `trailingContent: .none` and supply `progressIndicator` instead. Trailing text/content and progress indicators are mutually exclusive so the wing always renders a single element.

## Building a Live Activity

1. **Request authorization early** – call `requestAuthorization()` during app launch or onboarding and handle the `false` case with an in-app explanation linking to Atoll Settings → Extensions.
2. **Describe your activity** – populate `AtollLiveActivityDescriptor` with a stable `id`, a human-friendly title/subtitle, `leadingIcon` (optionally overridden with another icon/Lottie via `leadingContent`), trailing content (text, marquee, countdown, icon, animation), and (optionally) `centerTextStyle`, a mutually exclusive progress indicator, and accent color. Keep titles short and ensure custom images remain under 5 MB.
3. **Validate before sending** – the SDK performs client-side validation, but you can also call `ExtensionDescriptorValidator.validate(_:)` in tests to spot length/size issues before hitting Atoll.
4. **Present and update** – use `presentLiveActivity(_:)` for the initial payload, then `updateLiveActivity(_:)` with the same `id` whenever state changes. Dismiss finished sessions with `dismissLiveActivity(activityID:)` to free space for other apps.
5. **Listen for callbacks** – hook `onActivityDismiss` to learn when the user or Atoll revoked your activity so you can stop background work or show UI in your app.
6. **Debug with Atoll diagnostics** – inside Atoll → Settings → Extensions, enable *Extension diagnostics logging* to mirror every XPC payload, validation decision, and display outcome in the macOS Console under the `com.ebullioscopic.Atoll` subsystem. The new logs call out whether your activity rendered (music pairing vs standalone) or was hidden by user settings.

> ✅ Tip: keep a single long-lived `AtollClient.shared` reference per process and re-use descriptor builders to avoid repeatedly instantiating large payloads.

### Inline Sneak Peek & Dismissals

- **Sneak peek configuration** – Omit `sneakPeekConfig` (or set `.default`) to automatically route your title/subtitle into Atoll's HUD whenever the activity appears. Use `.inline(duration: 3.0)` or `.standard(duration: 2.0)` to customize the display style and duration, and set `showOnUpdate: true` to trigger sneak peek on every update. If you need the center text to remain visible inside the notch, explicitly pass `.disabled`; otherwise Atoll suppresses it while the notch is closed to avoid the hardware cutout.
- **HUD copy overrides** – Set `sneakPeekTitle` and `sneakPeekSubtitle` when you need different messaging in the HUD versus the main descriptor (e.g., concise notch title with a richer sneak peek phrase). These fall back to `title` / `subtitle` automatically.
- **Inline center text** – Set `centerTextStyle = .inline` (or leave `.inheritUser`) so Atoll can route your title/subtitle into its Sneak Peek HUD when the user prefers inline mode, keeping the closed notch clear. Pair this with concise trailing content so copy never collides with hardware cutouts.
- **Leading overrides** – Use `leadingContent` to swap the default icon for another icon/app icon or a bundled Lottie animation. Text-based entries are rejected so the left wing always stays purely visual.
- **Music coexistence** – Mark `allowsMusicCoexistence = true` for activities (e.g., timers) that can share space with the music tile; Atoll will place your badge on the album art and reserve the right wing automatically.
- **User-driven dismissals** – Register `AtollClient.shared.onActivityDismiss` to learn when someone closes your activity from the hover affordance in Atoll. Stop related background work once you receive the callback to keep resource usage low.
- **Smooth animations** – Activities appear with spring scale-in animations and fade-out on dismissal. Updates to the same activity ID animate smoothly without jarring transitions.

### Advanced Layout Controls

- **Leading segment overrides** – set `leadingContent` to replace the default icon with another `AtollIconDescriptor` or `.animation` payload (Lottie). The left wing never renders text/countdowns, keeping the notch hardware clear.
- **Center text styles** – choose between `.inheritUser` (default), `.standard`, and `.inline` via `centerTextStyle` to match or override the user's Sneak Peek preference.
- **Marquee & countdown trailing text** – use `.marquee` for long labels that need auto-scrolling and `.countdownText` for digital timers without building a custom animation.

```swift
var descriptor = activity
descriptor.leadingContent = .icon(.appIcon(bundleIdentifier: "com.example.workout", size: CGSize(width: 28, height: 28), cornerRadius: 6))
descriptor.trailingContent = .countdownText(targetDate: targetDate)
descriptor.centerTextStyle = .inline
```

Text-based trailing content (`.text`, `.marquee`, `.countdownText`) and every progress indicator except `.lottie`/`.none` accept an optional `color` parameter so you can align individual labels or gauges with their semantic meaning without changing the descriptor's primary accent color.

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
    leadingIcon: .symbol(name: "brain.head.profile", color: .purple),
    trailingContent: .countdownText(targetDate: Date().addingTimeInterval(25 * 60)),
    progressIndicator: .ring(diameter: 26, strokeWidth: 3, color: .purple),
    centerTextStyle: .inline,
    accentColor: .purple,
    allowsMusicCoexistence: true
)

try await AtollClient.shared.presentLiveActivity(activity)
```

### Lock Screen Widget

```swift
let widget = AtollLockScreenWidgetDescriptor(
    id: "weather",
    bundleIdentifier: Bundle.main.bundleIdentifier!,
    layoutStyle: .card,
    position: .init(alignment: .center, verticalOffset: 120, horizontalOffset: 0),
    size: CGSize(width: 240, height: 110),
    material: .liquid,
    appearance: .init(
        tintColor: .white,
        tintOpacity: 0.1,
        enableGlassHighlight: true,
        contentInsets: .init(top: 16, leading: 20, bottom: 16, trailing: 20),
        shadow: .init(color: .black, opacity: 0.35, radius: 32, offset: CGSize(width: 0, height: -12))
    ),
    cornerRadius: 20,
    content: [
        .icon(.symbol(name: "cloud.sun.fill", color: .yellow)),
        .text("San Francisco", font: .system(size: 16, weight: .semibold), color: .white),
        .text("72°F", font: .system(size: 28, weight: .bold), color: .white, alignment: .trailing),
        .gauge(value: 0.72, minValue: 0, maxValue: 1, style: .circular, color: .white),
        .webView(
            .init(
                html: "<div class=\"forecast\"></div>",
                preferredHeight: 80,
                isTransparent: true
            )
        )
    ],
    accentColor: .accent,
    dismissOnUnlock: true,
    priority: .normal
)

try await AtollClient.shared.presentLockScreenWidget(widget)
```

### Lock Screen Materials & Positioning

- **Alignment-aware offsets** – `AtollWidgetPosition` clamps horizontal offsets to ±600 pt and vertical offsets to ±400 pt relative to the requested alignment (`leading`, `center`, `trailing`). Set `clampMode` to `.relaxed` or `.unconstrained` to loosen the default safe-area constraints when you need full-bleed layouts.
- **Material presets** – Choose from `.frosted`, `.liquid`, `.solid`, `.semiTransparent`, or `.clear` via `AtollWidgetMaterial`. Pair `.liquid` or `appearance.enableGlassHighlight` with rounded corners for true “liquid glass” styling.
- **Deterministic sizing** – Supply an explicit `size` when you need dimensions outside each layout style’s default (e.g., taller inline widgets). The SDK automatically clamps to 640×360 pt to keep overlays separated.

Use `appearance` to override padding, borders, or shadows and `.webView` when you need a sandboxed HTML/CSS/JS layer (transparent by default, localhost-only networking when explicitly enabled).

### Widget Content Tips

- **Mix and match elements** – Combine `.text`, `.icon`, `.progress`, `.graph`, `.gauge`, `.spacer`, and `.divider` entries in the `content` array to build rich layouts without shipping executable UI code.
- **Use gauges for live metrics** – `.gauge` supports circular or linear styles with independent min/max ranges, making it ideal for weather, fitness rings, or battery indicators.
- **Respect color limits** – Stick to `AtollColorDescriptor` values so Atoll can enforce contrast modes (monochrome, high contrast) when rendering on top of lock screen wallpapers.
- **Keep it light** – Each widget may include up to 20 elements; reuse existing gauges/text elements instead of sending large graphs when a summary will do.

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
- Match the user’s Sneak Peek preference by using `.inheritUser` or opt into `.inline` when you want text routed into the HUD

### ❌ Don't

- Overuse `.critical` priority
- Present dismissed activities immediately
- Send updates faster than 1/second
- Ignore authorization errors
- Assume Atoll is installed
- Depend on center text staying visible when the user forces inline Sneak Peek — provide leading/trailing fallbacks instead

---

## Size Limits

| Property | Limit |
|----------|-------|
| Live activity title | 50 characters |
| Live activity subtitle | 100 characters |
| Icon image data | 5 MB |
| Lock screen widget size | 640×360 pt max |
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

---

## Credits

Built with ❤️ by the Atoll team.

Special thanks to the community for feedback and contributions!

---

**⭐ If you find AtollExtensionKit useful, please star the repo!**
