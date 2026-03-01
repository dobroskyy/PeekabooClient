//
//  VPNServiceProtocol.swift
//  PeekabooClient
//
//  Domain Layer - Interface
//

import Foundation
import Combine

@MainActor
protocol VPNServiceProtocol {
    var statusPublisher: AnyPublisher<VPNStatus, Never> { get }
    var connectedDate: Date? { get }
    func connect(with configuration: VPNConfiguration) async throws
    func disconnect() async throws
    func setup() async throws
}
