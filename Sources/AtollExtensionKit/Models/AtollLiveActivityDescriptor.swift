//
//  AtollLiveActivityDescriptor.swift
//  AtollExtensionKit
//
//  Complete descriptor for third-party live activities.
//

import Foundation
import CoreGraphics

/// Describes a live activity to be displayed in Atoll's Dynamic Island.
public struct AtollLiveActivityDescriptor: Codable, Sendable, Hashable, Identifiable {
    /// Unique identifier for this activity (must be unique per app)
    public let id: String
    
    /// Application bundle identifier
    public let bundleIdentifier: String
    
    /// Activity priority level
    public let priority: AtollLiveActivityPriority
    
    /// Activity title (shown in notch)
    public let title: String
    
    /// Optional subtitle
    public let subtitle: String?
    
    /// Leading icon (left side) - Strictly Icon, Image or Lottie
    public let leadingIcon: AtollIconDescriptor
    
    /// Trailing content configuration (right side) - Strictly one type
    public let trailingContent: AtollTrailingContent
    
    /// Accent color for UI elements
    public let accentColor: AtollColorDescriptor
    
    /// Badge icon overlaying the leading icon (optional)
    public let badgeIcon: AtollIconDescriptor?
    
    /// When true, allows the activity to display alongside music playback
    public let allowsMusicCoexistence: Bool
    
    /// Estimated duration (for auto-dismissal planning, nil = persistent)
    public let estimatedDuration: TimeInterval?
    
    /// Custom metadata (app-specific)
    public let metadata: [String: String]

    /// Controls how the title/subtitle render in the center column
    public let centerTextStyle: AtollCenterTextStyle
    
    /// Sneak peek configuration (auto-shows title/subtitle on change)
    public let sneakPeekConfig: AtollSneakPeekConfig?

    /// Optional override for the sneak peek title (defaults to `title`)
    public let sneakPeekTitle: String?

    /// Optional override for the sneak peek subtitle (defaults to `subtitle`)
    public let sneakPeekSubtitle: String?

    private enum CodingKeys: String, CodingKey {
        case id
        case bundleIdentifier
        case priority
        case title
        case subtitle
        case leadingIcon
        case trailingContent
        case accentColor
        case badgeIcon
        case allowsMusicCoexistence
        case estimatedDuration
        case metadata
        case centerTextStyle
        case sneakPeekConfig
        case sneakPeekTitle
        case sneakPeekSubtitle
    }
    
    public init(
        id: String,
        bundleIdentifier: String,
        priority: AtollLiveActivityPriority = .normal,
        title: String,
        subtitle: String? = nil,
        leadingIcon: AtollIconDescriptor,
        trailingContent: AtollTrailingContent = .none,
        accentColor: AtollColorDescriptor = .accent,
        badgeIcon: AtollIconDescriptor? = nil,
        allowsMusicCoexistence: Bool = false,
        estimatedDuration: TimeInterval? = nil,
        metadata: [String: String] = [:],
        centerTextStyle: AtollCenterTextStyle = .inheritUser,
        sneakPeekConfig: AtollSneakPeekConfig? = nil,
        sneakPeekTitle: String? = nil,
        sneakPeekSubtitle: String? = nil
    ) {
        self.id = id
        self.bundleIdentifier = bundleIdentifier
        self.priority = priority
        self.title = title
        self.subtitle = subtitle
        self.leadingIcon = leadingIcon
        self.trailingContent = trailingContent
        self.accentColor = accentColor
        self.badgeIcon = badgeIcon
        self.allowsMusicCoexistence = allowsMusicCoexistence
        self.estimatedDuration = estimatedDuration
        self.metadata = metadata
        self.centerTextStyle = centerTextStyle
        self.sneakPeekConfig = sneakPeekConfig
        self.sneakPeekTitle = sneakPeekTitle
        self.sneakPeekSubtitle = sneakPeekSubtitle
    }
    
    /// Convenience initializer that automatically uses the main bundle identifier.
    /// - Parameters:
    ///   - id: Unique identifier for this activity
    ///   - priority: Activity priority level
    ///   - title: Activity title
    ///   - subtitle: Optional subtitle
    ///   - leadingIcon: Leading icon descriptor
    ///   - trailingContent: Trailing content configuration
    ///   - accentColor: Accent color descriptor
    ///   - badgeIcon: Optional badge icon
    ///   - allowsMusicCoexistence: Whether to allow music coexistence
    ///   - sneakPeekConfig: Sneak peek configuration for title/subtitle display
    public init(
        id: String,
        priority: AtollLiveActivityPriority = .normal,
        title: String,
        subtitle: String? = nil,
        leadingIcon: AtollIconDescriptor,
        trailingContent: AtollTrailingContent = .none,
        accentColor: AtollColorDescriptor = .accent,
        badgeIcon: AtollIconDescriptor? = nil,
        allowsMusicCoexistence: Bool = false,
        estimatedDuration: TimeInterval? = nil,
        metadata: [String: String] = [:],
        centerTextStyle: AtollCenterTextStyle = .inheritUser,
        sneakPeekConfig: AtollSneakPeekConfig? = nil,
        sneakPeekTitle: String? = nil,
        sneakPeekSubtitle: String? = nil
    ) {
        self.init(
            id: id,
            bundleIdentifier: Bundle.main.bundleIdentifier ?? "",
            priority: priority,
            title: title,
            subtitle: subtitle,
            leadingIcon: leadingIcon,
            trailingContent: trailingContent,
            accentColor: accentColor,
            badgeIcon: badgeIcon,
            allowsMusicCoexistence: allowsMusicCoexistence,
            estimatedDuration: estimatedDuration,
            metadata: metadata,
            centerTextStyle: centerTextStyle,
            sneakPeekConfig: sneakPeekConfig,
            sneakPeekTitle: sneakPeekTitle,
            sneakPeekSubtitle: sneakPeekSubtitle
        )
    }
    
    /// Validates the descriptor
    public var isValid: Bool {
        !id.isEmpty &&
        !bundleIdentifier.isEmpty &&
        !title.isEmpty &&
        leadingIcon.isValid &&
        (badgeIcon?.isValid ?? true) &&
        trailingContent.isValid
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        bundleIdentifier = try container.decode(String.self, forKey: .bundleIdentifier)
        priority = try container.decode(AtollLiveActivityPriority.self, forKey: .priority)
        title = try container.decode(String.self, forKey: .title)
        subtitle = try container.decodeIfPresent(String.self, forKey: .subtitle)
        leadingIcon = try container.decode(AtollIconDescriptor.self, forKey: .leadingIcon)
        trailingContent = try container.decodeIfPresent(AtollTrailingContent.self, forKey: .trailingContent) ?? .none
        accentColor = try container.decode(AtollColorDescriptor.self, forKey: .accentColor)
        badgeIcon = try container.decodeIfPresent(AtollIconDescriptor.self, forKey: .badgeIcon)
        allowsMusicCoexistence = try container.decodeIfPresent(Bool.self, forKey: .allowsMusicCoexistence) ?? false
        estimatedDuration = try container.decodeIfPresent(TimeInterval.self, forKey: .estimatedDuration)
        sneakPeekConfig = try container.decodeIfPresent(AtollSneakPeekConfig.self, forKey: .sneakPeekConfig)
        metadata = try container.decodeIfPresent([String: String].self, forKey: .metadata) ?? [:]
        centerTextStyle = try container.decodeIfPresent(AtollCenterTextStyle.self, forKey: .centerTextStyle) ?? .inheritUser
        sneakPeekTitle = try container.decodeIfPresent(String.self, forKey: .sneakPeekTitle)
        sneakPeekSubtitle = try container.decodeIfPresent(String.self, forKey: .sneakPeekSubtitle)
    }
}

/// Center text presentation style for live activities.
public enum AtollCenterTextStyle: String, Codable, Sendable, Hashable {
    /// Follow the user's Sneak Peek style preference inside Atoll.
    case inheritUser
    /// Always use the stacked (default) presentation.
    case standard
    /// Use the inline Sneak Peek presentation with marquee support.
    case inline
}

/// Trailing content configuration for the right side of the activity.
public enum AtollTrailingContent: Codable, Sendable, Hashable {
    /// Text label
    case text(
        String,
        font: AtollFontDescriptor = .system(size: 12, weight: .medium),
        color: AtollColorDescriptor? = nil
    )

    /// Marquee text label
    case marquee(
        String,
        font: AtollFontDescriptor = .system(size: 12, weight: .medium),
        minDuration: Double = 0.4,
        color: AtollColorDescriptor? = nil
    )

    /// Countdown (mm:ss / HH:mm:ss) rendered as text
    case countdown(
        targetDate: Date,
        font: AtollFontDescriptor = .monospacedDigit(size: 13, weight: .semibold),
        color: AtollColorDescriptor? = nil
    )
    
    /// Icon or Image
    case icon(AtollIconDescriptor)
    
    /// Spectrum visualization (like music)
    case spectrum(color: AtollColorDescriptor = .accent)
    
    /// Custom Lottie animation
    case animation(data: Data, size: CGSize = CGSize(width: 50, height: 30))
    
    /// Circular progress ring
    case ring(
        value: Double,
        diameter: CGFloat = 24,
        strokeWidth: CGFloat = 3,
        color: AtollColorDescriptor? = nil
    )
    
    /// Horizontal progress bar
    case bar(
        value: Double,
        total: Double = 1.0,
        height: CGFloat = 4,
        cornerRadius: CGFloat = 2,
        color: AtollColorDescriptor? = nil
    )
    
    /// No trailing content
    case none
    
    public var isValid: Bool {
        switch self {
        case .icon(let descriptor):
            return descriptor.isValid
        case .animation(let data, _):
            return data.count <= 5_242_880 // 5MB limit
        case .marquee(let text, _, _, _):
            return !text.isEmpty
        case .countdown(_, _, _):
            return true
        case .text(let text, _, _):
            return !text.isEmpty
        case .ring(let value, _, _, _):
            return value >= 0 && value <= 1
        case .bar(let value, let total, _, _, _):
            return total > 0 && value >= 0
        default:
            return true
        }
    }
}

/// Configuration for sneak peek presentation of live activity content.
public struct AtollSneakPeekConfig: Codable, Sendable, Hashable {
    /// Whether to show sneak peek when activity appears or updates
    public let enabled: Bool
    
    /// Display duration in seconds (nil = use default, .infinity = persistent)
    public let duration: TimeInterval?
    
    /// Presentation style (overrides user preference if set)
    public let style: AtollSneakPeekStyle?
    
    /// Whether to trigger sneak peek on every update (vs only initial presentation)
    public let showOnUpdate: Bool
    
    public init(
        enabled: Bool = true,
        duration: TimeInterval? = nil,
        style: AtollSneakPeekStyle? = nil,
        showOnUpdate: Bool = false
    ) {
        self.enabled = enabled
        self.duration = duration
        self.style = style
        self.showOnUpdate = showOnUpdate
    }
    
    /// Default configuration (enabled, respects user preferences)
    public static let `default` = AtollSneakPeekConfig()
    
    /// Disabled sneak peek
    public static let disabled = AtollSneakPeekConfig(enabled: false)
    
    /// Inline style with custom duration
    public static func inline(duration: TimeInterval? = nil) -> AtollSneakPeekConfig {
        AtollSneakPeekConfig(duration: duration, style: .inline)
    }
    
    /// Standard style with custom duration
    public static func standard(duration: TimeInterval? = nil) -> AtollSneakPeekConfig {
        AtollSneakPeekConfig(duration: duration, style: .standard)
    }
}

/// Sneak peek presentation style for live activities.
public enum AtollSneakPeekStyle: String, Codable, Sendable, Hashable {
    /// Use the standard stacked presentation (title above subtitle)
    case standard
    
    /// Use the inline presentation with marquee support
    case inline
}
