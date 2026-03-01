import XCTest
@testable import PeekabooClient

final class VPNConfigurationTests: XCTestCase {
    
    private func makeConfig(address: String = "example.com", port: Int = 443, userId: String = "test-uuid") -> VPNConfiguration {
        VPNConfiguration(
            id: "test-id",
            name: "Test",
            originalURL: "vless://test",
            serverAddress: address,
            serverPort: port,
            userId: userId,
            encryption: "none",
            transport: .tcp,
            protocol: .vless(reality: .init(
                publicKey: "key",
                serverName: "sni.com",
                fingerprint: "chrome",
                shortId: "",
                spiderX: nil,
                mldsa65Verify: nil
            ))
        )
    }
    
    func testValidConfig_isValid() {
        let config = makeConfig()
        XCTAssertTrue(config.isValid)
    }
    
    func testPort1_isValid() {
        let config = makeConfig(port: 1)
        XCTAssertTrue(config.isValid)
    }
    
    func testPort65535_isValid() {
        let config = makeConfig(port: 65535)
        XCTAssertTrue(config.isValid)
    }
    
    func testPort0_isInvalid() {
        let config = makeConfig(port: 0)
        XCTAssertFalse(config.isValid)
    }
    
    func testPort65536_isInvalid() {
        let config = makeConfig(port: 65536)
        XCTAssertFalse(config.isValid)
    }
    
    func testNegativePort_isInvalid() {
        let config = makeConfig(port: -1)
        XCTAssertFalse(config.isValid)
    }
    
    func testEmptyAddress_isInvalid() {
        let config = makeConfig(address: "")
        XCTAssertFalse(config.isValid)
    }
    
    func testEmptyUserId_isInvalid() {
        let config = makeConfig(userId: "")
        XCTAssertFalse(config.isValid)
    }
}
