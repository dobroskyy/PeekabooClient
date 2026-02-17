//
//  AppConstants.swift
//  PeekabooClient
//
//  Shared - Utility
//

import Foundation

enum AppConstants {
    
    static let appGroupIdentifier = "group.dobrosky.PeekabooClient"
    static let providerBundleIdentifier = "dobrosky.PeekabooClient.PacketTunnelExtension"
    
    enum Network {
        static let socksPort = 10808
        static let tunnelMTU = 8500
    }
    
    enum StorageKeys {
        static let statisticsFile = "stats.json"
    }
    
    enum Timeouts {
        static let statisticsUpdateInterval: TimeInterval = 1.0
        static let statisticsFreshnessThreshold: TimeInterval = 5.0
    }
}
