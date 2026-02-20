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
    
    private lazy var statisticsRepository: StatisticsRepositoryProtocol = {
        StatisticsRepository()
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

    func makeMonitorVPNStatusUseCase() -> MonitorVPNStatusUseCaseProtocol {
        MonitorVPNStatusUseCase(
            vpnService: vpnService,
            statisticsRepository: statisticsRepository
        )
    }

    func makeVPNViewModel() -> VPNViewModel {
        VPNViewModel(
            connectUseCase: makeConnectVPNUseCase(),
            disconnectUseCase: makeDisconnectVPNUseCase(),
            monitorStatusUseCase: makeMonitorVPNStatusUseCase(),
            vpnService: vpnService,
            configRepository: configRepository
        )
    }
}
