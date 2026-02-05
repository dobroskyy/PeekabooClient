//
//  StatisticsRepositoryProtocol.swift
//  PeekabooClient
//
//  Domain Layer - Interface
//

import Foundation
import Combine

protocol StatisticsRepositoryProtocol {
    var statisticsPublisher: AnyPublisher<NetworkStatistics, Never> { get }
    func getCurrentStatistics() -> NetworkStatistics
    func startMonitoring()
    func stopMonitoring()
}
