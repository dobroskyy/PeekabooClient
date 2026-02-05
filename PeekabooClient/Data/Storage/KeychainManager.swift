//
//  KeychainManager.swift
//  PeekabooClient
//
//  Data Layer - Keychain Storage
//

import Foundation
import Security

final class KeychainManager {
    
    enum KeychainError: Error {
        case itemNotFound
        case unexpectedData
        case unhandledError(status: OSStatus)
    }
    
    static let shared = KeychainManager()
    private let accessGroup: String?
    
    private init() {
        #if DEBUG
        self.accessGroup = nil
        #else
        self.accessGroup = "dobrosky.PeekabooClient.shared"
        #endif
    }
    
    func save(_ data: Data, forKey key: String) throws {
        
        try? delete(key: key)
        
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock]
        
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw KeychainError.unhandledError(status: status)
        }
    }
    
    func load(key: String) throws -> Data {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                throw KeychainError.itemNotFound
            }
            throw KeychainError.unhandledError(status: status)
        }
        
        guard let data = result as? Data else {
            throw KeychainError.unexpectedData
        }
        
        return data
    }
    
    func delete(key: String) throws {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status ==  errSecItemNotFound else {
            throw KeychainError.unhandledError(status: status)
        }
    }
    
    func exists(key: String) -> Bool {
        do {
            _ = try load(key: key)
            return true
        } catch {
            return false
        }
    }
    
}

