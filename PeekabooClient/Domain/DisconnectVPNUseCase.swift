//
//  DisconnectVPNUseCase.swift
//  PeekabooClient
//
//  Domain Layer - Use Case
//

import Foundation

protocol DisconnectVPNUseCaseProtocol {
    func execute() async throws
}

final class DisconnectVPNUseCase: DisconnectVPNUseCaseProtocol {
    
    private let vpnService: VPNServiceProtocol
    
    init(vpnService: VPNServiceProtocol) {
        self.vpnService = vpnService
    }
    
    func execute() async throws {
        try await vpnService.disconnect()
    }
    
    
}
