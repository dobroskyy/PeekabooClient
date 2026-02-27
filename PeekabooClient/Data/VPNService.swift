//
//  VPNService.swift
//  PeekabooClient
//
//  Data Layer - VPN Service
//

import Foundation
import NetworkExtension
import Combine

final class VPNService: VPNServiceProtocol {
    
    private var manager: NETunnelProviderManager?
    
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
        try manager.connection.startVPNTunnel()
    }
    
    func disconnect() async throws {
        guard let manager = manager else { return }
        let currentStatus = manager.connection.status
        guard currentStatus != .disconnected && currentStatus != .invalid else { return }
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
    
    private func requestPermission(with configuration: VPNConfiguration) async throws {
        let newManager = NETunnelProviderManager()
        
        let rule = NEOnDemandRuleConnect()
        rule.interfaceTypeMatch = .any
        
        let protocolConfig = try buildProtocolConfig(for: configuration)
        newManager.protocolConfiguration = protocolConfig
        newManager.localizedDescription = AppConstants.appName
        newManager.isEnabled = true
        newManager.onDemandRules = [rule]
        newManager.isOnDemandEnabled = true
        try await newManager.saveToPreferences()
        try await newManager.loadFromPreferences()
        self.manager = newManager
    }
    
    private func updateConfiguration(with configuration: VPNConfiguration) async throws {
        guard let manager = manager else {
            throw VPNError.configurationInvalid
        }
        
        let rule = NEOnDemandRuleConnect()
        rule.interfaceTypeMatch = .any
        
        let protocolConfig = try buildProtocolConfig(for: configuration)
        manager.protocolConfiguration = protocolConfig
        manager.isEnabled = true
        manager.onDemandRules = [rule]
        manager.isOnDemandEnabled = true
        try await manager.saveToPreferences()
        try await manager.loadFromPreferences()
    }
    
    private func observeVPNStatusChanges() {
        NotificationCenter.default.publisher(for: .NEVPNStatusDidChange, object: nil)
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
