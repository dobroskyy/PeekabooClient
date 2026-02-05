//
//  XrayConfigMapper.swift
//  PeekabooClient
//
//  Shared - Utility
//

import LibXray
import Foundation

final class XrayConfigMapper {
    
    enum XrayMapperError: Error {
        case invalidURL
        case emptyResponse
        case invalidJSONStructure
        case invalidResultJSON
    }
    
    static func mapToXrayJSON(configuration: VPNConfiguration) throws -> String {
        guard case .vless(let reality) = configuration.protocol else {
            throw XrayMapperError.invalidJSONStructure
        }
        
        let vlessOutbound: [String: Any] = [
            "protocol": "vless",
            "tag": "proxy",
            "settings": [
                "vnext": [[
                    "address": configuration.serverAddress,
                    "port": configuration.serverPort,
                    "users": [[
                        "id": configuration.userId,
                        "encryption": configuration.encryption,
                        "flow": ""
                    ]]
                ]]
            ],
            "streamSettings": [
                "network": "tcp",
                "security": "reality",
                "realitySettings": [
                    "show": false,
                    "fingerprint": reality.fingerprint,
                    "serverName": reality.serverName,
                    "publicKey": reality.publicKey,
                    "shortId": reality.shortId,
                    "spiderX": reality.spiderX
                ]
            ]
        ]
        
        let config: [String: Any] = [
            "log": [
                "loglevel": "warning"
            ],
            "inbounds": buildInbounds(),
            "outbounds": [
                vlessOutbound,
                [
                    "protocol": "freedom",
                    "tag": "direct"
                ],
                [
                    "protocol": "blackhole",
                    "tag": "block"
                ]
            ],
            "routing": buildRouting(),
            "dns": buildDNS(),
            "policy": buildPolicy(),
            "stats": [:]
        ]
        
        let finalData = try JSONSerialization.data(withJSONObject: config, options: .prettyPrinted)
        guard let finalJSON = String(data: finalData, encoding: .utf8) else {
            throw XrayMapperError.invalidJSONStructure
        }
        
        return finalJSON
    }
    
    private static func buildInbounds() -> [[String: Any]] {
        let socksInbound: [String: Any] = [
            "listen": "127.0.0.1",
            "port": AppConstants.Network.socksPort,
            "protocol": "socks",
            "sniffing": [
                "enabled": true,
                "destOverride": ["http", "tls", "quic"],
                "routeOnly": false
            ],
            "settings": [
                "udp": true
            ],
            "tag": "socks"
        ]
        
        return [socksInbound]
    }
    
    private static func buildRouting() -> [String: Any] {
        [
            "domainStrategy": "AsIs",
            "rules": [
                [
                    "type": "field",
                    "port": "0-65535",
                    "outboundTag": "proxy"
                ]
            ]
        ]
    }
    
    private static func buildDNS() -> [String: Any] {
        [
            "servers": [
                "https://dns.google/dns-query",
                "1.1.1.1"
            ]
        ]
    }
    
    private static func buildPolicy() -> [String: Any] {
        [
            "system": [
                "statsInboundDownlink": true,
                "statsInboundUplink": true,
                "statsOutboundDownlink": true,
                "statsOutboundUplink": true
            ]
        ]
    }
    
}
