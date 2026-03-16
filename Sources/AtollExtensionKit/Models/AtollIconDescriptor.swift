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

    // MARK: - Custom Codable (supports default values for omitted fields)

    private enum CodingKeys: String, CodingKey {
        case symbol, image, appIcon, lottie, none
    }

    private enum SymbolCodingKeys: String, CodingKey {
        case name, size, weight
    }

    private enum ImageCodingKeys: String, CodingKey {
        case data, size, cornerRadius
    }

    private enum AppIconCodingKeys: String, CodingKey {
        case bundleIdentifier, size, cornerRadius
    }

    private enum LottieCodingKeys: String, CodingKey {
        case animationData, size
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if container.contains(.symbol) {
            let nested = try container.nestedContainer(keyedBy: SymbolCodingKeys.self, forKey: .symbol)
            let name = try nested.decode(String.self, forKey: .name)
            let size = try nested.decodeIfPresent(CGFloat.self, forKey: .size) ?? 16
            let weight = try nested.decodeIfPresent(AtollFontWeight.self, forKey: .weight) ?? .regular
            self = .symbol(name: name, size: size, weight: weight)
        } else if container.contains(.image) {
            let nested = try container.nestedContainer(keyedBy: ImageCodingKeys.self, forKey: .image)
            let data = try nested.decode(Data.self, forKey: .data)
            let size = try nested.decodeIfPresent(CGSize.self, forKey: .size) ?? CGSize(width: 20, height: 20)
            let cornerRadius = try nested.decodeIfPresent(CGFloat.self, forKey: .cornerRadius) ?? 0
            self = .image(data: data, size: size, cornerRadius: cornerRadius)
        } else if container.contains(.appIcon) {
            let nested = try container.nestedContainer(keyedBy: AppIconCodingKeys.self, forKey: .appIcon)
            let bundleIdentifier = try nested.decode(String.self, forKey: .bundleIdentifier)
            let size = try nested.decodeIfPresent(CGSize.self, forKey: .size) ?? CGSize(width: 20, height: 20)
            let cornerRadius = try nested.decodeIfPresent(CGFloat.self, forKey: .cornerRadius) ?? 4
            self = .appIcon(bundleIdentifier: bundleIdentifier, size: size, cornerRadius: cornerRadius)
        } else if container.contains(.lottie) {
            let nested = try container.nestedContainer(keyedBy: LottieCodingKeys.self, forKey: .lottie)
            let animationData = try nested.decode(Data.self, forKey: .animationData)
            let size = try nested.decodeIfPresent(CGSize.self, forKey: .size) ?? CGSize(width: 24, height: 24)
            self = .lottie(animationData: animationData, size: size)
        } else if container.contains(.none) {
            self = .none
        } else {
            throw DecodingError.dataCorrupted(.init(codingPath: container.codingPath, debugDescription: "Unknown AtollIconDescriptor case"))
        }
    }
}
