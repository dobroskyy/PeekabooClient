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
    
    private var cancellables = Set<AnyCancellable>()
    
    init(connectUseCase: ConnectVPNUseCaseProtocol,
         disconnectUseCase: DisconnectVPNUseCaseProtocol,
         monitorStatusUseCase: MonitorVPNStatusUseCaseProtocol,
         getServerInfoUseCase: GetServerInfoUseCaseProtocol,
         vpnService: VPNServiceProtocol) {
        
        self.connectUseCase = connectUseCase
        self.disconnectUseCase = disconnectUseCase
        self.monitorStatusUseCase = monitorStatusUseCase
        self.getServerInfoUseCase = getServerInfoUseCase
        self.vpnService = vpnService
        
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
