//
//  AtollExtensionKitError.swift
//  AtollExtensionKit
//
//  Error types for AtollExtensionKit.
//

import Foundation

/// Errors that can occur when using AtollExtensionKit.
public enum AtollExtensionKitError: LocalizedError, Sendable {
    /// Atoll is not installed on this system
    case atollNotInstalled
    
    /// Atoll version is incompatible with this SDK version
    case incompatibleVersion(required: String, found: String)
    
    /// App is not authorized to use Atoll
    case notAuthorized
    
    /// Invalid descriptor data
    case invalidDescriptor(reason: String)
    
    /// XPC connection failed
    case connectionFailed(underlying: Error?)
    
    /// XPC service is unavailable
    case serviceUnavailable
    
    /// Activity limit exceeded
    case limitExceeded(limit: Int)
    
    /// Unknown error
    case unknown(String)
    
    public var errorDescription: String? {
        switch self {
        case .atollNotInstalled:
            return "Atoll is not installed. Please install Atoll to use live activities."
        case .incompatibleVersion(let required, let found):
            return "Atoll version \(found) is incompatible. Required version: \(required) or later."
        case .notAuthorized:
            return "App is not authorized to display live activities. User must grant permission in Atoll Settings."
        case .invalidDescriptor(let reason):
            return "Invalid descriptor: \(reason)"
        case .connectionFailed(let error):
            if let error {
                return "Failed to connect to Atoll: \(error.localizedDescription)"
            }
            return "Failed to connect to Atoll."
        case .serviceUnavailable:
            return "Atoll service is temporarily unavailable. Please try again later."
        case .limitExceeded(let limit):
            return "Activity limit exceeded. Maximum \(limit) concurrent activities allowed."
        case .unknown(let message):
            return "Unknown error: \(message)"
        }
    }
}
