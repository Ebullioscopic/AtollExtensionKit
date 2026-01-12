//
//  AtollIconDescriptor.swift
//  AtollExtensionKit
//
//  Icon configurations for live activities and widgets.
//

import Foundation
import CoreGraphics

/// Describes an icon that can be displayed in live activities or widgets.
public enum AtollIconDescriptor: Codable, Sendable, Hashable {
    /// SF Symbol by name
    case symbol(name: String, size: CGFloat = 16, weight: AtollFontWeight = .regular)
    
    /// PNG/JPEG image data
    case image(data: Data, size: CGSize = CGSize(width: 20, height: 20), cornerRadius: CGFloat = 0)
    
    /// App icon from bundle identifier
    case appIcon(bundleIdentifier: String, size: CGSize = CGSize(width: 20, height: 20), cornerRadius: CGFloat = 4)
    
    /// Lottie animation
    case lottie(animationData: Data, size: CGSize = CGSize(width: 24, height: 24))
    
    /// No icon
    case none
    
    /// Validation: ensures icon data doesn't exceed size limits
    public var isValid: Bool {
        switch self {
        case .image(let data, _, _), .lottie(let data, _):
            // Limit icon data to 5MB
            return data.count <= 5_242_880
        default:
            return true
        }
    }
}
