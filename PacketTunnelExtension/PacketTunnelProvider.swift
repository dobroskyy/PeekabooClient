//
//  PacketTunnelProvider.swift
//  PacketTunnelExtension
//
//  Created by Максим on 03.02.2026.
//

import NetworkExtension
import LibXray
import Tun2SocksKit
import UserNotifications

final class PacketTunnelProvider: NEPacketTunnelProvider {
    
    private let shared = UserDefaults(suiteName: AppConstants.appGroupIdentifier)

    private let MTU = AppConstants.Network.tunnelMTU
    private let socksPort = AppConstants.Network.socksPort

    override func startTunnel(options: [String: NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        if let shared = self.shared {
            let isActive = shared.bool(forKey: AppConstants.Keys.sessionIsActive)
            if options == nil && isActive {
                let count = shared.integer(forKey: AppConstants.Keys.reconnectCount)
                if count >= 25 {
                    sendNotification(body: "Превышен лимит переподключений. VPN Отключен")
                    completionHandler(makeError("Превышен лимит переподключений", code: 0))
                    return
                }
                shared.set(count + 1, forKey: AppConstants.Keys.reconnectCount)
                sendNotification(body: "VPN Переподключен")
            } else {
                shared.set(true, forKey: AppConstants.Keys.sessionIsActive)
                shared.set(0, forKey: AppConstants.Keys.reconnectCount)
            }
        }
        
        guard let protocolConfig = self.protocolConfiguration as? NETunnelProviderProtocol else {
            completionHandler(makeError("Отсутствует конфигурация протокола", code: -1))
            return
        }
        guard let configString = protocolConfig.providerConfiguration?["config"] as? String else {
            completionHandler(makeError("Отсутствует конфигурация VPN", code: -2))
            return
        }
        guard let configData = configString.data(using: .utf8) else {
            completionHandler(makeError("Неверная кодировка конфигурации", code: -3))
            return
        }
        do {
            try startXray(configData: configData)
        } catch {
            completionHandler(error)
            return
        }
        
        let networkSettings = buildNetworkSettings()
        setTunnelNetworkSettings(networkSettings) { [weak self] error in
            guard let self else {
                completionHandler(Self.makeError("Провайдер деинициализирован", code: -99))
                return
            }
            if let error {
                completionHandler(error)
                return
            }
            
            self.startSocks5Tunnel(completionHandler: completionHandler)
        }
        
    }

    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        Socks5Tunnel.quit()
        LibXrayStopXray()
        
        if let shared = self.shared {
            shared.set(false, forKey: AppConstants.Keys.sessionIsActive)
        }
        
        DispatchQueue.global().async {
            while LibXrayGetXrayState() {
                Thread.sleep(forTimeInterval: 0.05)
            }
            completionHandler()
        }
    }

    private func startXray(configData: Data) throws {
        let vpnConfig = try JSONDecoder().decode(VPNConfiguration.self, from: configData)
        let xrayJSON = try XrayConfigMapper.mapToXrayJSON(configuration: vpnConfig)
        let request: [String: String] = [
            "datDir": "",
            "configJSON": xrayJSON
        ]
        let requestData = try JSONEncoder().encode(request)
        let base64Request = requestData.base64EncodedString()
        let result = LibXrayRunXrayFromJSON(base64Request)

        if !LibXrayGetXrayState() {
            throw makeError("Xray failed to start: \(result)")
        }
    }

    private func startSocks5Tunnel(completionHandler: @escaping (Error?) -> Void) {
        let config = """
        tunnel:
          mtu: \(MTU)
        socks5:
          port: \(socksPort)
          address: 127.0.0.1
          udp: 'udp'
        misc:
          task-stack-size: 20480
          connect-timeout: 5000
          read-write-timeout: 60000
          log-file: stderr
          log-level: error
          limit-nofile: 65535
        """

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else {
                completionHandler(Self.makeError("Провайдер деинициализирован", code: -99))
                return
            }
            Thread.sleep(forTimeInterval: 1.0)
            completionHandler(nil)
            let exitCode = Socks5Tunnel.run(withConfig: .string(content: config))
            if exitCode != 0 {
                self.cancelTunnelWithError(self.makeError("Socks5Tunnel завершился с кодом: \(exitCode)", code: Int(exitCode)))
            }
        }
    }

    private func buildNetworkSettings() -> NEPacketTunnelNetworkSettings {
        let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "254.1.1.1")
        settings.mtu = NSNumber(value: MTU)
        let ipv4 = NEIPv4Settings(addresses: ["198.18.0.1"], subnetMasks: ["255.255.255.0"])
        ipv4.includedRoutes = [NEIPv4Route.default()]
        settings.ipv4Settings = ipv4
        let ipv6 = NEIPv6Settings(addresses: ["fd6e:a81b:704f:1211::1"], networkPrefixLengths: [64])
        ipv6.includedRoutes = [NEIPv6Route.default()]
        settings.ipv6Settings = ipv6
        let dns = NEDNSSettings(servers: ["1.1.1.1", "8.8.8.8"])
        dns.matchDomains = [""]
        settings.dnsSettings = dns
        return settings
    }

    private func makeError(_ message: String, code: Int = -1) -> NSError {
        Self.makeError(message, code: code)
    }
    
    private static func makeError(_ message: String, code: Int = -1) -> NSError {
        NSError(domain: "PacketTunnel", code: code,
                userInfo: [NSLocalizedDescriptionKey: message])
    }
    
    private func sendNotification(body: String) {
        let content = UNMutableNotificationContent()
        content.title = "Peekaboo"
        content.body = body
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
}
