import XCTest
@testable import PeekabooClient

final class XrayConfigMapperTests: XCTestCase {
    
    private func makeConfig(
        transport: VPNConfiguration.TransportType = .tcp,
        address: String = "example.com",
        port: Int = 443,
        userId: String = "test-uuid",
        publicKey: String = "testPBK",
        sni: String = "fake-sni.com",
        fingerprint: String = "chrome",
        shortId: String = "ab"
    ) -> VPNConfiguration {
        VPNConfiguration(
            id: "test-id",
            name: "TestConfig",
            originalURL: "vless://test",
            serverAddress: address,
            serverPort: port,
            userId: userId,
            encryption: "none",
            transport: transport,
            protocol: .vless(reality: .init(
                publicKey: publicKey,
                serverName: sni,
                fingerprint: fingerprint,
                shortId: shortId,
                spiderX: nil,
                mldsa65Verify: nil
            ))
        )
    }
    
    private func parseJSON(_ jsonString: String) throws -> [String: Any] {
        let data = jsonString.data(using: .utf8)!
        return try JSONSerialization.jsonObject(with: data) as! [String: Any]
    }
    
    func testOutputContainsAllTopLevelKeys() throws {
        let json = try XrayConfigMapper.mapToXrayJSON(configuration: makeConfig())
        let dict = try parseJSON(json)
        
        XCTAssertNotNil(dict["log"])
        XCTAssertNotNil(dict["inbounds"])
        XCTAssertNotNil(dict["outbounds"])
        XCTAssertNotNil(dict["routing"])
        XCTAssertNotNil(dict["dns"])
        XCTAssertNotNil(dict["policy"])
        XCTAssertNotNil(dict["stats"])
    }
    
    func testVlessOutbound_containsServerAndUser() throws {
        let config = makeConfig(address: "1.2.3.4", port: 2040, userId: "my-uuid")
        let json = try XrayConfigMapper.mapToXrayJSON(configuration: config)
        let dict = try parseJSON(json)
        
        let outbounds = dict["outbounds"] as! [[String: Any]]
        let vless = outbounds.first { $0["tag"] as? String == "proxy" }!
        
        XCTAssertEqual(vless["protocol"] as? String, "vless")
        
        let settings = vless["settings"] as! [String: Any]
        let vnext = (settings["vnext"] as! [[String: Any]]).first!
        
        XCTAssertEqual(vnext["address"] as? String, "1.2.3.4")
        XCTAssertEqual(vnext["port"] as? Int, 2040)
        
        let user = (vnext["users"] as! [[String: Any]]).first!
        XCTAssertEqual(user["id"] as? String, "my-uuid")
        XCTAssertEqual(user["encryption"] as? String, "none")
    }
    
    func testOutbounds_containsDirectAndBlock() throws {
        let json = try XrayConfigMapper.mapToXrayJSON(configuration: makeConfig())
        let dict = try parseJSON(json)
        
        let outbounds = dict["outbounds"] as! [[String: Any]]
        let tags = outbounds.compactMap { $0["tag"] as? String }
        
        XCTAssertTrue(tags.contains("proxy"))
        XCTAssertTrue(tags.contains("direct"))
        XCTAssertTrue(tags.contains("block"))
    }
    
    func testRealitySettings_containsAllFields() throws {
        let config = makeConfig(publicKey: "myPBK", sni: "my-sni.com", fingerprint: "firefox", shortId: "ff")
        let json = try XrayConfigMapper.mapToXrayJSON(configuration: config)
        let dict = try parseJSON(json)
        
        let outbounds = dict["outbounds"] as! [[String: Any]]
        let vless = outbounds.first { $0["tag"] as? String == "proxy" }!
        let stream = vless["streamSettings"] as! [String: Any]
        let reality = stream["realitySettings"] as! [String: Any]
        
        XCTAssertEqual(stream["security"] as? String, "reality")
        XCTAssertEqual(reality["publicKey"] as? String, "myPBK")
        XCTAssertEqual(reality["serverName"] as? String, "my-sni.com")
        XCTAssertEqual(reality["fingerprint"] as? String, "firefox")
        XCTAssertEqual(reality["shortId"] as? String, "ff")
    }
    
    func testTCPTransport_networkIsTCP() throws {
        let json = try XrayConfigMapper.mapToXrayJSON(configuration: makeConfig(transport: .tcp))
        let dict = try parseJSON(json)
        
        let outbounds = dict["outbounds"] as! [[String: Any]]
        let vless = outbounds.first { $0["tag"] as? String == "proxy" }!
        let stream = vless["streamSettings"] as! [String: Any]
        
        XCTAssertEqual(stream["network"] as? String, "tcp")
        XCTAssertNil(stream["xhttpSettings"])
    }
    
    func testXHTTPTransport_hasXhttpSettings() throws {
        let json = try XrayConfigMapper.mapToXrayJSON(configuration: makeConfig(transport: .xhttp))
        let dict = try parseJSON(json)
        
        let outbounds = dict["outbounds"] as! [[String: Any]]
        let vless = outbounds.first { $0["tag"] as? String == "proxy" }!
        let stream = vless["streamSettings"] as! [String: Any]
        
        XCTAssertEqual(stream["network"] as? String, "xhttp")
        
        let xhttpSettings = stream["xhttpSettings"] as? [String: Any]
        XCTAssertNotNil(xhttpSettings)
        XCTAssertEqual(xhttpSettings?["mode"] as? String, "auto")
    }
    
    func testAllTransports_setCorrectNetwork() throws {
        let cases: [(VPNConfiguration.TransportType, String)] = [
            (.tcp, "tcp"),
            (.ws, "ws"),
            (.grpc, "grpc"),
            (.h2, "h2"),
            (.xhttp, "xhttp"),
            (.httpupgrade, "httpupgrade"),
        ]
        
        for (transport, expectedNetwork) in cases {
            let json = try XrayConfigMapper.mapToXrayJSON(configuration: makeConfig(transport: transport))
            let dict = try parseJSON(json)
            
            let outbounds = dict["outbounds"] as! [[String: Any]]
            let vless = outbounds.first { $0["tag"] as? String == "proxy" }!
            let stream = vless["streamSettings"] as! [String: Any]
            
            XCTAssertEqual(stream["network"] as? String, expectedNetwork, "Failed for transport: \(transport)")
        }
    }
    
    func testInbound_socksOnCorrectPort() throws {
        let json = try XrayConfigMapper.mapToXrayJSON(configuration: makeConfig())
        let dict = try parseJSON(json)
        
        let inbounds = dict["inbounds"] as! [[String: Any]]
        let socks = inbounds.first { $0["tag"] as? String == "socks" }!
        
        XCTAssertEqual(socks["listen"] as? String, "127.0.0.1")
        XCTAssertEqual(socks["port"] as? Int, AppConstants.Network.socksPort)
        XCTAssertEqual(socks["protocol"] as? String, "socks")
    }
}
