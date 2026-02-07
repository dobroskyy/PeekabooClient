//
//  ConfigRepository.swift
//  PeekabooClient
//
//  Data Layer - Repository
//

import Foundation
import Combine

final class ConfigRepository: ConfigRepositoryProtocol {

    @Published private var cachedActiveConfig: VPNConfiguration?

    var activeConfigurationPublisher: AnyPublisher<VPNConfiguration?, Never> {
        $cachedActiveConfig.eraseToAnyPublisher()
    }

    private enum Keys {
        static let configurations = "vpn_configurations"
        static let activeConfigId = "active_config_id"
    }
    
    private let keychain: KeychainManager
    private let sharedDefaults: UserDefaults?
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    init(keychain: KeychainManager = .shared) {
        self.keychain = keychain
        self.sharedDefaults = UserDefaults(suiteName: "group.dobrosky.PeekabooClient")
        Task { @MainActor in
            cachedActiveConfig = try? await getActiveConfiguration()
        }
    }
    
    func getActiveConfiguration() async throws -> VPNConfiguration {
        guard let activeId = sharedDefaults?.string(forKey: Keys.activeConfigId) else {
            throw VPNError.configurationInvalid
        }

        print(activeId)

        let configurations = try await getAllConfigurations()

        guard let activeConfig = configurations.first(where: { $0.id == activeId }) else {
            throw VPNError.configurationInvalid
        }

        return activeConfig

    }
    
    func saveConfiguration(_ configuration: VPNConfiguration) async throws {
        var configurations = try await getAllConfigurations()

        if let index = configurations.firstIndex(where: { $0.originalURL == configuration.originalURL }) {
            configurations[index] = configuration
        } else {
            configurations.append(configuration)
        }

        let data = try encoder.encode(configurations)
        try keychain.save(data, forKey: Keys.configurations)
        sharedDefaults?.set(configuration.id, forKey: Keys.activeConfigId)

        await MainActor.run {
            cachedActiveConfig = configuration
        }

    }

    func setActiveConfiguration(id: String) async throws {

        let configurations = try await getAllConfigurations()

        guard let config = configurations.first(where: { $0.id == id }) else {
            throw VPNError.configurationInvalid
        }

        sharedDefaults?.set(id, forKey: Keys.activeConfigId)

        await MainActor.run {
            cachedActiveConfig = config
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
    
    func deleteAllConfigurations() async throws {
        try keychain.delete(key: Keys.configurations)
        sharedDefaults?.removeObject(forKey: Keys.activeConfigId)
    }

    func deleteConfiguration(id: String) async throws {

        var configurations = try await getAllConfigurations()

        configurations.removeAll { $0.id == id }

        if configurations.isEmpty {
            try keychain.delete(key: Keys.configurations)
            sharedDefaults?.removeObject(forKey: Keys.activeConfigId)
        } else {
            let data = try encoder.encode(configurations)
            try keychain.save(data, forKey: Keys.configurations)

            let activeId = sharedDefaults?.string(forKey: Keys.activeConfigId)
            if activeId == id {
                sharedDefaults?.set(configurations.first?.id, forKey: Keys.activeConfigId)
            }
        }
    }

    func hasConfiguration() async -> Bool {
        return keychain.exists(key: Keys.configurations)
    }
}
