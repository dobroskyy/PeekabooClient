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
    
    private let appGroupIdentifier = "group.com.dobrosky.PeekabooClient"
    
    var statisticsPublisher: AnyPublisher<NetworkStatistics, Never> {
        statisticsSubject.eraseToAnyPublisher()
    }
    
    func getCurrentStatistics() async -> NetworkStatistics {
        statisticsSubject.value
    }
    
    func saveStatistics(_ statistics: NetworkStatistics) async throws {
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) else {
            throw NSError(domain: "StatisticsRepository", code: -1)
        }
        
        let statsURL = containerURL.appendingPathComponent("statistics.json")
        let data = try JSONEncoder().encode(statistics)
        try data.write(to: statsURL, options: .atomic)
        
    }
    
    func resetStatistics() async throws {
        try await saveStatistics(.zero)
        statisticsSubject.send(.zero)
    }
    
    func startMonitoring() async {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { [weak self] _ in
            self?.loadStatistics()
        })
    }
    
    func stopMonitoring() async {
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
        
        let statsURL = containerURL.appendingPathComponent("statistics.json")
        
        guard let data = try? Data(contentsOf: statsURL),
              let stats = try? JSONDecoder().decode(NetworkStatistics.self, from: data) else {
            return
        }
        
        statisticsSubject.send(stats)
    }
    
}
