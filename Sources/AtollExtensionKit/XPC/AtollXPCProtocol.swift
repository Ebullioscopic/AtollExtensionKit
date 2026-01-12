//
//  AtollXPCProtocol.swift
//  AtollExtensionKit
//
//  XPC protocol for communication between Atoll and third-party apps.
//

import Foundation

/// Protocol defining the XPC interface for Atoll services.
@objc public protocol AtollXPCServiceProtocol {
    /// Request authorization for the calling app to display live activities.
    /// - Parameter bundleIdentifier: The app's bundle identifier
    /// - Parameter reply: Callback with authorization result
    func requestAuthorization(bundleIdentifier: String, reply: @escaping (Bool, Error?) -> Void)
    
    /// Check if the app is authorized.
    /// - Parameter bundleIdentifier: The app's bundle identifier
    /// - Parameter reply: Callback with authorization status
    func checkAuthorization(bundleIdentifier: String, reply: @escaping (Bool) -> Void)
    
    /// Present a live activity.
    /// - Parameter descriptor: The activity descriptor (as Data)
    /// - Parameter reply: Callback with success/failure
    func presentLiveActivity(descriptorData: Data, reply: @escaping (Bool, Error?) -> Void)
    
    /// Update an existing live activity.
    /// - Parameter descriptorData: Updated descriptor (as Data)
    /// - Parameter reply: Callback with success/failure
    func updateLiveActivity(descriptorData: Data, reply: @escaping (Bool, Error?) -> Void)
    
    /// Dismiss a live activity.
    /// - Parameter activityID: Activity identifier
    /// - Parameter bundleIdentifier: App's bundle identifier
    /// - Parameter reply: Callback with success/failure
    func dismissLiveActivity(activityID: String, bundleIdentifier: String, reply: @escaping (Bool, Error?) -> Void)
    
    /// Present a lock screen widget.
    /// - Parameter descriptorData: Widget descriptor (as Data)
    /// - Parameter reply: Callback with success/failure
    func presentLockScreenWidget(descriptorData: Data, reply: @escaping (Bool, Error?) -> Void)
    
    /// Update an existing lock screen widget.
    /// - Parameter descriptorData: Updated descriptor (as Data)
    /// - Parameter reply: Callback with success/failure
    func updateLockScreenWidget(descriptorData: Data, reply: @escaping (Bool, Error?) -> Void)
    
    /// Dismiss a lock screen widget.
    /// - Parameter widgetID: Widget identifier
    /// - Parameter bundleIdentifier: App's bundle identifier
    /// - Parameter reply: Callback with success/failure
    func dismissLockScreenWidget(widgetID: String, bundleIdentifier: String, reply: @escaping (Bool, Error?) -> Void)
    
    /// Get Atoll version information.
    /// - Parameter reply: Callback with version string
    func getVersion(reply: @escaping (String) -> Void)
}

/// Client-facing protocol (for notifications from Atoll to apps).
@objc public protocol AtollXPCClientProtocol {
    /// Notifies client that authorization status changed.
    /// - Parameter isAuthorized: New authorization status
    func authorizationDidChange(isAuthorized: Bool)
    
    /// Notifies client that an activity was dismissed (e.g., by user interaction).
    /// - Parameter activityID: The dismissed activity ID
    func activityDidDismiss(activityID: String)
    
    /// Notifies client that a widget was dismissed.
    /// - Parameter widgetID: The dismissed widget ID
    func widgetDidDismiss(widgetID: String)
}
