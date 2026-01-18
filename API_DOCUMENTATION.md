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
5. [Notch Experiences](#notch-experiences)
6. [Priority System](#priority-system)
7. [Best Practices](#best-practices)
8. [Size Limits & Validation](#size-limits--validation)
9. [Error Handling](#error-handling)
10. [Examples](#examples)

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

### Run the Samples

Two sample targets under [`Samples`](Samples) mirror the workflows described in this document:

- `Samples/AtollXcodeSample` is a Swift Package CLI target. Run `swift run --package-path Samples/AtollXcodeSample` to print the SDK version, build a descriptor, and validate that `AtollClient.shared` is reachable—ideal for sanity-checking your toolchain before touching UI code.
- `Samples/AtollXcodeSampleApp` is a SwiftUI macOS app. Open `AtollXcodeSampleApp.xcodeproj`, build, and run to see the descriptor validator and client ping buttons we use when testing inline Sneak Peek download/icon-trailing demos. Edit `Sources/App/ContentView.swift` to swap in your own descriptors (e.g., countdown text + progress indicator) and observe how Atoll renders them.

Use these projects as living documentation: copy/paste the descriptor snippets from this guide into the sample app to verify inline Sneak Peek colors, trailing bars, and badge sizes before integrating them into your product.

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
2. **Assemble a descriptor** – create an `AtollLiveActivityDescriptor` with a persistent `id`, concise title/subtitle, a `leadingIcon` (optionally swapped for another icon/Lottie via `leadingContent`), trailing content (text/marquee/countdown/icon/animation), and optional `centerTextStyle`, `sneakPeekConfig`, or accent color. If you instead want a ring/bar/percentage on the right wing, set `trailingContent = .none` and supply a `progressIndicator`—the two are mutually exclusive. Use `allowsMusicCoexistence` when your activity can share space with music. Keep payloads lean to pass validation.
3. **Validate/test** – during development you can run `ExtensionDescriptorValidator.validate(_:)` (part of the SDK) on sample descriptors or unit tests to catch size/length violations before shipping.
4. **Present** – send the descriptor via `presentLiveActivity(_:)`. Re-use the same `id` for the life of the session.
5. **Update & dismiss** – call `updateLiveActivity(_:)` whenever the state changes, then `dismissLiveActivity(activityID:)` when the session ends so Atoll frees the slot.
6. **Monitor callbacks & logs** – subscribe to `onActivityDismiss` to detect user revocations, and enable *Extension diagnostics logging* inside Atoll → Settings → Extensions to see each payload, validation result, and display decision in Console.app.

### Sneak Peek Configuration

Extension live activities support **sneak peek** – a temporary HUD that displays your title/subtitle when the activity appears or updates, preventing text from rendering behind the physical notch.

- **Enable automatically** – Omit `sneakPeekConfig` (or set it to `.default`) to show title/subtitle in a brief HUD when your activity is presented. Text only appears via sneak peek, never under the notch hardware.
- **Custom duration** – Use `.inline(duration: 3.5)` or `.standard(duration: 2.0)` to control how long the sneak peek displays (in seconds).
- **Show on updates** – Pass `AtollSneakPeekConfig(enabled: true, showOnUpdate: true)` to trigger sneak peek every time you update the activity, not just on initial presentation.
- **Disable sneak peek** – Set `sneakPeekConfig: .disabled` to prevent automatic HUD displays. Your activity will still render in the closed notch, but the title/subtitle will be hidden to avoid text under the hardware.
- **Style override** – Use `.inline()` or `.standard()` to force a specific presentation style, overriding the user's Atoll preference. Leave `style: nil` to inherit the user's setting.

You can also override the HUD copy without changing the main descriptor text by setting `sneakPeekTitle` and `sneakPeekSubtitle`. These optional fields fall back to `title` / `subtitle` when omitted, allowing you to keep the notch copy short while presenting richer messaging inside the sneak peek.

**Important:** Atoll no longer renders extension titles/subtitles inside the closed notch. Even if you disable sneak peek, the center column stays empty so nothing ever collides with the hardware cutout. Always provide `sneakPeekTitle` / `sneakPeekSubtitle` (falling back to `title` / `subtitle`) so the HUD has copy to display.

Inline sneak peek mirrors the reminder/timer live activity layout: your `leadingContent` or `leadingIcon` occupies the left wing, the center seam remains blank for notch safety, and the trailing wing renders either your `trailingContent` or `progressIndicator` using the same ring/countdown sizing logic as the built-in reminder and timer views. Plan for concise glyphs or progress accents instead of center text whenever the user selects inline sneak peek.

### Inline Sneak Peek & Dismissals

- **Inline sneak peek copy** – Provide `sneakPeekTitle` / `sneakPeekSubtitle` (falling back to `title` / `subtitle`) so the reminder-style HUD has text to display. The inline layout keeps the notch center empty, so this HUD is the only surface that shows copy.
- **Leading overrides** – Use `leadingContent` when you need to replace the default icon with another `AtollIconDescriptor` or a bundled Lottie animation. Text-based cases are rejected so the left wing always stays purely visual.
- **Music coexistence** – Mark `allowsMusicCoexistence = true` for activities that can share space with music playback; Atoll will place your badge on the album art and shift the right wing automatically.
- **User-driven dismissals** – Register `AtollClient.shared.onActivityDismiss` to learn when someone closes your activity using Atoll’s hover affordance. Shut down background work once this callback fires to avoid recreating the activity immediately.- **Smooth animations** – Activities appear with a subtle spring scale-in animation and fade-out on dismissal. Updates to the same activity ID animate smoothly without jarring transitions.
Inline sneak peek now follows the reminder/timer live activity layout: the left wing shows your `leadingContent`, the center remains blank, and the right wing renders either your `trailingContent` or `progressIndicator`. Rings, digital countdowns, and bar indicators reuse the same sizing rules as reminder/timer, so the HUD stays balanced regardless of which wing content you choose.
### Creating a Live Activity

```swift
let activity = AtollLiveActivityDescriptor(
    id: "workout-timer",
    bundleIdentifier: Bundle.main.bundleIdentifier!,
    priority: .normal,
    title: "Workout Timer",
    subtitle: "Chest & Triceps",
    leadingIcon: .symbol(name: "figure.strengthtraining.traditional", color: .orange),
    leadingContent: .icon(
        .appIcon(
            bundleIdentifier: "com.example.workout",
            size: CGSize(width: 28, height: 28),
            cornerRadius: 6
        )
    ),
    trailingContent: .marquee(
        "Set 2 of 4",
        font: .system(size: 12, weight: .medium),
        minDuration: 0.5
    ),
    accentColor: .orange,
    badgeIcon: .symbol(name: "flame.fill", color: .orange),
    allowsMusicCoexistence: true,
    centerTextStyle: .inline,
    sneakPeekConfig: .inline(duration: 3.0),  // Shows title/subtitle for 3 seconds
    sneakPeekTitle: "Workout timer",
    sneakPeekSubtitle: "Set 2 of 4"
)

try await AtollClient.shared.presentLiveActivity(activity)
```

**With sneak peek on updates:**

```swift
let activity = AtollLiveActivityDescriptor(
    id: "download-progress",
    title: "Downloading",
    subtitle: "update-pkg-v2.dmg",
    leadingIcon: .symbol(name: "arrow.down.circle.fill", color: .blue),
    trailingContent: .none,
    progressIndicator: .percentage(color: .blue),
    progress: 0.45,
    accentColor: .blue,
    sneakPeekConfig: AtollSneakPeekConfig(
        enabled: true,
        duration: 2.0,
        style: .standard,
        showOnUpdate: true  // Show sneak peek on every progress update
    )
)
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
.text(
    "Running",
    font: .system(size: 12, weight: .medium),
    color: .accent  // Optional; defaults to the descriptor's accent color
)
```

**Marquee text:**
```swift
.marquee(
    "Half Marathon Training",
    font: .system(size: 12, weight: .semibold),
    minDuration: 0.5,
    color: .gray
)
```

**Countdown text:**
```swift
.countdownText(
    targetDate: Date().addingTimeInterval(3600),
    font: .monospacedDigit(size: 13, weight: .semibold),
    color: .green
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

> ℹ️ `leadingContent` only accepts `.icon` and `.animation` so the left wing always renders a graphic (symbol, app icon, image, or Lottie) instead of text.

All text-based trailing cases (`.text`, `.marquee`, `.countdownText`) honor an optional `color` override so you can differentiate labels (e.g., red errors, green success) without altering the descriptor-wide accent color.

### Leading Segment Overrides

By default Atoll renders the `leadingIcon` you provide. Supplying `leadingContent` swaps the entire left wing for another `AtollIconDescriptor` (including `.appIcon` / `.image`) or a Lottie animation when you need richer artwork than the default glyph.

```swift
var descriptor = activity
descriptor.leadingContent = .icon(
    .image(data: artworkPNGData, size: CGSize(width: 28, height: 28), cornerRadius: 6)
)
descriptor.badgeIcon = .symbol(name: "flame", color: .orange)
```

### Center Text Styles

`AtollCenterTextStyle` remains part of the data model for forward compatibility, but the Atoll host ignores it for extension live activities—the center column stays blank while the closed notch is visible. Use sneak peek text instead of relying on this property for active layouts.

### Progress Indicators

Progress indicators occupy the right wing whenever `trailingContent == .none`. If you provide any trailing content, the indicator is ignored and validation fails, ensuring the wing always renders a single visual element.

**Ring (circular):**
```swift
.ring(diameter: 26, strokeWidth: 3, color: .accent)
```

**Bar (horizontal):**
```swift
.bar(width: 90, height: 4, cornerRadius: 2, color: .orange)
```

**Percentage text:**
```swift
.percentage(font: .system(size: 13, weight: .bold), color: .accent)
```

**Countdown timer:**
```swift
.countdown(font: .monospacedDigit(size: 13, weight: .semibold), color: .accent)
```

**Lottie animation:**
```swift
.lottie(animationData: animationData, size: CGSize(width: 32, height: 32))
```

**None:**
```swift
.none
```

Every indicator except `.lottie` and `.none` accepts an optional `color` override so you can align the bar/ring/text tint with the semantic state you are representing without changing the descriptor-wide accent color.

---

## Lock Screen Widgets

Widgets appear on the macOS lock screen similar to weather, music, or battery indicators.

### Creating a Lock Screen Widget

```swift
let widget = AtollLockScreenWidgetDescriptor(
    id: "stock-ticker",
    bundleIdentifier: Bundle.main.bundleIdentifier!,
    layoutStyle: .card,
    position: .init(alignment: .leading, verticalOffset: -80, horizontalOffset: 60),
    size: CGSize(width: 220, height: 110),
    material: .frosted,
    appearance: .init(
        tintColor: .white,
        tintOpacity: 0.12,
        enableGlassHighlight: true,
        contentInsets: .init(top: 14, leading: 18, bottom: 14, trailing: 18),
        border: .init(color: .white, opacity: 0.18, width: 1),
        shadow: .init(color: .black, opacity: 0.35, radius: 26, offset: CGSize(width: 0, height: -10))
    ),
    cornerRadius: 18,
    content: [
        .icon(.symbol(name: "chart.line.uptrend.xyaxis", color: .green)),
        .text("AAPL", font: .system(size: 16, weight: .semibold), color: .white),
        .text("$175.43", font: .system(size: 22, weight: .bold), color: .green),
        .text("+2.3%", font: .system(size: 14, weight: .medium), color: .green, alignment: .trailing),
        .webView(
            .init(
                html: "<div class=\"sparkline\"></div><script>renderSparkline()</script>",
                preferredHeight: 90,
                isTransparent: true,
                allowLocalhostRequests: false
            )
        )
    ],
    accentColor: .accent,
    dismissOnUnlock: true,
    priority: .normal
)

try await AtollClient.shared.presentLockScreenWidget(widget)
```

### Layout Styles

- `.inline` – single-line layout similar to Atoll’s weather widgets (default size: 200×48 pt)
- `.circular` – compact circular badges for gauges or progress indicators (default: 100×100 pt)
- `.card` – rectangular surface for richer compositions (default: 220×120 pt)
- `.custom` – opt-in when you want full control over the size (defaults to 150×80 pt; still clamped to 640×360 pt)

### Content Elements

**Icon:**
```swift
.icon(.symbol(name: "bolt.fill", color: .yellow))
```

**Text:**
```swift
.text("Battery", font: .system(size: 14, weight: .medium), color: .white)
```

**Progress:**
```swift
.progress(.bar(width: 120, height: 4), value: 0.75, color: .green)
```

**Graph:**
```swift
.graph(data: [0.2, 0.5, 0.8, 0.6], color: .blue, size: CGSize(width: 160, height: 60))
```

**Gauge:**
```swift
.gauge(value: 0.6, minValue: 0, maxValue: 1, style: .circular, color: .orange)
```

**Spacer:**
```swift
.spacer(height: 8)
```

**Divider:**
```swift
.divider(color: .gray, thickness: 1)
```

**Web View:**
```swift
.webView(
    .init(
        html: "<div class=\"now-playing\">…</div>",
        preferredHeight: 110,
        isTransparent: true,
        allowLocalhostRequests: true
    )
)
```

### Lock Screen Materials & Positioning

- **Alignment-aware offsets** – `AtollWidgetPosition` accepts an alignment (`leading`, `center`, `trailing`) plus `verticalOffset` (±400 pt) and `horizontalOffset` (±600 pt). Use these fields instead of screen coordinates so widgets remain notch-safe across displays. Set `clampMode` to `.relaxed` or `.unconstrained` when you need to escape the default safe-area margins.
- **Material presets** – `AtollWidgetMaterial` includes `.frosted`, `.liquid`, `.solid`, `.semiTransparent`, and `.clear`. Pair liquid material with larger corner radii (≥20 pt) to mirror Atoll’s glass overlays and toggle `appearance.enableGlassHighlight` to request the effect even if you choose a different base material.
- **Deterministic sizing** – Provide a custom `size` when you need dimensions outside the layout style defaults. The SDK clamps all widgets to 640×360 pt to avoid overlap.

### Appearance Overrides

- **Tint overlays** – `appearance.tintColor` and `tintOpacity` add a translucent color wash above frosted/liquid materials without mutating the descriptor-wide accent.
- **Content insets** – Supply `appearance.contentInsets` (top/leading/bottom/trailing) to override the default padding and keep text/gauges perfectly aligned with your design system.
- **Borders & shadows** – Use `AtollWidgetBorderStyle` / `AtollWidgetShadowStyle` to specify custom borders and drop shadows. When `appearance.border` is omitted, Atoll falls back to a 1 pt white stroke (4% opacity).
- **Glass accents** – Enable `appearance.enableGlassHighlight` to request the macOS Liquid Glass treatment wherever available. On older systems the view gracefully falls back to `.regularMaterial`.

### Transparent Web Content

- **Sandboxed WKWebView** – `.webView` renders inline HTML/CSS/JS (max 20 KB) inside a mouse-disabled WKWebView so you can layer custom shaders, charts, or canvas effects over Atoll’s background.
- **Network policy** – Navigation is limited to `about:` / `data:` URLs unless you set `allowLocalhostRequests = true`, which whitelists `http://localhost` and `http://127.0.0.1` for dev servers. All other hosts are blocked for safety.
- **Visual control** – `isTransparent` clears the view’s background so only your markup appears. Provide `backgroundColor` when you need an explicit fill, and use `maximumContentWidth` to clamp how wide the surface can stretch.
- **Sizing** – `preferredHeight` drives the web view’s height (clamped to 40–420 pt). Combine it with layout `size` + padding to keep the chrome balanced.

### Widget Content Tips

- **Mix and match elements** – Compose `.text`, `.icon`, `.progress`, `.graph`, `.gauge`, `.spacer`, and `.divider` entries to create layered widgets without embedding executable UI code.
- **Bring your own chrome** – Use `.webView` for transparent HTML/CSS/JS overlays (think vector gradients, live charts, or sparkline canvases) while keeping gestures disabled and respecting Atoll’s security policy.
- **Use gauges for live metrics** – `.gauge` outputs circular or linear indicators with independent min/max ranges, perfect for weather, battery, or fitness statistics.
- **Respect color limits** – Stick to `AtollColorDescriptor` values so Atoll can enforce monochrome/high-contrast modes on colorful wallpapers.
- **Keep it light** – Each widget supports up to 20 content elements. Prefer summaries over dense graphs when possible to minimize rendering cost.

### Materials

- `.frosted` – translucent blur that mirrors Atoll’s default overlays
- `.liquid` – high-gloss “liquid glass” treatment for hero widgets
- `.solid` – opaque background using the widget’s accent color
- `.semiTransparent` – subtle tint with reduced opacity
- `.clear` – fully transparent background, ideal for minimalist text/icon layouts

---

## Notch Experiences

`AtollNotchExperienceDescriptor` lets you surface rich, structured content directly inside Atoll’s Dynamic Island. A descriptor can render:

- A **standard notch tab** that sits alongside built-in tabs (Timers, Shelf, etc.)
- An optional **minimalistic override** that replaces the compact music UI while the user’s minimalistic mode is active

Both surfaces share the same declarative building blocks as lock screen widgets, so SDK clients never send executable UI code—only structured content sections, optional icons, and sandboxed web payloads.

### Overview

- Requires the user to enable **Extensions → Allow extension notch experiences** inside Atoll Settings. Users can further toggle tabs, minimalistic overrides, and interactive web views individually; always provide a fallback path in your app.
- Capacity is limited (default: 2 simultaneous experiences). Submit only when there is meaningful information to show and dismiss promptly when stale.
- Tabs and minimalistic overrides are independent. You can ship one, the other, or both in the same descriptor.
- Content is rendered by Atoll; titles and copy never sit under the physical notch. Sneak Peek HUD handles headline text when tabs appear.

### Workflow

1. **Authorize** – Request authorization just like live activities. Notch experiences honor the same permission scope.
2. **Assemble the descriptor** – Populate the required metadata plus either `tab`, `minimalistic`, or both configurations.
3. **Validate locally** – Call `descriptor.isValid` or `ExtensionDescriptorValidator.validate(_:)` in your tests to catch layout/length issues before hitting the service.
4. **Present** – `try await AtollClient.shared.presentNotchExperience(descriptor)` queues the experience. Use a stable `id` per logical surface so updates replace the existing tab instead of creating duplicates.
5. **Update** – Re-send the descriptor with new content via `updateNotchExperience(_:)`. Prefer incremental updates over dismiss/re-present to keep animations smooth.
6. **Dismiss** – Call `dismissNotchExperience(experienceID:)` when the session ends, or respond to `onNotchExperienceDismiss` callbacks if the user revokes it from Atoll.
7. **Fallbacks** – When the user disables tabs, minimalistic overrides, or interactive web content, degrade gracefully inside your own UI instead of re-presenting.

### Descriptor Structure

Top-level fields mirror other Atoll descriptors:

- `id` and `bundleIdentifier` uniquely identify your experience.
- `priority` determines ordering relative to other extension tabs (same enum as live activities).
- `accentColor` tints dividers, highlights, and fallback UI elements.
- `metadata` carries up to 32 key/value pairs for diagnostics (never rendered to the user).
- `tab` / `minimalistic` hold their respective configurations. At least one must be present.

### Tab Experiences (`TabConfiguration`)

- **Presentation** – Tabs appear in Atoll’s Tab bar when `Enable extension notch tabs` is on. Users tap the tab to show your content; Atoll hides it automatically when the descriptor disappears.
- **Layout** – Provide up to 6 `AtollNotchContentSection` entries. Each section can be a `stack`, `columns`, or `metrics` layout and accepts the same `AtollWidgetContentElement` payloads as lock screen widgets (text, icons, graphs, gauges, progress, spacers, dividers, web views).
- **Sizing** – `preferredHeight` suggests how tall the tab should be (clamped to 160–420 pt). Atoll ensures the size stays within the notch frame.
- **Branding** – Use `iconSymbolName`, `badgeIcon`, and `appearance` to align with your app’s look. Keep labels short for accessibility.
- **Footnotes** – Optional footnote text (≤140 characters) appears beneath your content stack for legal copy or instructions.
- **Interactive web content** – Supply `webContent` plus `allowWebInteraction = true` when your tab needs a sandboxed WKWebView with keyboard/mouse input. Atoll rejects descriptors that contain web content if the user disabled **Allow interactive web content**.

### Minimalistic Replacements (`MinimalisticConfiguration`)

- **Use case** – Override the compact minimalistic music layout with extension-driven content while the user’s minimalistic mode is active.
- **Copy** – Optional `headline` (≤80 chars) and `subtitle` (≤120 chars) sit above your sections, mirroring the music title/subtitle area without touching the physical notch.
- **Sections** – Provide up to 3 sections with the same content elements as tabs. Minimalistic sections should remain lightweight to avoid overcrowding.
- **Web content** – Optional `webContent` renders a sandboxed view sized automatically by Atoll. It respects the same global interactive web toggle as tabs.
- **Layout hints** – `layout` communicates the general form factor (`.stack`, `.metrics`, `.custom`) so Atoll can adjust padding. Use `hidesMusicControls` if you need the music buttons removed entirely.

### Content Sections & Elements

- `AtollNotchContentSection` limits you to 6 elements per section. Each element is one of the existing widget building blocks (`.text`, `.icon`, `.progress`, `.graph`, `.gauge`, `.webView`, `.divider`, `.spacer`).
- Titles (≤80 chars) and subtitles (≤160 chars) are optional per section. Use them sparingly to keep the notch readable.
- Because these types are `Codable`, you can reuse existing widget-building utilities when assembling your notch descriptors.

### Interactive Web Content Policy

- HTML payloads share the lock screen widget limits (20 KB max, inline assets only).
- Navigation remains limited to `about:` / `data:` unless you explicitly allow localhost inside `AtollWidgetWebContentDescriptor` (useful for pointing at a dev server during testing).
- Set `allowWebInteraction = true` only when you genuinely need keyboard or mouse input. Tabs default to read-only web views.
- Atoll rejects descriptors that include web content when the user disables **Allow interactive web content** or when system security policies block the payload. Always render equivalent data using native elements whenever possible.

### Example

```swift
let descriptor = AtollNotchExperienceDescriptor(
    id: "finance-dashboard",
    priority: .high,
    accentColor: .init(red: 0.18, green: 0.65, blue: 0.94),
    tab: .init(
        title: "Finance",
        iconSymbolName: "chart.pie.fill",
        preferredHeight: 260,
        sections: [
            .init(
                id: "positions",
                title: "Positions",
                layout: .columns,
                elements: [
                    .text("AAPL", font: .system(size: 16, weight: .semibold), color: .white),
                    .text("$182.44", font: .monospacedDigit(size: 16, weight: .medium), color: .green),
                    .gauge(value: 0.72, minValue: 0, maxValue: 1, style: .circular, color: .green),
                    .divider(color: .white, thickness: 1)
                ]
            )
        ],
        webContent: .init(
            html: "<canvas id=\"spark\"></canvas><script>renderSpark()</script>",
            preferredHeight: 120,
            allowLocalhostRequests: false,
            isTransparent: true
        ),
        allowWebInteraction: false
    ),
    minimalistic: .init(
        headline: "Portfolio",
        subtitle: "Daily change +$1,820",
        sections: [
            .init(
                id: "overview",
                layout: .metrics,
                elements: [
                    .text("Top mover", font: .system(size: 13, weight: .regular), color: .white),
                    .text("+3.4%", font: .monospacedDigit(size: 15, weight: .semibold), color: .green)
                ]
            )
        ],
        hidesMusicControls: true
    )
)

try await AtollClient.shared.presentNotchExperience(descriptor)
```

### API Surface

```swift
try await AtollClient.shared.presentNotchExperience(descriptor)
try await AtollClient.shared.updateNotchExperience(descriptor)
try await AtollClient.shared.dismissNotchExperience(experienceID: descriptor.id)

AtollClient.shared.onNotchExperienceDismiss(experienceID: descriptor.id) {
    // Cleanup work / update UI
}
```

Use dismissal callbacks to stop background work when the user closes your tab from Atoll. If you re-present immediately, Atoll treats it as a new submission and re-applies validation/capacity checks.

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
- Activities with `.allowsMusicCoexistence = true` can share space with music
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
let descriptor = AtollLiveActivityDescriptor(
    id: "timer",
    bundleIdentifier: Bundle.main.bundleIdentifier!,
    title: "Timer",
    leadingIcon: .symbol(name: "timer", color: .blue),
    allowsMusicCoexistence: true
)
```
Set `allowsMusicCoexistence = true` for activities that should appear alongside music playback.

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

### 8. **Degrade when notch surfaces are disabled**
- Users can toggle notch experiences, extension tabs, minimalistic overrides, and interactive web content independently inside Atoll. Detect `AtollExtensionKitError.invalidDescriptor` / `AtollExtensionKitError.notAuthorized` responses and keep rendering equivalent information inside your own UI instead of looping on retries.
- Avoid presenting placeholder tabs just to reserve capacity. Submit descriptors only when you have live data to show and dismiss them when finished.

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
| Widget width | 640 pt max | Enforced |
| Widget height | 360 pt max | Enforced |
| Content elements | 20 max | Performance |
| Text length | 100 chars | Per element |
| Image data | 5 MB | Per icon |
| Graph data points | 100 max | Performance |
| Web content HTML | 20 KB | `.webView` payload |

### Notch Experiences

| Property | Limit | Notes |
|----------|-------|-------|
| Concurrent experiences | 2 global (default) | Host-enforced capacity |
| Tab sections | 6 max | Each section must be valid |
| Section elements | 6 max | Shares rules with widget elements |
| Tab preferred height | 160–420 pt | Clamped by host |
| Tab footnote | 140 characters | Optional |
| Minimalistic sections | 3 max | Keep content concise |
| Minimalistic headline | 80 characters | Optional |
| Minimalistic subtitle | 120 characters | Optional |
| Section title | 80 characters | Optional |
| Section subtitle | 160 characters | Optional |
| Web content HTML | 20 KB | Same limits as widgets |

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
                font: .monospacedDigit(size: 14, weight: .semibold)
            ),
            accentColor: .purple,
            allowsMusicCoexistence: true
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
        trailingContent: .none,
        progressIndicator: .bar(width: 110, height: 4),
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
        position: .init(alignment: .center, verticalOffset: 100),
        material: .frosted,
        content: [
            .icon(.symbol(name: "bitcoinsign.circle.fill", color: .orange)),
            .spacer(height: 4),
            .text(symbol, font: .system(size: 16, weight: .bold), color: .white),
            .spacer(height: 6),
            .text(
                "$\(String(format: "%.2f", price))",
                font: .monospacedDigit(size: 16, weight: .semibold),
                color: .white
            ),
            .spacer(height: 4),
            .text(
                String(format: "%+.2f%%", change),
                font: .monospacedDigit(size: 14, weight: .medium),
                color: color
            )
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
                font: .system(size: 14, weight: .bold, design: .rounded)
        ),
        accentColor: .orange,
            allowsMusicCoexistence: true,
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
