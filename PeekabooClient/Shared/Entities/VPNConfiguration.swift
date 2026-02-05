//
//  VPNConfiguration.swift
//  PeekabooClient
//
//  Shared - Entity
//

import Foundation

struct VPNConfiguration: Codable {
    
    let id: String
    let name: String
    let originalURL: String
    
    let serverAddress: String
    let serverPort: Int
    let userId: String
    let encryption: String
    let `protocol`: ProtocolType
    
    enum ProtocolType: Codable {
        case vless(reality: RealitySettings)
    }
    
    
    
    struct RealitySettings: Codable {
        let publicKey: String       // pbk
        let shortId: String         // sid
        let serverName: String      // sni
        let fingerprint: String     // fp
        let mldsa65Verify: String   // pqv (post-quantum)
        let spiderX: String         // spx
    }
}

extension VPNConfiguration {
    var isValid: Bool {
        !serverAddress.isEmpty &&
        serverPort > 0 && serverPort <= 65535 &&
        !userId.isEmpty &&
        !encryption.isEmpty
    }
}


