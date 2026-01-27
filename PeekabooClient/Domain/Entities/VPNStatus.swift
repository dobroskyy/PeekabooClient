//
//  VPNStatus.swift
//  PeekabooClient
//
//  Domain Layer - Entity
//

import Foundation

enum VPNStatus {
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

enum VPNError: LocalizedError {
    case configurationInvalid
    case networkUnavailable
    case authenticationFailed
    case timeout
    case permissionDenied
    case permissionNotGranted
    case alreadyInProgress
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .configurationInvalid:
            return "Неверная конфигурация приложения"
        case .networkUnavailable:
            return "Соединение с интернетом отсутствует"
        case .authenticationFailed:
            return "Не удалось выполнить аутентификацию"
        case .timeout:
            return "Превышено время ожидания ответа"
        case .permissionDenied:
            return "В доступе отказано. У вас недостаточно прав для выполнения этой операции"
        case .permissionNotGranted:
            return "Необходимые разрешения не предоставлены. Пожалуйста, предоставьте доступ в настройках"
        case .alreadyInProgress:
            return "Операция уже выполняется"
        case .unknown(let description):
            return "Произошла неизвестная ошибка: \(description)"
        }
    }
}
