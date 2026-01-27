//
//  VlessURLParser.swift
//  PeekabooClient
//
//  Shared - Utility
//

import Foundation

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
    }}

struct VlessURLParser {
    
    static func parse(_ urlString: String) throws -> VPNConfiguration {
        //
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
        //
        guard let queryItems = url.queryItems, !queryItems.isEmpty else {
            throw VlessParserError.missingQueryParameters
        }
        var params: [String: String] = [:]
        for item in queryItems {
            if let value = item.value {
                params[item.name] = value
            }
        }
        guard let encryption = params["encryption"] else {
            throw VlessParserError.invalidRealityParameters
        }
        guard let publicKey = params["pbk"] else {
            throw VlessParserError.invalidRealityParameters
        }
        guard let fingerPrint = params["fp"] else {
            throw VlessParserError.invalidRealityParameters
        }
        guard let serverName = params["sni"] else {
            throw VlessParserError.invalidRealityParameters
        }
        guard let shortId = params["sid"] else {
            throw VlessParserError.invalidRealityParameters
        }
        guard let spiderX = params["spx"] else {
            throw VlessParserError.invalidRealityParameters
        }
        guard let mldsa65Verify = params["pqv"] else {
            throw VlessParserError.invalidRealityParameters
        }
        let name = url.fragment ?? "CONFIG"
        //
        let realitySettings = VPNConfiguration.RealitySettings(publicKey: publicKey, shortId: shortId, serverName: serverName, fingerprint: fingerPrint, mldsa65Verify: mldsa65Verify, spiderX: spiderX)
        
        let configuration = VPNConfiguration(id: UUID().uuidString, name: name, serverAddress: server, serverPort: port, userId: userID, encryption: encryption, protocol: .vless(reality: realitySettings))
        
        guard configuration.isValid else {
            throw VlessParserError.invalidRealityParameters
        }
        
        return configuration
        
    }
}
