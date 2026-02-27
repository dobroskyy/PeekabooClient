//
//  VPNStatus.swift
//  PeekabooClient
//
//  Domain Layer - Entity
//

import Foundation

enum VPNStatus: Equatable {
    case disconnected
    case connecting
    case connected
    case disconnecting
    case error(VPNError)
    case reasserting

    var isTransitioning: Bool {
        switch self {
        case .connecting, .disconnecting, .reasserting: true
        case .disconnected, .connected, .error: false
        }
    }
}
