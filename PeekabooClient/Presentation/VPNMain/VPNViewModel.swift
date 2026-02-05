//
//  VPNViewModel.swift
//  PeekabooClient
//
//  Presentation Layer - ViewModel
//

import Foundation
import Combine

final class VPNViewModel {
    
    @Published private(set) var status: VPNStatus = .disconnected
    @Published private(set) var statistics: NetworkStatistics = .zero
    @Published private(set) var serverInfo: String = "Загрузка..."
    
    private let connectUseCase: ConnectVPNUseCaseProtocol
    private let disconnectUseCase: DisconnectVPNUseCaseProtocol
    private let monitorStatusUseCase: MonitorVPNStatusUseCaseProtocol
    private let getServerInfoUseCase: GetServerInfoUseCaseProtocol
    private let vpnService: VPNServiceProtocol
    private let configRepository: ConfigRepositoryProtocol
    
    private var cancellables = Set<AnyCancellable>()
    
    init(connectUseCase: ConnectVPNUseCaseProtocol,
         disconnectUseCase: DisconnectVPNUseCaseProtocol,
         monitorStatusUseCase: MonitorVPNStatusUseCaseProtocol,
         getServerInfoUseCase: GetServerInfoUseCaseProtocol,
         vpnService: VPNServiceProtocol,
         configRepository: ConfigRepositoryProtocol) {
        
        self.connectUseCase = connectUseCase
        self.disconnectUseCase = disconnectUseCase
        self.monitorStatusUseCase = monitorStatusUseCase
        self.getServerInfoUseCase = getServerInfoUseCase
        self.vpnService = vpnService
        self.configRepository = configRepository
        
        setupBindings()
        loadServerInfo()
        setupVPNService()
    }
    
    func toggleConnection() {
        Task {
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
                print("Error: \(error)")
            }
        }
    }
    
    func addConfiguration(from vlessURL: String) {
        Task {
            do {
                let configuration = try VlessURLParser.parse(vlessURL)
                try await configRepository.saveConfiguration(configuration)
                
                await MainActor.run {
                    print("Конфигурация сохранена: \(configuration.name)")
                    // TODO: alert
                }
            } catch {
                await MainActor.run {
                    print("Ошибка: \(error)")
                    // TODO: alert
                }
            }
        }
    }
    
    private func setupBindings() {
        monitorStatusUseCase.statusPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newStatus in
                self?.status = newStatus
            }
            .store(in: &cancellables)
        
        monitorStatusUseCase.statisticsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newStats in
                self?.statistics = newStats
            }
            .store(in: &cancellables)
    }
    
    private func loadServerInfo() {
        Task {
            let info = await getServerInfoUseCase.execute()
            await MainActor.run {
                self.serverInfo = info
            }
        }
    }

    private func setupVPNService() {
        Task {
            try? await vpnService.setup()
        }
    }
    
}

extension VPNViewModel {
    var buttonTitle: String {
        switch status {
        case .disconnected:
            return "Подключить"
        case .connecting:
            return "Подключение..."
        case .connected:
            return "Отключить"
        case .disconnecting:
            return "Отключение..."
        case .reasserting:
            return "Переподключение..."
        case .error:
            return "Повторить"
        }
    }
    
    var statusText: String {
        status.displayText
    }
    
    var isButtonEnabled: Bool {
        !status.isTransitioning
    }
}
