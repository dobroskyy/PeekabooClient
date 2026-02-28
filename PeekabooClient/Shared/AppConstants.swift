//
//  AppConstants.swift
//  PeekabooClient
//
//  Shared - Utility
//

import Foundation
import LibXray

enum AppConstants {
    
    static let appGroupIdentifier = "group.dobrosky.PeekabooClient"
    static let providerBundleIdentifier = "dobrosky.PeekabooClient.PacketTunnelExtension"
    static let appName = "Peekaboo"
    
    static var xrayVersion: String {
        let base64String = LibXrayXrayVersion()

        guard let data = Data(base64Encoded: base64String),
              let jsonString = String(data: data, encoding: .utf8) else {
            return "Unknown"
        }

        guard let jsonData = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let version = json["data"] as? String else {
            return "Unknown"
        }

        return version
    }
    
    enum Network {
        static let socksPort = 10808
        static let tunnelMTU = 8500
    }
    
    enum Keys {
        static let reconnectCount = "reconnect_count"
        static let sessionIsActive = "session_is_active"
        static let limitReached = "limit_reached"
    }
}
