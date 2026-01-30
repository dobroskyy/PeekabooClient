//
//  ConfigRepository.swift
//  PeekabooClient
//
//  Data Layer - Repository
//

import Foundation

final class ConfigRepository: ConfigRepositoryProtocol {
    private enum Keys {
        static let configurations = "vpn_configurations"
        static let activeConfigId = "active_config_id"
    }
    
    private let keychain: KeychainManager
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    init(keychain: KeychainManager = .shared) {
        self.keychain = keychain
    }
    
    func getActiveConfiguration() async throws -> VPNConfiguration {
        guard let activeId = UserDefaults.standard.string(forKey: Keys.activeConfigId) else {
            throw VPNError.configurationInvalid
        }
        
        let configurations = try await getAllConfigurations()
        
        guard let activeConfig = configurations.first(where: { $0.id == activeId }) else {
            throw VPNError.configurationInvalid
        }
        
        return activeConfig
        
    }
    
    func saveConfiguration(_ configuration: VPNConfiguration) async throws {
        var configurations = try await getAllConfigurations()
        
        if let index = configurations.firstIndex(where: { $0.id == configuration.id }) {
            configurations[index] = configuration
        } else {
            configurations.append(configuration)
        }
        
        let data = try encoder.encode(configurations)
        
        try keychain.save(data, forKey: Keys.configurations)
        
        
        if configurations.count == 1 {
            UserDefaults.standard.set(configuration.id, forKey: Keys.activeConfigId)
        }
    }
    
    func getAllConfigurations() async throws -> [VPNConfiguration] {
        do {
            let data = try keychain.load(key: Keys.configurations)
            let configurations = try decoder.decode([VPNConfiguration].self, from: data)
            return configurations
        } catch KeychainManager.KeychainError.itemNotFound {
            return []
        } catch {
            throw error
        }
    }
    
    func deleteConfiguration(id: String) async throws {
        
        var configurations = try await getAllConfigurations()
        
        configurations.removeAll { $0.id == id }
        
        if configurations.isEmpty {
            try keychain.delete(key: Keys.configurations)
            UserDefaults.standard.removeObject(forKey: Keys.activeConfigId)
        } else {
            let data = try encoder.encode(configurations)
            try keychain.save(data, forKey: Keys.configurations)
            
            let activeId = UserDefaults.standard.string(forKey: Keys.activeConfigId)
            if activeId == id {
                UserDefaults.standard.set(configurations.first?.id, forKey: Keys.activeConfigId)
            }
        }
    }
    
    func hasConfiguration() async -> Bool {
        return keychain.exists(key: Keys.configurations)
    }
}
