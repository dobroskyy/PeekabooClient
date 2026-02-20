//
//  VPNError.swift
//  PeekabooClient
//
//  Domain Layer - Entity
//

import Foundation

enum VPNError: LocalizedError, Equatable {
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
