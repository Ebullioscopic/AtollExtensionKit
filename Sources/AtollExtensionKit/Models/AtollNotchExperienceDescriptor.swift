//
//  AtollNotchExperienceDescriptor.swift
//  AtollExtensionKit
//
//  Describes third-party notch content rendered inside the Dynamic Island.
//

import Foundation
import CoreGraphics

/// Declarative descriptor for rich notch content surfaces.
///
/// Use this descriptor to render a dedicated Dynamic Island tab (standard UI)
/// and/or replace the minimalistic music layout when the user enables that mode.
public struct AtollNotchExperienceDescriptor: Codable, Sendable, Hashable, Identifiable {
    /// Unique identifier (per app)
    public let id: String

    /// Application bundle identifier
    public let bundleIdentifier: String

    /// Rendering priority relative to other extension payloads
    public let priority: AtollLiveActivityPriority

    /// Accent color used for highlights, dividers, and fallback tinting
    public let accentColor: AtollColorDescriptor

    /// Optional metadata passed through to the host for diagnostics/logging
    public let metadata: [String: String]

    /// Standard notch tab configuration (optional)
    public let tab: TabConfiguration?

    /// Minimalistic replacement configuration (optional)
    public let minimalistic: MinimalisticConfiguration?

    /// Optional duration hint that helps Atoll schedule automatic dismissal
    public let durationHint: TimeInterval?

    /// Convenience property for validation
    public var isValid: Bool {
        guard !id.isEmpty,
              !bundleIdentifier.isEmpty,
              tab != nil || minimalistic != nil else {
            return false
        }

        if let tab, !tab.isValid {
            return false
        }

        if let minimalistic, !minimalistic.isValid {
            return false
        }

        return metadata.count <= 32 && metadata.keys.allSatisfy { !$0.isEmpty }
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case bundleIdentifier
        case priority
        case accentColor
        case metadata
        case tab
        case minimalistic
        case durationHint
    }

    public init(
        id: String,
        bundleIdentifier: String,
        priority: AtollLiveActivityPriority = .normal,
        accentColor: AtollColorDescriptor = .accent,
        metadata: [String: String] = [:],
        tab: TabConfiguration? = nil,
        minimalistic: MinimalisticConfiguration? = nil,
        durationHint: TimeInterval? = nil
    ) {
        self.id = id
        self.bundleIdentifier = bundleIdentifier
        self.priority = priority
        self.accentColor = accentColor
        self.metadata = metadata
        self.tab = tab
        self.minimalistic = minimalistic
        self.durationHint = durationHint
    }

    /// Convenience initializer that uses `Bundle.main.bundleIdentifier`.
    public init(
        id: String,
        priority: AtollLiveActivityPriority = .normal,
        accentColor: AtollColorDescriptor = .accent,
        metadata: [String: String] = [:],
        tab: TabConfiguration? = nil,
        minimalistic: MinimalisticConfiguration? = nil,
        durationHint: TimeInterval? = nil
    ) {
        self.init(
            id: id,
            bundleIdentifier: Bundle.main.bundleIdentifier ?? "",
            priority: priority,
            accentColor: accentColor,
            metadata: metadata,
            tab: tab,
            minimalistic: minimalistic,
            durationHint: durationHint
        )
    }
}

// MARK: - Tab Configuration

public extension AtollNotchExperienceDescriptor {
    struct TabConfiguration: Codable, Sendable, Hashable {
        /// Visible title inside the tab button tooltip and diagnostics
        public let title: String

        /// Optional SF Symbol identifier for the tab button (defaults to puzzle icon)
        public let iconSymbolName: String?

        /// Optional badge rendered on top of the tab header
        public let badgeIcon: AtollIconDescriptor?

        /// Preferred height in points (clamped by Atoll)
        public let preferredHeight: CGFloat?

        /// Optional appearance overrides (tint, border, highlights)
        public let appearance: AtollWidgetAppearanceOptions?

        /// Ordered content sections
        public let sections: [AtollNotchContentSection]

        /// Optional sandboxed web content that supports user interaction
        public let webContent: AtollWidgetWebContentDescriptor?

        /// Whether the embedded web view should allow keyboard/mouse input
        public let allowWebInteraction: Bool

        /// Optional footnote text displayed below the content stack
        public let footnote: String?

        public init(
            title: String,
            iconSymbolName: String? = nil,
            badgeIcon: AtollIconDescriptor? = nil,
            preferredHeight: CGFloat? = nil,
            appearance: AtollWidgetAppearanceOptions? = nil,
            sections: [AtollNotchContentSection] = [],
            webContent: AtollWidgetWebContentDescriptor? = nil,
            allowWebInteraction: Bool = false,
            footnote: String? = nil
        ) {
            self.title = title
            self.iconSymbolName = iconSymbolName
            self.badgeIcon = badgeIcon
            self.preferredHeight = preferredHeight
            self.appearance = appearance
            self.sections = sections
            self.webContent = webContent
            self.allowWebInteraction = allowWebInteraction
            self.footnote = footnote
        }

        var isValid: Bool {
            guard !title.isEmpty,
                  sections.count <= 6,
                  sections.allSatisfy({ $0.isValid }) else {
                return false
            }

            if let preferredHeight {
                if preferredHeight < 160 || preferredHeight > 420 {
                    return false
                }
            }

            if let footnote, footnote.count > 140 {
                return false
            }

            if let webContent, !webContent.isValid {
                return false
            }

            if let badgeIcon, !badgeIcon.isValid {
                return false
            }

            return appearance?.isValid ?? true
        }
    }
}

// MARK: - Minimalistic Configuration

public extension AtollNotchExperienceDescriptor {
    struct MinimalisticConfiguration: Codable, Sendable, Hashable {
        /// Primary headline rendered where the music title normally appears
        public let headline: String?

        /// Secondary line rendered under the headline
        public let subtitle: String?

        /// Additional content sections stacked below the compact controls
        public let sections: [AtollNotchContentSection]

        /// Optional interactive web payload (height automatically constrained)
        public let webContent: AtollWidgetWebContentDescriptor?

        /// Layout hint that helps the host pick spacing presets
        public let layout: MinimalisticLayout

        /// When true, Atoll will suppress the built-in music controls entirely
        public let hidesMusicControls: Bool

        public init(
            headline: String? = nil,
            subtitle: String? = nil,
            sections: [AtollNotchContentSection] = [],
            webContent: AtollWidgetWebContentDescriptor? = nil,
            layout: MinimalisticLayout = .stack,
            hidesMusicControls: Bool = true
        ) {
            self.headline = headline
            self.subtitle = subtitle
            self.sections = sections
            self.webContent = webContent
            self.layout = layout
            self.hidesMusicControls = hidesMusicControls
        }

        var isValid: Bool {
            let headlineLength = headline?.count ?? 0
            let subtitleLength = subtitle?.count ?? 0
            guard headlineLength <= 80,
                  subtitleLength <= 120,
                  sections.count <= 3,
                  sections.allSatisfy({ $0.isValid }) else {
                return false
            }

            if let webContent, !webContent.isValid {
                return false
            }

            return true
        }
    }

    enum MinimalisticLayout: String, Codable, Sendable, Hashable {
        case stack
        case metrics
        case custom
    }
}

// MARK: - Content Sections

public struct AtollNotchContentSection: Codable, Sendable, Hashable {
    public enum Layout: String, Codable, Sendable, Hashable {
        /// Vertical stack that stretches to the full width
        case stack
        /// Two-column grid that balances elements evenly
        case columns
        /// Compact metric row (value + label pairs)
        case metrics
    }

    /// Optional identifier for diffing/debugging
    public let id: String?

    /// Optional title rendered above the section
    public let title: String?

    /// Optional subtitle rendered below the title using secondary styling
    public let subtitle: String?

    /// Layout hint for the host renderer
    public let layout: Layout

    /// Ordered content elements. Supports the same payloads as lock screen widgets.
    public let elements: [AtollWidgetContentElement]

    public init(
        id: String? = nil,
        title: String? = nil,
        subtitle: String? = nil,
        layout: Layout = .stack,
        elements: [AtollWidgetContentElement]
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.layout = layout
        self.elements = elements
    }

    var isValid: Bool {
        guard !elements.isEmpty,
              elements.count <= 6,
              elements.allSatisfy({ $0.isValid }) else {
            return false
        }
        if let title, title.count > 80 { return false }
        if let subtitle, subtitle.count > 160 { return false }
        return true
    }
}
