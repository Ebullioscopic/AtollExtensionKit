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
    
    /// Leading icon (left side)
    public let leadingIcon: AtollIconDescriptor
    
    /// Trailing content configuration
    public let trailingContent: AtollTrailingContent
    
    /// Optional progress indicator
    public let progressIndicator: AtollProgressIndicator?
    
    /// Progress value (0.0 to 1.0)
    public let progress: Double
    
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
    
    public init(
        id: String,
        bundleIdentifier: String,
        priority: AtollLiveActivityPriority = .normal,
        title: String,
        subtitle: String? = nil,
        leadingIcon: AtollIconDescriptor,
        trailingContent: AtollTrailingContent = .none,
        progressIndicator: AtollProgressIndicator? = nil,
        progress: Double = 0,
        accentColor: AtollColorDescriptor = .accent,
        badgeIcon: AtollIconDescriptor? = nil,
        allowsMusicCoexistence: Bool = false,
        estimatedDuration: TimeInterval? = nil,
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.bundleIdentifier = bundleIdentifier
        self.priority = priority
        self.title = title
        self.subtitle = subtitle
        self.leadingIcon = leadingIcon
        self.trailingContent = trailingContent
        self.progressIndicator = progressIndicator
        self.progress = min(max(progress, 0), 1)
        self.accentColor = accentColor
        self.badgeIcon = badgeIcon
        self.allowsMusicCoexistence = allowsMusicCoexistence
        self.estimatedDuration = estimatedDuration
        self.metadata = metadata
    }
    
    /// Convenience initializer that automatically uses the main bundle identifier.
    /// - Parameters:
    ///   - id: Unique identifier for this activity
    ///   - priority: Activity priority level
    ///   - title: Activity title
    ///   - subtitle: Optional subtitle
    ///   - leadingIcon: Leading icon descriptor
    ///   - trailingContent: Trailing content configuration
    ///   - progressIndicator: Optional progress indicator
    ///   - progress: Progress value (0.0 to 1.0)
    ///   - accentColor: Accent color descriptor
    ///   - badgeIcon: Optional badge icon
    ///   - allowsMusicCoexistence: Whether to allow music coexistence
    ///   - estimatedDuration: Estimated activity duration
    ///   - metadata: Custom metadata
    public init(
        id: String,
        priority: AtollLiveActivityPriority = .normal,
        title: String,
        subtitle: String? = nil,
        leadingIcon: AtollIconDescriptor,
        trailingContent: AtollTrailingContent = .none,
        progressIndicator: AtollProgressIndicator? = nil,
        progress: Double = 0,
        accentColor: AtollColorDescriptor = .accent,
        badgeIcon: AtollIconDescriptor? = nil,
        allowsMusicCoexistence: Bool = false,
        estimatedDuration: TimeInterval? = nil,
        metadata: [String: String] = [:]
    ) {
        self.init(
            id: id,
            bundleIdentifier: Bundle.main.bundleIdentifier ?? "",
            priority: priority,
            title: title,
            subtitle: subtitle,
            leadingIcon: leadingIcon,
            trailingContent: trailingContent,
            progressIndicator: progressIndicator,
            progress: progress,
            accentColor: accentColor,
            badgeIcon: badgeIcon,
            allowsMusicCoexistence: allowsMusicCoexistence,
            estimatedDuration: estimatedDuration,
            metadata: metadata
        )
    }
    
    /// Validates the descriptor
    public var isValid: Bool {
        !id.isEmpty &&
        !bundleIdentifier.isEmpty &&
        !title.isEmpty &&
        leadingIcon.isValid &&
        (badgeIcon?.isValid ?? true) &&
        trailingContent.isValid &&
        progress >= 0 && progress <= 1
    }
}

/// Trailing content configuration for the right side of the activity.
public enum AtollTrailingContent: Codable, Sendable, Hashable {
    /// Text label
    case text(String, font: AtollFontDescriptor = .system(size: 12, weight: .medium))
    
    /// Icon
    case icon(AtollIconDescriptor)
    
    /// Spectrum visualization (like music)
    case spectrum(color: AtollColorDescriptor = .accent)
    
    /// Custom Lottie animation
    case animation(data: Data, size: CGSize = CGSize(width: 50, height: 30))
    
    /// No trailing content
    case none
    
    var isValid: Bool {
        switch self {
        case .icon(let descriptor):
            return descriptor.isValid
        case .animation(let data, _):
            return data.count <= 5_242_880 // 5MB limit
        default:
            return true
        }
    }
}
