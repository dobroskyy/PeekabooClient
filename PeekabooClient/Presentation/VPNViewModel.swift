//
//  VPNViewModel.swift
//  PeekabooClient
//
//  Presentation Layer - ViewModel
//

import Foundation
import Combine
import UIKit

final class VPNViewModel: ObservableObject {
    
    @Published private(set) var status: VPNStatus = .disconnected
    @Published private(set) var configurations: [VPNConfiguration] = []
    @Published private(set) var activeConfigurationId: String?
    @Published private(set) var errorMessage: String?
    @Published private(set) var isSwitchingConfiguration = false
    @Published private(set) var reconnectCount = 0
    
    private let shared = UserDefaults(suiteName: AppConstants.appGroupIdentifier)
    
    var showError: Bool { errorMessage != nil }
    func clearError() { errorMessage = nil }
    
    var isConfigurationSelectionEnabled: Bool {
        !isSwitchingConfiguration && !status.isTransitioning
    }
    
    private let connectUseCase: ConnectVPNUseCaseProtocol
    private let disconnectUseCase: DisconnectVPNUseCaseProtocol
    private let vpnService: VPNServiceProtocol
    private let configRepository: ConfigRepositoryProtocol

    private var cancellables = Set<AnyCancellable>()
    private var selectConfigurationTask: Task<Void, Never>?
    private var connectTask: Task<Void, Never>?

    init(connectUseCase: ConnectVPNUseCaseProtocol,
         disconnectUseCase: DisconnectVPNUseCaseProtocol,
         vpnService: VPNServiceProtocol,
         configRepository: ConfigRepositoryProtocol) {

        self.connectUseCase = connectUseCase
        self.disconnectUseCase = disconnectUseCase
        self.vpnService = vpnService
        self.configRepository = configRepository

        setupBindings()
        loadConfigurations()
        setupVPNService()
    }
    
    func toggleConnection() {
        connectTask?.cancel()
        connectTask = Task {
            do {
                switch status {
                case .disconnected:
                    try await connectUseCase.execute()
                case .connected:
                    try await disconnectUseCase.execute()
                default:
                    break
                }
            } catch {
                await MainActor.run { errorMessage = error.localizedDescription }
            }
        }
    }
    
    func addConfigurationFromClipboard() {
        guard let str = UIPasteboard.general.string, str.hasPrefix("vless://") else {
            errorMessage = "В буфере обмена нет URL"
            return
        }
        Task {
            do {
                let configuration = try VlessURLParser.parse(str)
                try await configRepository.saveConfiguration(configuration)
                loadConfigurations()
            } catch {
                await MainActor.run { errorMessage = error.localizedDescription }
            }
        }
    }

    func selectConfiguration(_ id: String) {
        guard isConfigurationSelectionEnabled else { return }
        
        selectConfigurationTask?.cancel()
        selectConfigurationTask = Task {
            await MainActor.run { isSwitchingConfiguration = true }
            defer { Task { @MainActor in isSwitchingConfiguration = false } }
            
            do {
                let wasConnected = status == .connected
                let previousConfigId = activeConfigurationId
                
                if wasConnected {
                    try await disconnectUseCase.execute()
                }
                guard !Task.isCancelled else { return }
                
                try await configRepository.setActiveConfiguration(id: id)
                guard !Task.isCancelled else { return }
                
                if wasConnected {
                    do {
                        try await connectUseCase.execute()
                    } catch {
                        if let previousId = previousConfigId {
                            try? await configRepository.setActiveConfiguration(id: previousId)
                        }
                        throw error
                    }
                }
            } catch {
                await MainActor.run { errorMessage = error.localizedDescription }
            }
        }
    }

    func loadConfigurations() {
        Task {
            do {
                let configs = try await configRepository.getAllConfigurations()
                await MainActor.run {
                    self.configurations = configs
                }
            } catch {
                await MainActor.run { errorMessage = error.localizedDescription }
            }
        }
    }
    
    func deleteConfiguration(id: String) {
        Task {
            do {
                try await configRepository.deleteConfiguration(id: id)
                loadConfigurations()
            } catch {
                await MainActor.run { errorMessage = error.localizedDescription }
            }
        }
    }
    
    private func setupBindings() {
        vpnService.statusPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newStatus in
                guard let self else { return }
                self.status = newStatus
                self.refreshReconnectCount()
                self.checkReconnectionLimit()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UIScene.didActivateNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                self.refreshReconnectCount()
                self.checkReconnectionLimit()
                
            }
            .store(in: &cancellables)
        
        configRepository.activeConfigurationPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] config in
                self?.activeConfigurationId = config?.id
            }
            .store(in: &cancellables)
    }

    private func refreshReconnectCount() {
        reconnectCount = shared?.integer(forKey: AppConstants.Keys.reconnectCount) ?? 0
    }
    
    private func checkReconnectionLimit() {
        let limitReached = self.shared?.bool(forKey: AppConstants.Keys.limitReached) ?? false
        if limitReached {
            Task {
                do {
                    try await self.disconnectUseCase.execute()
                    await MainActor.run {
                        self.errorMessage = "Превышен лимит переподключений. VPN отключён"
                    }
                } catch {
                    await MainActor.run {
                        self.errorMessage = error.localizedDescription
                    }
                }
            }
        }
    }

    private func setupVPNService() {
        Task {
            do {
                try await vpnService.setup()
            } catch {
                await MainActor.run { errorMessage = error.localizedDescription }
            }
        }
    }
    
    var connectedDate: Date? {
        vpnService.connectedDate
    }
}

extension VPNViewModel {
    var buttonTitle: String {
        switch status {
        case .disconnected:
            return "Отключено"
        case .connecting:
            return "Подключение..."
        case .connected:
            return "Подключено"
        case .disconnecting:
            return "Отключение..."
        case .reasserting:
            return "Переподключение..."
        case .error:
            return "Повторить"
        }
    }
    
    var isButtonEnabled: Bool {
        !status.isTransitioning
    }
    
    func formattedDuration(at date: Date = Date()) -> String {
        guard let connectedDate = connectedDate else {
            return "00:00"
        }
        let totalSeconds = Int(date.timeIntervalSince(connectedDate))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}
