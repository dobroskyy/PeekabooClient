//
//  ConnectVPNUseCase.swift
//  PeekabooClient
//
//  Domain Layer - Use Case
//

import Foundation

protocol ConnectVPNUseCaseProtocol {
    func execute() async throws
}

final class ConnectVPNUseCase: ConnectVPNUseCaseProtocol {
    
    private let vpnService: VPNServiceProtocol
    private let configRepository: ConfigRepositoryProtocol
    
    init(vpnService: VPNServiceProtocol, configRepository: ConfigRepositoryProtocol) {
        self.vpnService = vpnService
        self.configRepository = configRepository
    }
    
    
    func execute() async throws {
        guard await configRepository.hasConfiguration() else {
            throw VPNError.configurationInvalid
        }
        
        let configuration = try await configRepository.getActiveConfiguration()
        
        guard configuration.isValid else {
            throw VPNError.configurationInvalid
        }
        
        try await vpnService.connect(with: configuration)
        
    }
    
    
}
