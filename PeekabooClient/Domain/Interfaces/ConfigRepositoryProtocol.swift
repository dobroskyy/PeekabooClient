//
//  ConfigRepositoryProtocol.swift
//  PeekabooClient
//
//  Domain Layer - Interface
//

import Foundation

protocol ConfigRepositoryProtocol {
    func getActiveConfiguration() async throws -> VPNConfiguration
    func saveConfiguration(_ configuration: VPNConfiguration) async throws
    func getAllConfigurations() async throws -> [VPNConfiguration]
    func deleteConfiguration(id: String) async throws
    func hasConfiguration() async -> Bool
}

