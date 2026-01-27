//
//  NetworkStatistics.swift
//  PeekabooClient
//
//  Created by Максим on 27.01.2026.
//

import Foundation

struct NetworkStatistics: Codable {
    
    let uploadBytes: UInt64
    let downloadBytes: UInt64
    let timestamp: Date
    
    private func formatBytes(_ bytes: UInt64) -> String {
        switch bytes {
        case 0..<1024:
            return "\(bytes) B"
        case 1024..<1024 * 1024:
            let kb = Double(bytes) / 1024
            return String(format: "%.1f KB", kb)
        case 1024 * 1024..<1024 * 1024 * 1024:
            let mb = Double(bytes) / (1024 * 1024)
            return String(format: "%.1f MB", mb)
        case 1024 * 1024 * 1024..<1024 * 1024 * 1024 * 1024:
            let gb = Double(bytes) / (1024 * 1024 * 1024)
            return String(format: "%.1f GB", gb)
        default:
            let tb = Double(bytes) / (1024 * 1024 * 1024 * 1024)
            return String(format: "%.1f TB", tb)
        }
    }
    
    var displayText: String {
        return "↑ \(formatBytes(uploadBytes))  ↓ \(formatBytes(downloadBytes))"
    }
    
    static let zero = NetworkStatistics(uploadBytes: 0, downloadBytes: 0, timestamp: Date())
    
}
