//
//  GetServerInfoUseCase.swift
//  PeekabooClient
//
//  Domain Layer - Use Case
//

import Foundation
import Combine

protocol GetServerInfoUseCaseProtocol {
    var serverInfoPublisher: AnyPublisher<String, Never> { get }
    func execute() async -> String
}

final class GetServerInfoUseCase: GetServerInfoUseCaseProtocol {

    private let configRepository: ConfigRepositoryProtocol

    init(configRepository: ConfigRepositoryProtocol) {
        self.configRepository = configRepository
    }

    var serverInfoPublisher: AnyPublisher<String, Never> {
        configRepository.activeConfigurationPublisher
            .map { config in
                guard let config = config else {
                    return "Нет конфигурации"
                }
                return "\(config.serverAddress):\(config.serverPort)"
            }
            .eraseToAnyPublisher()
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
