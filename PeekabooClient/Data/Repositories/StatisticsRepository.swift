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
    
    private let appGroupIdentifier = "group.dobrosky.PeekabooClient"
    
    var statisticsPublisher: AnyPublisher<NetworkStatistics, Never> {
        statisticsSubject.eraseToAnyPublisher()
    }
    
    func getCurrentStatistics() -> NetworkStatistics {
        statisticsSubject.value
    }
    
    @MainActor
    func startMonitoring() {
        
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { [weak self] _ in
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
            forSecurityApplicationGroupIdentifier: appGroupIdentifier
        ) else {
            return
        }
        
        let statsURL = containerURL.appendingPathComponent("stats.json")
        
        guard let data = try? Data(contentsOf: statsURL),
              let stats = try? JSONDecoder().decode(NetworkStatistics.self, from: data) else {
            return
        }
        
        let age = Date().timeIntervalSince(stats.timestamp)
        if age > 5.0 {
            statisticsSubject.send(.zero)
            return
        }
        
        statisticsSubject.send(stats)
    }
    
}
