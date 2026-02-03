//
//  VPNServiceProtocol.swift
//  PeekabooClient
//
//  Domain Layer - Interface
//

import Foundation
import Combine

protocol VPNServiceProtocol {
    var statusPublisher: AnyPublisher<VPNStatus, Never> { get }
    func getCurrentStatus() -> VPNStatus
    func connect(with configuration: VPNConfiguration) async throws
    func disconnect() async throws
    func setup() async throws
    func requestPermission(with configuration: VPNConfiguration) async throws
}
