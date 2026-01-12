//
//  AtollColorDescriptor.swift
//  AtollExtensionKit
//
//  Color configurations compatible with Codable and XPC.
//

import Foundation

/// Platform-independent color description.
public struct AtollColorDescriptor: Codable, Sendable, Hashable {
    public let red: Double
    public let green: Double
    public let blue: Double
    public let alpha: Double
    
    public init(red: Double, green: Double, blue: Double, alpha: Double = 1.0) {
        self.red = min(max(red, 0), 1)
        self.green = min(max(green, 0), 1)
        self.blue = min(max(blue, 0), 1)
        self.alpha = min(max(alpha, 0), 1)
    }
    
    // MARK: - Predefined Colors
    
    public static let white = AtollColorDescriptor(red: 1, green: 1, blue: 1)
    public static let black = AtollColorDescriptor(red: 0, green: 0, blue: 0)
    public static let red = AtollColorDescriptor(red: 1, green: 0, blue: 0)
    public static let green = AtollColorDescriptor(red: 0, green: 1, blue: 0)
    public static let blue = AtollColorDescriptor(red: 0, green: 0, blue: 1)
    public static let yellow = AtollColorDescriptor(red: 1, green: 1, blue: 0)
    public static let orange = AtollColorDescriptor(red: 1, green: 0.6, blue: 0)
    public static let purple = AtollColorDescriptor(red: 0.6, green: 0, blue: 1)
    public static let pink = AtollColorDescriptor(red: 1, green: 0, blue: 0.6)
    public static let gray = AtollColorDescriptor(red: 0.5, green: 0.5, blue: 0.5)
    
    /// Use system accent color
    public static let accent = AtollColorDescriptor(red: -1, green: -1, blue: -1)
    
    public var isAccent: Bool {
        red < 0 && green < 0 && blue < 0
    }
}
