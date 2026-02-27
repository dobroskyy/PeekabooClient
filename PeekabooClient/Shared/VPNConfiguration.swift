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
        let publicKey: String
        let serverName: String
        let fingerprint: String

        let shortId: String
        let spiderX: String?
        let mldsa65Verify: String?
    }
}

extension VPNConfiguration {
    var isValid: Bool {
        !serverAddress.isEmpty &&
        serverPort > 0 && serverPort <= 65535 &&
        !userId.isEmpty
    }
    
    var protocolDisplayName: String {
        switch `protocol` {
        case .vless:
            return "VLESS"
        }
    }
    
    var transportDisplayName: String {
        switch transport {
        case .tcp:
            return "TCP"
        case .ws:
            return "WebSocket"
        case .grpc:
            return "gRPC"
        case .h2:
            return "HTTP/2"
        case .xhttp:
            return "XHTTP"
        case .httpupgrade:
            return "HTTPUpgrade"
        }
    }
    
    var protocolDescription: String {
        "\(protocolDisplayName) / \(transportDisplayName)"
    }
}


