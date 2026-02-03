//
//  MonitorVPNStatusUseCase.swift
//  PeekabooClient
//
//  Domain Layer - Use Case
//

import Foundation
import Combine

protocol MonitorVPNStatusUseCaseProtocol {
    var statusPublisher: AnyPublisher<VPNStatus, Never> { get }
    var statisticsPublisher: AnyPublisher<NetworkStatistics, Never> { get }
}

final class MonitorVPNStatusUseCase: MonitorVPNStatusUseCaseProtocol {
    var statusPublisher: AnyPublisher<VPNStatus, Never> {
        vpnService.statusPublisher
    }
    
    var statisticsPublisher: AnyPublisher<NetworkStatistics, Never> {
        statisticsRepository.statisticsPublisher
    }
    
    private let vpnService: VPNServiceProtocol
    private let statisticsRepository: StatisticsRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(vpnService: VPNServiceProtocol, statisticsRepository: StatisticsRepositoryProtocol) {
        self.vpnService = vpnService
        self.statisticsRepository = statisticsRepository
        observeVPNStatus()
    }
    
    private func observeVPNStatus() {
        vpnService.statusPublisher
            .sink { [weak self] status in
                Task { [weak self] in
                    switch status {
                    case .connected:
                        await self?.statisticsRepository.startMonitoring()
                    case .disconnected:
                        await self?.statisticsRepository.stopMonitoring()
                    default:
                        break
                    }
                }
            }
            .store(in: &cancellables)
    }
    
}
