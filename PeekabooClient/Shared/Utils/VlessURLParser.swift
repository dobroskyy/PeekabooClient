//
//  VlessURLParser.swift
//  PeekabooClient
//
//  Shared - Utility
//

import Foundation
import CryptoKit

enum VlessParserError: LocalizedError {
    
    case invalidURL
    case invalidScheme
    case missingUserId
    case missingServer
    case invalidPort
    case missingQueryParameters
    case invalidRealityParameters
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Неверный формат URL"
        case .invalidScheme:
            return "URL должен начинаться с vless://"
        case .missingUserId:
            return "Отсутствует User ID в URL"
        case .missingServer:
            return "Отсутствует адрес сервера"
        case .invalidPort:
            return "Неверный или отсутствующий порт"
        case .missingQueryParameters:
            return "Отсутствуют параметры конфигурации"
        case .invalidRealityParameters:
            return "Неверные параметры Reality протокола"
        }
    }
}

struct VlessURLParser {
    
    private static func generateStableID(from urlString: String) -> String {
        let hash = SHA256.hash(data: Data(urlString.utf8))
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    static func parse(_ urlString: String) throws -> VPNConfiguration {
        guard let url = URLComponents(string: urlString) else {
            throw VlessParserError.invalidURL
        }
        guard url.scheme == "vless" else {
            throw VlessParserError.invalidScheme
        }
        guard let userID = url.user, !userID.isEmpty else {
            throw VlessParserError.missingUserId
        }
        guard let server = url.host, !server.isEmpty else {
            throw VlessParserError.missingServer
        }
        guard let port = url.port else {
            throw VlessParserError.invalidPort
        }

        guard let queryItems = url.queryItems, !queryItems.isEmpty else {
            throw VlessParserError.missingQueryParameters
        }
        var params: [String: String] = [:]
        for item in queryItems {
            if let value = item.value {
                params[item.name] = value
            }
        }

        guard let publicKey = params["pbk"], !publicKey.isEmpty else {
            throw VlessParserError.invalidRealityParameters
        }
        guard let serverName = params["sni"], !serverName.isEmpty else {
            throw VlessParserError.invalidRealityParameters
        }
        guard let fingerprint = params["fp"], !fingerprint.isEmpty else {
            throw VlessParserError.invalidRealityParameters
        }

        let encryption = params["encryption"] ?? "none"
        let shortId = params["sid"] ?? ""
        let spiderX = params["spx"]
        let mldsa65Verify = params["pqv"]
        let transportTypeString = params["type"] ?? "tcp"

        let name = url.fragment ?? "CONFIG"

        let realitySettings = VPNConfiguration.RealitySettings(publicKey: publicKey, serverName: serverName, fingerprint: fingerprint, shortId: shortId, spiderX: spiderX, mldsa65Verify: mldsa65Verify)
        let transport = VPNConfiguration.TransportType(rawValue: transportTypeString) ?? .tcp

        let configuration = VPNConfiguration(id: generateStableID(from: urlString), name: name, originalURL: urlString, serverAddress: server, serverPort: port, userId: userID, encryption: encryption, transport: transport, protocol: .vless(reality: realitySettings))

        guard configuration.isValid else {
            throw VlessParserError.invalidRealityParameters
        }

        return configuration

    }
}
