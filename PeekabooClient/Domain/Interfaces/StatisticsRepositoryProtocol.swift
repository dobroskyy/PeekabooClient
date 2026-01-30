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
    func getCurrentStatistics() async -> NetworkStatistics
    func saveStatistics(_ statistics: NetworkStatistics) async throws
    func resetStatistics() async throws
    func startMonitoring() async
    func stopMonitoring() async
}
