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
    let transport: TransportType
    let `protocol`: ProtocolType

    enum TransportType: String, Codable {
        case tcp
        case ws
        case grpc
        case h2
        case xhttp
        case httpupgrade
    }

    enum ProtocolType: Codable {
        case vless(reality: RealitySettings)
    }



    struct RealitySettings: Codable {
        let publicKey: String       // pbk
        let serverName: String      // sni
        let fingerprint: String     // fp

        let shortId: String         // sid
        let spiderX: String?        // spx
        let mldsa65Verify: String?  // pqv
    }
}

extension VPNConfiguration {
    var isValid: Bool {
        !serverAddress.isEmpty &&
        serverPort > 0 && serverPort <= 65535 &&
        !userId.isEmpty
    }
}


