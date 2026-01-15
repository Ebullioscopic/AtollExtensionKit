# AtollExtensionKit API Documentation

**Version:** 1.1.0  
**Platform:** macOS 13.0+  
**Language:** Swift 6.2  

AtollExtensionKit enables third-party applications to display custom live activities and lock screen widgets inside the Atoll (DynamicIsland) app.

---

## Table of Contents

1. [Getting Started](#getting-started)
2. [Authorization](#authorization)
3. [Live Activities](#live-activities)
4. [Size Limits & Validation](#size-limits--validation)

---

## Getting Started

### Installation

Add AtollExtensionKit to your project using Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/ebullioscopic/AtollExtensionKit.git", from: "1.0.0")
]
```

### Authorization

Before presenting any content, you must request user authorization. This triggers a permission prompt inside the Atoll app.

```swift
// Request authorization
let authorized = try await AtollClient.shared.requestAuthorization()

// Check status later
let isAuthorized = try await AtollClient.shared.checkAuthorization()
```

---

## Live Activities

Live activities appear in the closed Dynamic Island notch. They are highly customizable but strictly structured to ensure consistency.

### `AtollLiveActivityDescriptor`

The core model for defining an activity.

```swift
public struct AtollLiveActivityDescriptor {
    public let id: String
    public let priority: AtollLiveActivityPriority
    public let title: String
    public let subtitle: String?
    public let leadingIcon: AtollIconDescriptor // Strict: Icon/Image/Lottie only
    public let trailingContent: AtollTrailingContent // Strict: One type only
    public let accentColor: AtollColorDescriptor
    public let badgeIcon: AtollIconDescriptor?
    public let allowsMusicCoexistence: Bool
    public let estimatedDuration: TimeInterval?
    public let sneakPeekConfig: AtollSneakPeekConfig?
    // ... initializers
}
```

### Components

#### 1. Leading Icon (`AtollIconDescriptor`)
The left side of the notch. Supports static symbols, images, app icons, and Lottie animations. No text allowed here.

- `.symbol(name:size:weight:)` - SF Symbol
- `.image(data:size:cornerRadius:)` - PNG/JPEG data
- `.appIcon(bundleIdentifier:)` - Another app's icon
- `.lottie(animationData:)` - Lottie JSON animation

#### 2. Trailing Content (`AtollTrailingContent`)
The right side of the notch. Highly versatile but **mutually exclusive** (you can only select one).

- `.text(String)` - Static label
- `.marquee(String)` - Scrolling text
- `.countdown(targetDate:)` - Live countdown timer
- `.ring(value:diameter:color:)` - Circular progress ring
- `.bar(value:total:color:)` - Horizontal progress bar
- `.icon(AtollIconDescriptor)` - Static icon/image
- `.animation(data:)` - Custom Lottie animation
- `.spectrum` - Music-style visualizer

#### 3. Sneak Peek (`AtollSneakPeekConfig`)
Controls the temporary overlay when an activity updates. Supports standard (stacked) or inline (marquee) styles.

- **Inline Mode**: Replicates the native Music sneak peek style. Text sits in the center, expanding from the bottom, with icon/visualizer on the wings.

```swift
// Inline sneak peek (like Music)
let config = AtollSneakPeekConfig.inline(duration: 3.0)

// Standard stacked sneak peek
let config = AtollSneakPeekConfig.standard(duration: 2.0)
```

---

## Example

```swift
let activity = AtollLiveActivityDescriptor(
    id: "workout-session",
    priority: .high,
    title: "Outdoor Run",
    subtitle: "Zone 2 • 145 BPM",
    leadingIcon: .symbol(name: "figure.run", size: 18, weight: .semibold),
    trailingContent: .ring(value: 0.7, diameter: 22, color: .hex("#FF5733")), // Progress Ring
    accentColor: .hex("#FF5733"),
    allowsMusicCoexistence: true,
    sneakPeekConfig: .inline(duration: 3.0)
)
```

---

## Validation Rules

- **Ids**: Must be unique per app.
- **Images/Lottie**: Max size 5MB.
- **Progress**: values between 0.0 and 1.0.
- **Trailing**: Only one type of content on the right wing.
