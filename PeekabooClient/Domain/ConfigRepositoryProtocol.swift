//
//  ConfigRepositoryProtocol.swift
//  PeekabooClient
//
//  Domain Layer - Interface
//

import Foundation
import Combine

protocol ConfigRepositoryProtocol {
    var activeConfigurationPublisher: AnyPublisher<VPNConfiguration?, Never> { get }
    func getActiveConfiguration() async throws -> VPNConfiguration
    func saveConfiguration(_ configuration: VPNConfiguration) async throws
    func setActiveConfiguration(id: String) async throws
    func getAllConfigurations() async throws -> [VPNConfiguration]
    func deleteConfiguration(id: String) async throws
    func hasConfiguration() async -> Bool
}

