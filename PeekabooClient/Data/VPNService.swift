//
//  VPNService.swift
//  PeekabooClient
//
//  Data Layer - VPN Service
//

import Foundation
import NetworkExtension
import Combine

@MainActor
final class VPNService: VPNServiceProtocol {
    
    private var manager: NETunnelProviderManager?
    
    private let shared = UserDefaults(suiteName: AppConstants.appGroupIdentifier)
    
    private let statusSubject = CurrentValueSubject<VPNStatus, Never>(.disconnected)
    
    private var cancellables = Set<AnyCancellable>()
    
    var statusPublisher: AnyPublisher<VPNStatus, Never> {
        statusSubject.eraseToAnyPublisher()
    }
    
    var connectedDate: Date? {
        manager?.connection.connectedDate
    }
    
    init() {
        observeVPNStatusChanges()
    }
    
    func connect(with configuration: VPNConfiguration) async throws {
        shared?.set(false, forKey: AppConstants.Keys.limitReached)
        
        if manager == nil {
            try await requestPermission(with: configuration)
        } else {
            try await updateConfiguration(with: configuration)
        }
        guard let manager = manager else {
            throw VPNError.configurationInvalid
        }
        let currentStatus = manager.connection.status
        guard currentStatus == .disconnected || currentStatus == .invalid else {
            return
        }
        try manager.connection.startVPNTunnel(options: ["userInitiated": NSNumber(value: true)])
    }
    
    func disconnect() async throws {
        shared?.set(0, forKey: AppConstants.Keys.reconnectCount)
        guard let manager = manager else { return }
        let currentStatus = manager.connection.status
        guard currentStatus != .disconnected && currentStatus != .invalid else { return }
        manager.isOnDemandEnabled = false
        try await manager.saveToPreferences()
        try await manager.loadFromPreferences()
        try await withTimeout(seconds: 10) {
            manager.connection.stopVPNTunnel()
            for await status in self.statusSubject.values {
                switch status {
                case .disconnected, .error:
                    return
                default:
                    continue
                }
            }
        }
    }
    
    func setup() async throws {
        let managers = try await NETunnelProviderManager.loadAllFromPreferences()
        self.manager = managers.first { ($0.protocolConfiguration as? NETunnelProviderProtocol)?.providerBundleIdentifier == AppConstants.providerBundleIdentifier }
        if let manager = manager {
            let currentStatus = mapNEVPNStatus(manager.connection.status)
            statusSubject.send(currentStatus)
        }
    }

    private func requestPermission(with configuration: VPNConfiguration) async throws {
        let newManager = NETunnelProviderManager()
        newManager.localizedDescription = AppConstants.appName
        try await configureManager(newManager, with: configuration)
        self.manager = newManager
    }

    private func updateConfiguration(with configuration: VPNConfiguration) async throws {
        guard let manager = manager else {
            throw VPNError.configurationInvalid
        }
        try await configureManager(manager, with: configuration)
    }

    private func configureManager(_ manager: NETunnelProviderManager, with configuration: VPNConfiguration) async throws {
        let rule = NEOnDemandRuleConnect()
        rule.interfaceTypeMatch = .any

        manager.protocolConfiguration = try buildProtocolConfig(for: configuration)
        manager.isEnabled = true
        manager.onDemandRules = [rule]
        manager.isOnDemandEnabled = true
        try await manager.saveToPreferences()
        try await manager.loadFromPreferences()
    }

    private func observeVPNStatusChanges() {
        NotificationCenter.default.publisher(for: .NEVPNStatusDidChange, object: nil)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self, let manager = self.manager else { return }
                let neStatus = manager.connection.status
                let vpnStatus = self.mapNEVPNStatus(neStatus)
                self.statusSubject.send(vpnStatus)
            }
            .store(in: &cancellables)
    }

    private func mapNEVPNStatus(_ status: NEVPNStatus) -> VPNStatus {
        switch status {
        case .invalid, .disconnected:
            return .disconnected
        case .connecting:
            return .connecting
        case .connected:
            return .connected
        case .reasserting:
            return .reasserting
        case .disconnecting:
            return .disconnecting
        @unknown default:
            return .disconnected
        }
    }
}

// MARK: - Helper methods

extension VPNService {

    private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            group.addTask {
                try await Task.sleep(for: .seconds(seconds))
                throw VPNError.timeout
            }
            guard let result = try await group.next() else {
                throw VPNError.timeout
            }
            group.cancelAll()
            return result
        }
    }

    private func buildProtocolConfig(for configuration: VPNConfiguration) throws -> NETunnelProviderProtocol {
        let proto = NETunnelProviderProtocol()
        proto.providerBundleIdentifier = AppConstants.providerBundleIdentifier
        proto.serverAddress = configuration.serverAddress
        let data = try JSONEncoder().encode(configuration)
        guard let str = String(data: data, encoding: .utf8) else {
            throw VPNError.configurationInvalid
        }
        proto.providerConfiguration = ["config": str]
        return proto
    }
}
