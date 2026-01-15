//
//  AtollLockScreenWidgetDescriptor.swift
//  AtollExtensionKit
//
//  Complete descriptor for lock screen widgets.
//

import Foundation
import CoreGraphics

/// Describes a lock screen widget to be displayed when the device is locked.
public struct AtollLockScreenWidgetDescriptor: Codable, Sendable, Hashable, Identifiable {
    /// Unique identifier for this widget (must be unique per app)
    public let id: String
    
    /// Application bundle identifier
    public let bundleIdentifier: String
    
    /// Widget layout style
    public let layoutStyle: AtollWidgetLayoutStyle
    
    /// Widget position on lock screen
    public let position: AtollWidgetPosition
    
    /// Widget size (width x height in points)
    public let size: CGSize
    
    /// Material/background style
    public let material: AtollWidgetMaterial
    
    /// Optional appearance overrides (tint, border, glass accent, etc.)
    public let appearance: AtollWidgetAppearanceOptions?

    /// Corner radius
    public let cornerRadius: CGFloat
    
    /// Content elements to display
    public let content: [AtollWidgetContentElement]
    
    /// Accent color for widget elements
    public let accentColor: AtollColorDescriptor
    
    /// Whether widget dismisses on unlock
    public let dismissOnUnlock: Bool
    
    /// Priority (affects layering when multiple widgets exist)
    public let priority: AtollLiveActivityPriority
    
    /// Custom metadata
    public let metadata: [String: String]
    
    public init(
        id: String,
        bundleIdentifier: String,
        layoutStyle: AtollWidgetLayoutStyle = .inline,
        position: AtollWidgetPosition = .default,
        size: CGSize? = nil,
        material: AtollWidgetMaterial = .frosted,
        appearance: AtollWidgetAppearanceOptions? = nil,
        cornerRadius: CGFloat = 16,
        content: [AtollWidgetContentElement],
        accentColor: AtollColorDescriptor = .accent,
        dismissOnUnlock: Bool = true,
        priority: AtollLiveActivityPriority = .normal,
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.bundleIdentifier = bundleIdentifier
        self.layoutStyle = layoutStyle
        self.position = position
        self.size = size ?? layoutStyle.defaultSize
        self.material = material
        self.appearance = appearance
        self.cornerRadius = min(max(cornerRadius, 0), 32)
        self.content = content
        self.accentColor = accentColor
        self.dismissOnUnlock = dismissOnUnlock
        self.priority = priority
        self.metadata = metadata
    }
    
    public var isValid: Bool {
        !id.isEmpty &&
        !bundleIdentifier.isEmpty &&
        !content.isEmpty &&
        size.width > 0 && size.height > 0 &&
        size.width <= 640 && size.height <= 360 &&
        (appearance?.isValid ?? true) &&
        content.allSatisfy(\.isValid)
    }
}

/// Widget layout style.
public enum AtollWidgetLayoutStyle: String, Codable, Sendable, Hashable {
    /// Single-line inline layout (similar to weather widget)
    case inline
    
    /// Circular/ring-based layout (gauges, progress)
    case circular
    
    /// Card with flexible content
    case card
    
    /// Custom layout (full control)
    case custom
    
    var defaultSize: CGSize {
        switch self {
        case .inline: return CGSize(width: 200, height: 48)
        case .circular: return CGSize(width: 100, height: 100)
        case .card: return CGSize(width: 220, height: 120)
        case .custom: return CGSize(width: 150, height: 80)
        }
    }
}

/// Widget position on lock screen.
public struct AtollWidgetPosition: Codable, Sendable, Hashable {
    /// Horizontal alignment
    public let alignment: Alignment
    
    /// Vertical offset from default position (positive = down)
    public let verticalOffset: CGFloat
    
    /// Horizontal offset from alignment (positive = right)
    public let horizontalOffset: CGFloat
    
    /// Clamp behavior when positioning near screen edges
    public let clampMode: ClampMode

    public init(
        alignment: Alignment = .center,
        verticalOffset: CGFloat = 0,
        horizontalOffset: CGFloat = 0,
        clampMode: ClampMode = .safeRegion
    ) {
        self.alignment = alignment
        self.verticalOffset = min(max(verticalOffset, -400), 400)
        self.horizontalOffset = min(max(horizontalOffset, -600), 600)
        self.clampMode = clampMode
    }
    
    public static let `default` = AtollWidgetPosition(
        alignment: .center,
        verticalOffset: 0,
        horizontalOffset: 0,
        clampMode: .safeRegion
    )
    
    public enum Alignment: String, Codable, Sendable, Hashable {
        case leading, center, trailing
    }

    public enum ClampMode: String, Codable, Sendable, Hashable {
        /// Uses Atoll's default lock screen safe region insets
        case safeRegion

        /// Slightly relaxes safe area enforcement for larger canvases
        case relaxed

        /// Only clamps to the visible screen bounds
        case unconstrained
    }

    private enum CodingKeys: String, CodingKey {
        case alignment
        case verticalOffset
        case horizontalOffset
        case clampMode
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let alignment = try container.decodeIfPresent(Alignment.self, forKey: .alignment) ?? .center
        let vertical = try container.decodeIfPresent(CGFloat.self, forKey: .verticalOffset) ?? 0
        let horizontal = try container.decodeIfPresent(CGFloat.self, forKey: .horizontalOffset) ?? 0
        let clampMode = try container.decodeIfPresent(ClampMode.self, forKey: .clampMode) ?? .safeRegion
        self.alignment = alignment
        self.verticalOffset = min(max(vertical, -400), 400)
        self.horizontalOffset = min(max(horizontal, -600), 600)
        self.clampMode = clampMode
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(alignment, forKey: .alignment)
        try container.encode(verticalOffset, forKey: .verticalOffset)
        try container.encode(horizontalOffset, forKey: .horizontalOffset)
        try container.encode(clampMode, forKey: .clampMode)
    }
}

/// Widget material/background style.
public enum AtollWidgetMaterial: String, Codable, Sendable, Hashable {
    /// Frosted glass effect
    case frosted
    
    /// Liquid glass effect
    case liquid
    
    /// Solid color background
    case solid
    
    /// Semi-transparent
    case semiTransparent
    
    /// Clear background
    case clear
}

/// Content element within a widget.
public enum AtollWidgetContentElement: Codable, Sendable, Hashable {
    /// Text label
    case text(String, font: AtollFontDescriptor, color: AtollColorDescriptor? = nil, alignment: TextAlignment = .leading)
    
    /// Icon
    case icon(AtollIconDescriptor, tint: AtollColorDescriptor? = nil)
    
    /// Progress indicator
    case progress(AtollProgressIndicator, value: Double, color: AtollColorDescriptor? = nil)
    
    /// Graph/chart (simple line data)
    case graph(data: [Double], color: AtollColorDescriptor, size: CGSize)
    
    /// Gauge (circular or linear)
    case gauge(value: Double, minValue: Double = 0, maxValue: Double = 1, style: GaugeStyle = .circular, color: AtollColorDescriptor? = nil)
    
    /// Spacer
    case spacer(height: CGFloat)
    
    /// Horizontal divider
    case divider(color: AtollColorDescriptor = .gray, thickness: CGFloat = 1)

    /// Sandboxed transparent web content (HTML/CSS/JS only)
    case webView(AtollWidgetWebContentDescriptor)
    
    public enum TextAlignment: String, Codable, Sendable, Hashable {
        case leading, center, trailing
    }
    
    public enum GaugeStyle: String, Codable, Sendable, Hashable {
        case circular, linear
    }
    
    var isValid: Bool {
        switch self {
        case .icon(let descriptor, _):
            return descriptor.isValid
        case .graph(let data, _, let size):
            return !data.isEmpty && data.count <= 100 && size.width > 0 && size.height > 0
        case .gauge(let value, let min, let max, _, _):
            return value >= min && value <= max
        case .webView(let descriptor):
            return descriptor.isValid
        default:
            return true
        }
    }
}

// MARK: - Appearance Controls

public struct AtollWidgetAppearanceOptions: Codable, Sendable, Hashable {
    public let tintColor: AtollColorDescriptor?
    public let tintOpacity: Double
    public let enableGlassHighlight: Bool
    public let contentInsets: AtollWidgetContentInsets?
    public let border: AtollWidgetBorderStyle?
    public let shadow: AtollWidgetShadowStyle?

    public init(
        tintColor: AtollColorDescriptor? = nil,
        tintOpacity: Double = 0.85,
        enableGlassHighlight: Bool = false,
        contentInsets: AtollWidgetContentInsets? = nil,
        border: AtollWidgetBorderStyle? = nil,
        shadow: AtollWidgetShadowStyle? = nil
    ) {
        self.tintColor = tintColor
        self.tintOpacity = min(max(tintOpacity, 0), 1)
        self.enableGlassHighlight = enableGlassHighlight
        self.contentInsets = contentInsets
        self.border = border
        self.shadow = shadow
    }

    var isValid: Bool {
        (border?.isValid ?? true) && (shadow?.isValid ?? true)
    }
}

public struct AtollWidgetBorderStyle: Codable, Sendable, Hashable {
    public let color: AtollColorDescriptor
    public let opacity: Double
    public let width: CGFloat

    public init(color: AtollColorDescriptor, opacity: Double = 0.35, width: CGFloat = 1) {
        self.color = color
        self.opacity = min(max(opacity, 0), 1)
        self.width = min(max(width, 0), 6)
    }

    var isValid: Bool { width <= 6 && width >= 0 }
}

public struct AtollWidgetShadowStyle: Codable, Sendable, Hashable {
    public let color: AtollColorDescriptor
    public let opacity: Double
    public let radius: CGFloat
    public let offset: CGSize

    public init(
        color: AtollColorDescriptor,
        opacity: Double = 0.45,
        radius: CGFloat = 18,
        offset: CGSize = .zero
    ) {
        self.color = color
        self.opacity = min(max(opacity, 0), 1)
        self.radius = min(max(radius, 0), 60)
        let clampedX = min(max(offset.width, -80), 80)
        let clampedY = min(max(offset.height, -80), 80)
        self.offset = CGSize(width: clampedX, height: clampedY)
    }

    var isValid: Bool { radius >= 0 }
}

public struct AtollWidgetContentInsets: Codable, Sendable, Hashable {
    public let top: CGFloat
    public let leading: CGFloat
    public let bottom: CGFloat
    public let trailing: CGFloat

    public init(top: CGFloat = 0, leading: CGFloat = 0, bottom: CGFloat = 0, trailing: CGFloat = 0) {
        let clamp: (CGFloat) -> CGFloat = { value in
            min(max(value, 0), 96)
        }
        self.top = clamp(top)
        self.leading = clamp(leading)
        self.bottom = clamp(bottom)
        self.trailing = clamp(trailing)
    }
}

// MARK: - Web Content

public struct AtollWidgetWebContentDescriptor: Codable, Sendable, Hashable {
    public let html: String
    public let preferredHeight: CGFloat
    public let isTransparent: Bool
    public let allowLocalhostRequests: Bool
    public let backgroundColor: AtollColorDescriptor?
    public let maximumContentWidth: CGFloat?

    public init(
        html: String,
        preferredHeight: CGFloat = 140,
        isTransparent: Bool = true,
        allowLocalhostRequests: Bool = false,
        backgroundColor: AtollColorDescriptor? = nil,
        maximumContentWidth: CGFloat? = nil
    ) {
        self.html = html
        self.preferredHeight = min(max(preferredHeight, 40), 420)
        self.isTransparent = isTransparent
        self.allowLocalhostRequests = allowLocalhostRequests
        self.backgroundColor = backgroundColor
        if let width = maximumContentWidth {
            self.maximumContentWidth = max(40, min(width, 640))
        } else {
            self.maximumContentWidth = nil
        }
    }

    var isValid: Bool {
        let trimmed = html.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && html.utf8.count <= 20000
    }
}
