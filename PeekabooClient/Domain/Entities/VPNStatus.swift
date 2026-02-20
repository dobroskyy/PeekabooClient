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

    var displayText: String {
        switch self {
        case .disconnected:
            return "Отключено"
        case .connecting:
            return "Подключение..."
        case .connected:
            return "Подключено"
        case .disconnecting:
            return "Отключение..."
        case .error(let error):
            return "Сбой: \(error)"
        case .reasserting:
            return "Переподключение..."
        }
    }

    var isTransitioning: Bool {
        switch self {
        case .connecting, .disconnecting, .reasserting: true
        case .disconnected, .connected, .error: false
        }
    }
}
