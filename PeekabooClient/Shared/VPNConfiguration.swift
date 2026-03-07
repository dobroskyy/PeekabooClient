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
    let flow: String
    let transport: TransportType
    let `protocol`: ProtocolType

    let transportPath: String?
    let transportHost: String?
    let serviceName: String?

    init(id: String, name: String, originalURL: String, serverAddress: String, serverPort: Int, userId: String, encryption: String, flow: String, transport: TransportType, protocol: ProtocolType, transportPath: String? = nil, transportHost: String? = nil, serviceName: String? = nil) {
        self.id = id
        self.name = name
        self.originalURL = originalURL
        self.serverAddress = serverAddress
        self.serverPort = serverPort
        self.userId = userId
        self.encryption = encryption
        self.flow = flow
        self.transport = transport
        self.protocol = `protocol`
        self.transportPath = transportPath
        self.transportHost = transportHost
        self.serviceName = serviceName
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        originalURL = try container.decode(String.self, forKey: .originalURL)
        serverAddress = try container.decode(String.self, forKey: .serverAddress)
        serverPort = try container.decode(Int.self, forKey: .serverPort)
        userId = try container.decode(String.self, forKey: .userId)
        encryption = try container.decode(String.self, forKey: .encryption)
        flow = try container.decodeIfPresent(String.self, forKey: .flow) ?? ""
        transport = try container.decode(TransportType.self, forKey: .transport)
        `protocol` = try container.decode(ProtocolType.self, forKey: .protocol)
        transportPath = try container.decodeIfPresent(String.self, forKey: .transportPath)
        transportHost = try container.decodeIfPresent(String.self, forKey: .transportHost)
        serviceName = try container.decodeIfPresent(String.self, forKey: .serviceName)
    }

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


