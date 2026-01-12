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
        size.width <= 500 && size.height <= 300 &&
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
    
    public init(alignment: Alignment = .center, verticalOffset: CGFloat = 0, horizontalOffset: CGFloat = 0) {
        self.alignment = alignment
        self.verticalOffset = min(max(verticalOffset, -200), 200)
        self.horizontalOffset = min(max(horizontalOffset, -300), 300)
    }
    
    public static let `default` = AtollWidgetPosition(alignment: .center, verticalOffset: 0, horizontalOffset: 0)
    
    public enum Alignment: String, Codable, Sendable, Hashable {
        case leading, center, trailing
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
        default:
            return true
        }
    }
}
