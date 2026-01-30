//
//  GetServerInfoUseCase.swift
//  PeekabooClient
//
//  Domain Layer - Use Case
//

import Foundation

protocol GetServerInfoUseCaseProtocol {
    func execute() async -> String
}

final class GetServerInfoUseCase: GetServerInfoUseCaseProtocol {
    
    private let configRepository: ConfigRepositoryProtocol
    
    init(configRepository: ConfigRepositoryProtocol) {
        self.configRepository = configRepository
    }
    
    func execute() async -> String {
        do {
            let config = try await configRepository.getActiveConfiguration()
            return "\(config.serverAddress):\(config.serverPort)"
        } catch {
            return "Нет конфигурации"
        }
    }
    
    
}
