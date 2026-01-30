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
    
    init(vpnService: VPNServiceProtocol, statisticsRepository: StatisticsRepositoryProtocol) {
        self.vpnService = vpnService
        self.statisticsRepository = statisticsRepository
    }
    
}
