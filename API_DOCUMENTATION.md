# AtollExtensionKit API Documentation

**Version:** 1.0.0  
**Platform:** macOS 13.0+  
**Language:** Swift 6.2  

AtollExtensionKit enables third-party applications to display custom live activities and lock screen widgets inside the Atoll (DynamicIsland) app.

---

## Table of Contents

1. [Getting Started](#getting-started)
2. [Authorization](#authorization)
3. [Live Activities](#live-activities)
4. [Lock Screen Widgets](#lock-screen-widgets)
5. [Priority System](#priority-system)
6. [Best Practices](#best-practices)
7. [Size Limits & Validation](#size-limits--validation)
8. [Error Handling](#error-handling)
9. [Examples](#examples)

---

## Getting Started

### Installation

Add AtollExtensionKit to your project using Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/ebullioscopic/AtollExtensionKit.git", from: "1.0.0")
]
```

### Import

```swift
import AtollExtensionKit
```

### Check if Atoll is Installed

```swift
if AtollClient.shared.isAtollInstalled {
    print("Atoll is available!")
}
```

### Request Authorization

Before presenting any content, you must request user authorization:

```swift
do {
    let authorized = try await AtollClient.shared.requestAuthorization()
    if authorized {
        print("User authorized this app!")
    }
} catch {
    print("Authorization failed: \(error)")
}
```

---

## Authorization

### Authorization Flow

1. **Request**: Call `requestAuthorization()` to show a permission dialog in Atoll
2. **User Decision**: User approves/denies in Atoll Settings → Extensions tab
3. **Result**: Returns `Bool` indicating authorization status

### Check Current Status

```swift
let isAuthorized = try await AtollClient.shared.checkAuthorization()
```

### Listen for Changes

```swift
AtollClient.shared.onAuthorizationChange = { isAuthorized in
    print("Authorization changed: \(isAuthorized)")
}
```

---

## Live Activities

Live activities appear in the closed Dynamic Island notch, similar to timer, music, or reminder indicators.

### Step-by-Step Workflow

1. **Authorize** – call `requestAuthorization()` as soon as practical and ask users to approve the Extensions permission inside Atoll if the call returns `false`.
2. **Assemble a descriptor** – create an `AtollLiveActivityDescriptor` with a persistent `id`, concise title/subtitle, a `leadingIcon` (or explicit `leadingContent` override), trailing content (text/progress/marquee/countdown/animation), and optional `centerTextStyle`, progress indicator, or accent color. Keep payloads lean to pass validation.
3. **Validate/test** – during development you can run `ExtensionDescriptorValidator.validate(_:)` (part of the SDK) on sample descriptors or unit tests to catch size/length violations before shipping.
4. **Present** – send the descriptor via `presentLiveActivity(_:)`. Re-use the same `id` for the life of the session.
5. **Update & dismiss** – call `updateLiveActivity(_:)` whenever the state changes, then `dismissLiveActivity(activityID:)` when the session ends so Atoll frees the slot.
6. **Monitor callbacks & logs** – subscribe to `onActivityDismiss` to detect user revocations, and enable *Extension diagnostics logging* inside Atoll → Settings → Extensions to see each payload, validation result, and display decision in Console.app.

### Creating a Live Activity

```swift
let activity = AtollLiveActivityDescriptor(
    id: "workout-timer",
    bundleIdentifier: Bundle.main.bundleIdentifier!,
    priority: .normal,
    title: "Workout Timer",
    subtitle: "Chest & Triceps",
    leadingIcon: .symbol(name: "figure.strengthtraining.traditional", color: .orange),
    trailingContent: .text("Set 2/4"),
    progressIndicator: .ring(color: .orange, lineWidth: 3),
    accentColor: .orange,
    leadingContent: .countdownText(
        targetDate: Date().addingTimeInterval(1800),
        font: .monospacedDigit(size: 13, weight: .semibold)
    ),
    centerTextStyle: .inline
)

try await AtollClient.shared.presentLiveActivity(activity)
```

### Updating a Live Activity

```swift
var updated = activity
updated.subtitle = "5 reps remaining"
try await AtollClient.shared.updateLiveActivity(updated)
```

### Dismissing a Live Activity

```swift
try await AtollClient.shared.dismissLiveActivity(activityID: "workout-timer")
```

### Listening for Dismissal

```swift
AtollClient.shared.onActivityDismiss = { activityID in
    print("Activity \(activityID) was dismissed by user")
}
```

### Trailing Content Options

**Text label:**
```swift
.text("Running", font: .system(weight: .medium))
```

**Marquee text:**
```swift
.marquee("Half Marathon Training", font: .system(weight: .semibold), minDuration: 0.5)
```

**Countdown text:**
```swift
.countdownText(
    targetDate: Date().addingTimeInterval(3600),
    font: .monospacedDigit(size: 13, weight: .semibold)
)
```

**Icon:**
```swift
.icon(.symbol(name: "timer", color: .green))
```

**Spectrum visualization:**
```swift
.spectrum(color: .accent)
```

**Lottie animation:**
```swift
.animation(data: lottieData, size: .init(width: 60, height: 32))
```

**None:**
```swift
.none
```

> ℹ️ `leadingContent` accepts the same `AtollTrailingContent` cases, letting you move timers, marquee text, or animations to the left wing when needed.

### Leading Segment Overrides

By default Atoll renders the `leadingIcon` you provide. Supplying `leadingContent` swaps the entire left wing for any `AtollTrailingContent`, which is useful for timers that need both a badge and a digital countdown.

```swift
var descriptor = activity
descriptor.leadingContent = .countdownText(
    targetDate: targetDate,
    font: .monospacedDigit(size: 12, weight: .semibold)
)
descriptor.badgeIcon = .symbol(name: "flame", color: .orange)
```

### Center Text Styles

`AtollCenterTextStyle` controls how the title/subtitle render in the middle column:

- `.inheritUser` (default) mirrors the user's Sneak Peek style preference inside Atoll.
- `.standard` forces the classic stacked layout (title above subtitle).
- `.inline` renders title/subtitle on a single line with marquee support, matching Atoll's inline Sneak Peek layout.

```swift
var inlineDescriptor = activity
inlineDescriptor.centerTextStyle = .inline
```

### Progress Indicators

**Ring (circular):**
```swift
.ring(color: .blue, lineWidth: 3)
```

**Bar (horizontal):**
```swift
.bar(color: .green, height: 4)
```

**Percentage:**
```swift
.percentage(color: .purple, font: .system(weight: .bold))
```

**Countdown timer:**
```swift
.countdown(color: .red, font: .monospacedDigit()())
```

**Lottie animation (Base64 JSON):**
```swift
.lottie(base64Json: lottieBase64String, scale: 1.5)
```

**None:**
```swift
.none
```

---

## Lock Screen Widgets

Widgets appear on the macOS lock screen similar to weather, music, or battery indicators.

### Creating a Lock Screen Widget

```swift
let widget = AtollLockScreenWidgetDescriptor(
    id: "stock-ticker",
    bundleIdentifier: Bundle.main.bundleIdentifier!,
    layoutStyle: .inline,
    position: .init(
        alignment: .centerLeft,
        offsetX: 50,
        offsetY: -100
    ),
    material: .frosted(opacity: 0.8),
    content: [
        .icon(.symbol(name: "chart.line.uptrend.xyaxis", color: .green)),
        .text("AAPL", font: .system(weight: .semibold)),
        .text("$175.43", font: .system(weight: .bold), color: .green),
        .text("+2.3%", font: .system(weight: .medium), color: .green)
    ]
)

try await AtollClient.shared.presentLockScreenWidget(widget)
```

### Layout Styles

**Inline (horizontal row):**
```swift
.inline
```

**Circular (centered badge):**
```swift
.circular(diameter: 120)
```

**Card (rectangular container):**
```swift
.card(cornerRadius: 16)
```

**Custom:**
```swift
.custom(width: 300, height: 100)
```

### Content Elements

**Icon:**
```swift
.icon(.symbol(name: "bolt.fill", color: .yellow))
```

**Text:**
```swift
.text("Battery", font: .system(), color: .white)
```

**Progress:**
```swift
.progress(value: 0.75, style: .linear, color: .green)
```

**Graph:**
```swift
.graph(dataPoints: [0.2, 0.5, 0.8, 0.6], color: .blue)
```

**Gauge:**
```swift
.gauge(value: 0.6, range: 0...1, color: .orange)
```

**Spacer:**
```swift
.spacer(width: 10)
```

**Divider:**
```swift
.divider(color: .gray.withAlphaComponent(0.3), thickness: 1)
```

### Materials

**Frosted glass:**
```swift
.frosted(opacity: 0.9)
```

**Liquid effect:**
```swift
.liquid(blurRadius: 20)
```

**Solid background:**
```swift
.solid(color: .black.withAlphaComponent(0.7))
```

---

## Priority System

When multiple live activities compete for space, priority determines visibility:

| Priority | Use Case | Examples |
|----------|----------|----------|
| `.critical` | Time-sensitive alerts | Timers at 0:00, critical reminders |
| `.high` | Important ongoing tasks | Active workouts, cooking timers |
| `.normal` | Standard activities | Music playback, background tasks |
| `.low` | Informational updates | Download progress, syncing |

### Priority Rules

- **Higher priority always wins** when space is limited
- Activities with `.allowMusicCoexistence = true` can share space with music
- Equal priority → newest activity takes precedence
- User can manually dismiss any activity regardless of priority

---

## Best Practices

### 1. **Use Appropriate Priorities**
- Don't overuse `.critical` — reserve for genuinely urgent content
- Most activities should use `.normal`

### 2. **Keep Content Concise**
- Titles: 1-3 words recommended
- Subtitles: 3-7 words maximum
- Trailing content should be scannable at a glance

### 3. **Choose Icons Wisely**
- Use SF Symbols when possible for consistency
- Keep custom images under 100KB
- Avoid complex multi-color icons

### 4. **Music Coexistence**
```swift
activity.allowMusicCoexistence = true
```
Set this for activities that should appear alongside music playback.

### 5. **Update Efficiently**
- Batch multiple property changes into one `updateLiveActivity()` call
- Don't update more than once per second
- Dismiss activities when no longer needed

### 6. **Handle Errors Gracefully**
```swift
do {
    try await AtollClient.shared.presentLiveActivity(activity)
} catch AtollExtensionKitError.notAuthorized {
    // Prompt user to authorize in Atoll settings
} catch AtollExtensionKitError.atollNotInstalled {
    // Show install prompt
} catch {
    // Handle other errors
}
```

### 7. **Respect User Preferences**
- Listen for `onActivityDismiss` callbacks
- Don't immediately re-present dismissed activities
- Provide in-app settings to disable live activities
- Leave `centerTextStyle` at `.inheritUser` whenever possible so the view respects the user's Sneak Peek preference; only force `.inline` or `.standard` when your layout requires a specific treatment.

---

## Size Limits & Validation

### Live Activities

| Property | Limit | Notes |
|----------|-------|-------|
| Title | 50 characters | Truncated if longer |
| Subtitle | 100 characters | Optional |
| Icon image data | 5 MB | Validation enforced |
| Lottie JSON (Base64) | 5 MB | Animation data |
| Activity duration | 24 hours max | Auto-dismissed after |
| Update rate | 1/second | Throttled server-side |

### Lock Screen Widgets

| Property | Limit | Notes |
|----------|-------|-------|
| Widget width | 500 pt max | Enforced |
| Widget height | 300 pt max | Enforced |
| Content elements | 20 max | Performance |
| Text length | 100 chars | Per element |
| Image data | 5 MB | Per icon |
| Graph data points | 100 max | Performance |

### Validation Errors

AtollExtensionKit validates all descriptors before sending to Atoll:

```swift
catch AtollExtensionKitError.invalidDescriptor(let reason) {
    print("Validation failed: \(reason)")
}
```

---

## Error Handling

### Error Types

```swift
enum AtollExtensionKitError: LocalizedError {
    case atollNotInstalled
    case notAuthorized
    case serviceUnavailable
    case connectionFailed(underlying: Error)
    case invalidDescriptor(reason: String)
    case activityNotFound(activityID: String)
    case widgetNotFound(widgetID: String)
    case unknown(String)
}
```

### Common Scenarios

**Atoll Not Installed:**
```swift
catch AtollExtensionKitError.atollNotInstalled {
    let alert = NSAlert()
    alert.messageText = "Atoll Required"
    alert.informativeText = "Please install Atoll from atoll.app"
    alert.runModal()
}
```

**Not Authorized:**
```swift
catch AtollExtensionKitError.notAuthorized {
    // Prompt user to open Atoll Settings → Extensions
}
```

**Service Unavailable:**
```swift
catch AtollExtensionKitError.serviceUnavailable {
    // Atoll might be quitting or updating, retry later
}
```

---

## Examples

### Example 1: Pomodoro Timer

```swift
import AtollExtensionKit

class PomodoroManager {
    let client = AtollClient.shared
    
    func startPomodoro() async throws {
        let activity = AtollLiveActivityDescriptor(
            id: "pomodoro-\(UUID())",
            bundleIdentifier: Bundle.main.bundleIdentifier!,
            priority: .high,
            title: "Focus Time",
            subtitle: "Deep Work Session",
            leadingIcon: .symbol(name: "brain.head.profile", color: .purple),
            trailingContent: .countdownText(
                targetDate: Date().addingTimeInterval(25 * 60),
                font: .monospacedDigit()(weight: .semibold, design: .rounded)
            ),
            progressIndicator: .ring(color: .purple, lineWidth: 3),
            accentColor: .purple,
            allowMusicCoexistence: true,
            maxDuration: 1500
        )
        
        try await client.presentLiveActivity(activity)
    }
}
```

### Example 2: Download Manager

```swift
func showDownload(filename: String, progress: Double) async throws {
    let activity = AtollLiveActivityDescriptor(
        id: "download-\(filename)",
        bundleIdentifier: Bundle.main.bundleIdentifier!,
        priority: .low,
        title: "Downloading",
        subtitle: filename,
        leadingIcon: .symbol(name: "arrow.down.circle.fill", color: .blue),
        trailingContent: .text("\(Int(progress * 100))%"),
        progressIndicator: .bar(color: .blue, height: 4),
        progress: progress,
        accentColor: .blue
    )
    
    try await AtollClient.shared.updateLiveActivity(activity)
}
```

### Example 3: Cryptocurrency Tracker Widget

```swift
func showCryptoWidget(symbol: String, price: Double, change: Double) async throws {
    let isPositive = change >= 0
    let color: AtollColorDescriptor = isPositive ? .green : .red
    
    let widget = AtollLockScreenWidgetDescriptor(
        id: "crypto-\(symbol)",
        bundleIdentifier: Bundle.main.bundleIdentifier!,
        layoutStyle: .inline,
        position: .init(alignment: .topCenter, offsetX: 0, offsetY: 100),
        material: .frosted(opacity: 0.85),
        content: [
            .icon(.symbol(name: "bitcoinsign.circle.fill", color: .orange)),
            .spacer(width: 8),
            .text(symbol, font: .system(weight: .bold)),
            .spacer(width: 12),
            .text("$\(String(format: "%.2f", price))", 
                  font: .monospacedDigit()(weight: .semibold), 
                  color: .white),
            .spacer(width: 8),
            .text(String(format: "%+.2f%%", change), 
                  font: .monospacedDigit()(weight: .medium), 
                  color: color)
        ]
    )
    
    try await AtollClient.shared.presentLockScreenWidget(widget)
}
```

### Example 4: Workout Session

```swift
func startWorkout() async throws {
    let activity = AtollLiveActivityDescriptor(
        id: "workout-\(Date().timeIntervalSince1970)",
        bundleIdentifier: Bundle.main.bundleIdentifier!,
        priority: .high,
        title: "Workout",
        subtitle: "Upper Body",
        leadingIcon: .symbol(name: "figure.strengthtraining.traditional", color: .orange),
        trailingContent: .text("142 bpm"),
        progressIndicator: .percentage(
            color: .orange,
            font: .system(weight: .bold, design: .rounded)
        ),
        accentColor: .orange,
        allowMusicCoexistence: true,
        metadata: ["startTime": "\(Date())"]
    )
    
    try await AtollClient.shared.presentLiveActivity(activity)
}
```

---

## Version Compatibility

Check the Atoll version at runtime:

```swift
let version = try await AtollClient.shared.getVersion()
print("Atoll version: \(version)")
```

Minimum supported Atoll version: **1.0.0**

---

## Support & Resources

- **Website:** https://atoll.app
- **Documentation:** https://docs.atoll.app
- **GitHub:** https://github.com/ebullioscopic/AtollExtensionKit
- **Issues:** https://github.com/ebullioscopic/AtollExtensionKit/issues

---

## License

AtollExtensionKit is available under the MIT license. See LICENSE for details.
