//
//  StatisticsRepository.swift
//  PeekabooClient
//
//  Data Layer - Statistics Repository
//

import Foundation
import Combine

final class StatisticsRepository: StatisticsRepositoryProtocol {
    private let statisticsSubject = CurrentValueSubject<NetworkStatistics, Never>(.zero)
    private var timer: Timer?
    
    var statisticsPublisher: AnyPublisher<NetworkStatistics, Never> {
        statisticsSubject.eraseToAnyPublisher()
    }
    
    func getCurrentStatistics() -> NetworkStatistics {
        statisticsSubject.value
    }
    
    @MainActor
    func startMonitoring() {
        
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(withTimeInterval: AppConstants.Timeouts.statisticsUpdateInterval, repeats: true, block: { [weak self] _ in
            self?.loadStatistics()
        })
    }
    
    @MainActor
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        statisticsSubject.send(.zero)
    }
    
    private func loadStatistics() {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: AppConstants.appGroupIdentifier
        ) else {
            return
        }
        
        let statsURL = containerURL.appendingPathComponent(AppConstants.StorageKeys.statisticsFile)
        
        guard let data = try? Data(contentsOf: statsURL),
              let stats = try? JSONDecoder().decode(NetworkStatistics.self, from: data) else {
            return
        }
        
        let age = Date().timeIntervalSince(stats.timestamp)
        if age > AppConstants.Timeouts.statisticsFreshnessThreshold {
            statisticsSubject.send(.zero)
            return
        }
        
        statisticsSubject.send(stats)
    }
    
}
