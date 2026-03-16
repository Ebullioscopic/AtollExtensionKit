//
//  AtollProgressIndicator.swift
//  AtollExtensionKit
//
//  Progress indicator configurations for live activities.
//

import Foundation
import CoreGraphics

/// Visual representation of progress within a live activity.
public enum AtollProgressIndicator: Codable, Sendable, Hashable {
    /// Circular ring progress (like timer)
    case ring(diameter: CGFloat = 24, strokeWidth: CGFloat = 3, color: AtollColorDescriptor? = nil)
    
    /// Horizontal progress bar
    case bar(width: CGFloat? = nil, height: CGFloat = 4, cornerRadius: CGFloat = 2, color: AtollColorDescriptor? = nil)
    
    /// Percentage text display
    case percentage(font: AtollFontDescriptor = .system(size: 13, weight: .semibold), color: AtollColorDescriptor? = nil)
    
    /// Countdown timer (mm:ss or HH:mm:ss format)
    case countdown(font: AtollFontDescriptor = .monospacedDigit(size: 13, weight: .semibold), color: AtollColorDescriptor? = nil)
    
    /// Custom Lottie animation (must provide animation data)
    case lottie(animationData: Data, size: CGSize = CGSize(width: 30, height: 30))
    
    /// No progress indicator
    case none

    // MARK: - Custom Codable (supports default values for omitted fields)

    private enum CodingKeys: String, CodingKey {
        case ring, bar, percentage, countdown, lottie, none
    }

    private enum RingCodingKeys: String, CodingKey {
        case diameter, strokeWidth, color
    }

    private enum BarCodingKeys: String, CodingKey {
        case width, height, cornerRadius, color
    }

    private enum PercentageCodingKeys: String, CodingKey {
        case font, color
    }

    private enum CountdownCodingKeys: String, CodingKey {
        case font, color
    }

    private enum LottieCodingKeys: String, CodingKey {
        case animationData, size
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if container.contains(.ring) {
            let nested = try container.nestedContainer(keyedBy: RingCodingKeys.self, forKey: .ring)
            let diameter = try nested.decodeIfPresent(CGFloat.self, forKey: .diameter) ?? 24
            let strokeWidth = try nested.decodeIfPresent(CGFloat.self, forKey: .strokeWidth) ?? 3
            let color = try nested.decodeIfPresent(AtollColorDescriptor.self, forKey: .color)
            self = .ring(diameter: diameter, strokeWidth: strokeWidth, color: color)
        } else if container.contains(.bar) {
            let nested = try container.nestedContainer(keyedBy: BarCodingKeys.self, forKey: .bar)
            let width = try nested.decodeIfPresent(CGFloat.self, forKey: .width)
            let height = try nested.decodeIfPresent(CGFloat.self, forKey: .height) ?? 4
            let cornerRadius = try nested.decodeIfPresent(CGFloat.self, forKey: .cornerRadius) ?? 2
            let color = try nested.decodeIfPresent(AtollColorDescriptor.self, forKey: .color)
            self = .bar(width: width, height: height, cornerRadius: cornerRadius, color: color)
        } else if container.contains(.percentage) {
            let nested = try container.nestedContainer(keyedBy: PercentageCodingKeys.self, forKey: .percentage)
            let font = try nested.decodeIfPresent(AtollFontDescriptor.self, forKey: .font) ?? .system(size: 13, weight: .semibold)
            let color = try nested.decodeIfPresent(AtollColorDescriptor.self, forKey: .color)
            self = .percentage(font: font, color: color)
        } else if container.contains(.countdown) {
            let nested = try container.nestedContainer(keyedBy: CountdownCodingKeys.self, forKey: .countdown)
            let font = try nested.decodeIfPresent(AtollFontDescriptor.self, forKey: .font) ?? .monospacedDigit(size: 13, weight: .semibold)
            let color = try nested.decodeIfPresent(AtollColorDescriptor.self, forKey: .color)
            self = .countdown(font: font, color: color)
        } else if container.contains(.lottie) {
            let nested = try container.nestedContainer(keyedBy: LottieCodingKeys.self, forKey: .lottie)
            let animationData = try nested.decode(Data.self, forKey: .animationData)
            let size = try nested.decodeIfPresent(CGSize.self, forKey: .size) ?? CGSize(width: 30, height: 30)
            self = .lottie(animationData: animationData, size: size)
        } else if container.contains(.none) {
            self = .none
        } else {
            throw DecodingError.dataCorrupted(.init(codingPath: container.codingPath, debugDescription: "Unknown AtollProgressIndicator case"))
        }
    }
}

/// Font descriptor for text-based elements.
public struct AtollFontDescriptor: Codable, Sendable, Hashable {
    public let size: CGFloat
    public let weight: AtollFontWeight
    public let design: AtollFontDesign
    public let isMonospacedDigit: Bool
    
    public init(size: CGFloat, weight: AtollFontWeight = .regular, design: AtollFontDesign = .default, isMonospacedDigit: Bool = false) {
        self.size = size
        self.weight = weight
        self.design = design
        self.isMonospacedDigit = isMonospacedDigit
    }
    
    public static func system(size: CGFloat, weight: AtollFontWeight = .regular, design: AtollFontDesign = .default) -> AtollFontDescriptor {
        AtollFontDescriptor(size: size, weight: weight, design: design, isMonospacedDigit: false)
    }
    
    public static func monospacedDigit(size: CGFloat, weight: AtollFontWeight = .regular) -> AtollFontDescriptor {
        AtollFontDescriptor(size: size, weight: weight, design: .default, isMonospacedDigit: true)
    }
}

public enum AtollFontWeight: String, Codable, Sendable, Hashable {
    case ultraLight, thin, light, regular, medium, semibold, bold, heavy, black
}

public enum AtollFontDesign: String, Codable, Sendable, Hashable {
    case `default`, serif, rounded, monospaced
}
