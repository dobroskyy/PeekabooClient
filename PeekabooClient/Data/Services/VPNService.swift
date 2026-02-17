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
    
    init() {
        observeVPNStatusChanges()
    }
    
    func getCurrentStatus() -> VPNStatus {
        return statusSubject.value
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
        
        manager.connection.stopVPNTunnel()
        
        for await status in statusSubject.values {
            if status == .disconnected { return }
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
    
    func requestPermission(with configuration: VPNConfiguration) async throws {
        let newManager = NETunnelProviderManager()

        let protocolConfig = NETunnelProviderProtocol()
        protocolConfig.providerBundleIdentifier = AppConstants.providerBundleIdentifier
        protocolConfig.serverAddress = configuration.serverAddress
        
        let configData = try JSONEncoder().encode(configuration)
        guard let configString = String(data: configData, encoding: .utf8) else {
            throw VPNError.configurationInvalid
        }
        
        protocolConfig.providerConfiguration = ["config": configString]
        
        newManager.protocolConfiguration = protocolConfig
        newManager.localizedDescription = "Peekaboo Client"
        newManager.isEnabled = true
        
        try await newManager.saveToPreferences()
        try await newManager.loadFromPreferences()
        
        self.manager = newManager
    }
    
    private func updateConfiguration(with configuration: VPNConfiguration) async throws {
        guard let manager = manager else {
            throw VPNError.configurationInvalid
        }
        
        let protocolConfig = NETunnelProviderProtocol()
        protocolConfig.providerBundleIdentifier = AppConstants.providerBundleIdentifier
        protocolConfig.serverAddress = configuration.serverAddress
        
        let configData = try JSONEncoder().encode(configuration)
        guard let configString = String(data: configData, encoding: .utf8) else {
            throw VPNError.configurationInvalid
        }
        
        protocolConfig.providerConfiguration = ["config": configString]
        
        manager.protocolConfiguration = protocolConfig
        manager.isEnabled = true
        
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
        case .invalid:
            return .disconnected
        case .disconnected:
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
