# AtollExtensionKit

[![Swift](https://img.shields.io/badge/Swift-6.2-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-macOS%2013.0+-lightgrey.svg)](https://www.apple.com/macos/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

**AtollExtensionKit** is a Swift SDK that allows third-party macOS applications to display custom live activities and lock screen widgets inside [Atoll (DynamicIsland)](https://atoll.app).

## Features

✨ **Live Activities** - Display real-time information in the closed notch  
🎨 **Flexible Layouts** - Interchangeable trailing content (Rings, Bars, Countdowns, Marquees)  
🫧 **Sneak Peek 2.0** - Inline marquee notifications replicating native Music behavior  
⚡ **Type-Safe** - Simple, clean API with validation  
🔐 **Secure** - Sandboxed and permission-based  

## Quick Start

### 1. Define Activity
```swift
let activity = AtollLiveActivityDescriptor(
    id: "timer-01",
    title: "Focus Timer",
    leadingIcon: .symbol(name: "timer", size: 16),
    trailingContent: .countdown(targetDate: Date().addingTimeInterval(300)),
    accentColor: .accent,
    sneakPeekConfig: .inline()
)
```

### 2. Submit
```swift
try await AtollClient.shared.startLiveActivity(activity)
```

## Documentation

See [API_DOCUMENTATION.md](API_DOCUMENTATION.md) for full details on:
- Authorization
- `AtollTrailingContent` types
- `AtollSneakPeekConfig` styling
- Icons and Colors
