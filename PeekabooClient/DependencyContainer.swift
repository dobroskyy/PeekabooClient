//
//  DependencyContainer.swift
//  PeekabooClient
//
//  Core - Dependency Injection Container
//

import Foundation

final class DependencyContainer {
    
    static let shared = DependencyContainer()
    
    private init() {}
    
    private lazy var keychainManager: KeychainManager = {
        KeychainManager.shared
    }()
    
    private lazy var configRepository: ConfigRepositoryProtocol = {
        ConfigRepository(keychain: keychainManager)
    }()
    
    private lazy var vpnService: VPNServiceProtocol = {
        VPNService()
    }()

    func makeConnectVPNUseCase() -> ConnectVPNUseCaseProtocol {
        ConnectVPNUseCase(
            vpnService: vpnService,
            configRepository: configRepository
        )
    }

    func makeDisconnectVPNUseCase() -> DisconnectVPNUseCaseProtocol {
        DisconnectVPNUseCase(
            vpnService: vpnService
        )
    }

    func makeVPNViewModel() -> VPNViewModel {
        VPNViewModel(
            connectUseCase: makeConnectVPNUseCase(),
            disconnectUseCase: makeDisconnectVPNUseCase(),
            vpnService: vpnService,
            configRepository: configRepository
        )
    }
}
