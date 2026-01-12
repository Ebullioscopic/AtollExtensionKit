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
    case ring(diameter: CGFloat = 24, strokeWidth: CGFloat = 3)
    
    /// Horizontal progress bar
    case bar(width: CGFloat? = nil, height: CGFloat = 4, cornerRadius: CGFloat = 2)
    
    /// Percentage text display
    case percentage(font: AtollFontDescriptor = .system(size: 13, weight: .semibold))
    
    /// Countdown timer (mm:ss or HH:mm:ss format)
    case countdown(font: AtollFontDescriptor = .monospacedDigit(size: 13, weight: .semibold))
    
    /// Custom Lottie animation (must provide animation data)
    case lottie(animationData: Data, size: CGSize = CGSize(width: 30, height: 30))
    
    /// No progress indicator
    case none
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
