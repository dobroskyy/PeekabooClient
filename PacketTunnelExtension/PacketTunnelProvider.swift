//
//  PacketTunnelProvider.swift
//  PacketTunnelExtension
//
//  Created by Максим on 03.02.2026.
//

import NetworkExtension
import LibXray
import Tun2SocksKit

class PacketTunnelProvider: NEPacketTunnelProvider {
    
    private let MTU = 8500

    override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        
        guard let protocolConfig = self.protocolConfiguration as? NETunnelProviderProtocol else {
            completionHandler(NSError(domain: "Config", code: -1))
            return
        }
        
        guard let configString = protocolConfig.providerConfiguration?["config"] as? String else {
            completionHandler(NSError(domain: "Config", code: -2))
            return
        }
        
        guard let configData = configString.data(using: .utf8) else {
            completionHandler(NSError(domain: "Config", code: -3))
            return
        }
        
        do {
            let vpnConfig = try JSONDecoder().decode(VPNConfiguration.self, from: configData)
            let xrayJSON = try XrayConfigMapper.mapToXrayJSON(configuration: vpnConfig)
            
            let request: [String: String] = [
                "datDir": "",
                "configJSON": xrayJSON
            ]
            let requestData = try JSONEncoder().encode(request)
            let base64Request = requestData.base64EncodedString()
            
            let result = LibXrayRunXrayFromJSON(base64Request)
            
            if !result.isEmpty && result.lowercased().contains("error") {
                completionHandler(NSError(domain: "LibXray", code: -4, userInfo: [NSLocalizedDescriptionKey: result]))
                return
            }
            
            configureNetworkSettings { [weak self] error in
                if let error = error {
                    completionHandler(error)
                    return
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    do {
                        try self?.startSocks5Tunnel()
                        completionHandler(nil)
                    } catch {
                        completionHandler(error)
                    }
                }
            }
            
        } catch {
            completionHandler(error)
            return
        }
    }
    
    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        Socks5Tunnel.quit()
        LibXrayStopXray()
        completionHandler()
    }
    
    private func startSocks5Tunnel() throws {
        let socks5Config = """
        tunnel:
          mtu: \(MTU)
        
        socks5:
          port: \(AppConstants.Network.socksPort)
          address: "127.0.0.1"
          udp: 'udp'
        
        misc:
          task-stack-size: 20480
          connect-timeout: 5000
          read-write-timeout: 60000
          log-level: warning
          limit-nofile: 65535
        """
        
        Socks5Tunnel.run(withConfig: .string(content: socks5Config)) { _ in }
    }
    
    override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)?) {
        if let handler = completionHandler {
            handler(messageData)
        }
    }
    
    override func sleep(completionHandler: @escaping () -> Void) {
        completionHandler()
    }
    
    override func wake() {
    }
}

extension PacketTunnelProvider {
    
    private func configureNetworkSettings(completionHandler: @escaping (Error?) -> Void) {
        let settings = buildNetworkSettings()
        
        setTunnelNetworkSettings(settings) { error in
            completionHandler(error)
        }
    }
    
    private func buildNetworkSettings() -> NEPacketTunnelNetworkSettings {
        let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "198.18.0.1")
        settings.mtu = NSNumber(value: MTU)
        
        let ipv4Settings = NEIPv4Settings(addresses: ["198.18.0.1"], subnetMasks: ["255.255.255.0"])
        let defaultV4Route = NEIPv4Route(destinationAddress: "0.0.0.0", subnetMask: "0.0.0.0")
        defaultV4Route.gatewayAddress = "198.18.0.1"
        ipv4Settings.includedRoutes = [defaultV4Route]
        ipv4Settings.excludedRoutes = []
        settings.ipv4Settings = ipv4Settings
        
        let dnsSettings = NEDNSSettings(servers: ["8.8.8.8", "1.1.1.1"])
        dnsSettings.matchDomains = [""]
        settings.dnsSettings = dnsSettings
        
        return settings
    }
}
