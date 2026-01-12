//
//  AtollXPCConnectionManager.swift
//  AtollExtensionKit
//
//  Manages XPC connection to Atoll service.
//

import Foundation

final class AtollXPCConnectionManager: NSObject, @unchecked Sendable {
    private static let serviceName = "com.ebullioscopic.Atoll.xpc"
    private var connection: NSXPCConnection?
    private let queue = DispatchQueue(label: "com.atoll.xpc.connection")
    
    var onAuthorizationChange: ((Bool) -> Void)?
    var onActivityDismiss: ((String) -> Void)?
    var onWidgetDismiss: ((String) -> Void)?
    
    private var bundleIdentifier: String {
        Bundle.main.bundleIdentifier ?? "unknown"
    }
    
    var isAtollInstalled: Bool {
        // Check if Atoll app exists in Applications
        let appPath = "/Applications/Atoll.app"
        return FileManager.default.fileExists(atPath: appPath)
    }
    
    // MARK: - Connection Management
    
    private func getConnection() throws -> NSXPCConnection {
        if let existing = connection {
            return existing
        }
        
        guard isAtollInstalled else {
            throw AtollExtensionKitError.atollNotInstalled
        }
        
        let newConnection = NSXPCConnection(machServiceName: Self.serviceName, options: [])
        newConnection.remoteObjectInterface = NSXPCInterface(with: AtollXPCServiceProtocol.self)
        newConnection.exportedInterface = NSXPCInterface(with: AtollXPCClientProtocol.self)
        newConnection.exportedObject = self
        
        newConnection.invalidationHandler = { [weak self] in
            self?.connection = nil
        }
        
        newConnection.interruptionHandler = { [weak self] in
            self?.connection = nil
        }
        
        newConnection.resume()
        connection = newConnection
        return newConnection
    }
    
    private func getService() throws -> AtollXPCServiceProtocol {
        let connection = try getConnection()
        
        guard let service = connection.remoteObjectProxyWithErrorHandler({ error in
            print("XPC Error: \(error)")
        }) as? AtollXPCServiceProtocol else {
            throw AtollExtensionKitError.serviceUnavailable
        }
        
        return service
    }
    
    // MARK: - Service Methods
    
    func requestAuthorization() async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            do {
                let service = try getService()
                service.requestAuthorization(bundleIdentifier: bundleIdentifier) { authorized, error in
                    if let error {
                        continuation.resume(throwing: AtollExtensionKitError.connectionFailed(underlying: error))
                    } else {
                        continuation.resume(returning: authorized)
                    }
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    func checkAuthorization() async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            do {
                let service = try getService()
                service.checkAuthorization(bundleIdentifier: bundleIdentifier) { authorized in
                    continuation.resume(returning: authorized)
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    func getVersion() async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            do {
                let service = try getService()
                service.getVersion { version in
                    continuation.resume(returning: version)
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    func presentLiveActivity(_ descriptor: AtollLiveActivityDescriptor) async throws {
        let data = try JSONEncoder().encode(descriptor)
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            do {
                let service = try getService()
                service.presentLiveActivity(descriptorData: data) { success, error in
                    if success {
                        continuation.resume()
                    } else {
                        continuation.resume(throwing: error ?? AtollExtensionKitError.unknown("Failed to present activity"))
                    }
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    func updateLiveActivity(_ descriptor: AtollLiveActivityDescriptor) async throws {
        let data = try JSONEncoder().encode(descriptor)
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            do {
                let service = try getService()
                service.updateLiveActivity(descriptorData: data) { success, error in
                    if success {
                        continuation.resume()
                    } else {
                        continuation.resume(throwing: error ?? AtollExtensionKitError.unknown("Failed to update activity"))
                    }
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    func dismissLiveActivity(activityID: String) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            do {
                let service = try getService()
                service.dismissLiveActivity(activityID: activityID, bundleIdentifier: bundleIdentifier) { success, error in
                    if success {
                        continuation.resume()
                    } else {
                        continuation.resume(throwing: error ?? AtollExtensionKitError.unknown("Failed to dismiss activity"))
                    }
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    func presentLockScreenWidget(_ descriptor: AtollLockScreenWidgetDescriptor) async throws {
        let data = try JSONEncoder().encode(descriptor)
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            do {
                let service = try getService()
                service.presentLockScreenWidget(descriptorData: data) { success, error in
                    if success {
                        continuation.resume()
                    } else {
                        continuation.resume(throwing: error ?? AtollExtensionKitError.unknown("Failed to present widget"))
                    }
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    func updateLockScreenWidget(_ descriptor: AtollLockScreenWidgetDescriptor) async throws {
        let data = try JSONEncoder().encode(descriptor)
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            do {
                let service = try getService()
                service.updateLockScreenWidget(descriptorData: data) { success, error in
                    if success {
                        continuation.resume()
                    } else {
                        continuation.resume(throwing: error ?? AtollExtensionKitError.unknown("Failed to update widget"))
                    }
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    func dismissLockScreenWidget(widgetID: String) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            do {
                let service = try getService()
                service.dismissLockScreenWidget(widgetID: widgetID, bundleIdentifier: bundleIdentifier) { success, error in
                    if success {
                        continuation.resume()
                    } else {
                        continuation.resume(throwing: error ?? AtollExtensionKitError.unknown("Failed to dismiss widget"))
                    }
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    deinit {
        connection?.invalidate()
    }
}

// MARK: - Client Protocol Implementation

extension AtollXPCConnectionManager: AtollXPCClientProtocol {
    func authorizationDidChange(isAuthorized: Bool) {
        onAuthorizationChange?(isAuthorized)
    }
    
    func activityDidDismiss(activityID: String) {
        onActivityDismiss?(activityID)
    }
    
    func widgetDidDismiss(widgetID: String) {
        onWidgetDismiss?(widgetID)
    }
}
