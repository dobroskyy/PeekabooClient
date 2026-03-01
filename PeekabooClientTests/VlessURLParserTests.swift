import XCTest
@testable import PeekabooClient

final class VlessURLParserTests: XCTestCase {
    
    func testValidURL_parsesAllFieldsCorrectly() throws {
        let url = "vless://a1b2c3d4-e5f6-7890-abcd-ef1234567890@example.com:443?security=reality&type=xhttp&mode=auto&sni=fake-sni.com&fp=chrome&pbk=testPublicKey123&sid=abcd#TestServer"
        
        let result = try VlessURLParser.parse(url)
        
        XCTAssertEqual(result.serverAddress, "example.com")
        XCTAssertEqual(result.serverPort, 443)
        XCTAssertEqual(result.userId, "a1b2c3d4-e5f6-7890-abcd-ef1234567890")
        XCTAssertEqual(result.transport, .xhttp)
        XCTAssertEqual(result.encryption, "none")
        XCTAssertEqual(result.name, "TestServer")
        
        guard case .vless(let reality) = result.protocol else {
            XCTFail("Expected VLESS protocol")
            return
        }
        XCTAssertEqual(reality.publicKey, "testPublicKey123")
        XCTAssertEqual(reality.serverName, "fake-sni.com")
        XCTAssertEqual(reality.fingerprint, "chrome")
        XCTAssertEqual(reality.shortId, "abcd")
    }
    
    func testInvalidURL_throwsInvalidURL() {
          XCTAssertThrowsError(try VlessURLParser.parse("vless://host:port\n\n")) { error in
              XCTAssertEqual(error as? VlessParserError, .invalidURL)
          }
      }
    
    func testHTTPScheme_throwsInvalidScheme() {
        XCTAssertThrowsError(try VlessURLParser.parse("https://example.com:443")) { error in
            XCTAssertEqual(error as? VlessParserError, .invalidScheme)
        }
    }
    
    func testMissingUserId_throwsMissingUserId() {
        XCTAssertThrowsError(try VlessURLParser.parse("vless://@example.com:443?security=reality&pbk=key&sni=sni.com&fp=chrome")) { error in
            XCTAssertEqual(error as? VlessParserError, .missingUserId)
        }
    }
    
    func testMissingServer_throwsMissingServer() {
        XCTAssertThrowsError(try VlessURLParser.parse("vless://some-uuid@:443?security=reality&pbk=key&sni=sni.com&fp=chrome")) { error in
            XCTAssertEqual(error as? VlessParserError, .missingServer)
        }
    }
    
    func testMissingPort_throwsInvalidPort() {
        XCTAssertThrowsError(try VlessURLParser.parse("vless://some-uuid@example.com?security=reality&pbk=key&sni=sni.com&fp=chrome")) { error in
            XCTAssertEqual(error as? VlessParserError, .invalidPort)
        }
    }
    
    func testNoQueryParams_throwsMissingQueryParameters() {
        XCTAssertThrowsError(try VlessURLParser.parse("vless://some-uuid@example.com:443")) { error in
            XCTAssertEqual(error as? VlessParserError, .missingQueryParameters)
        }
    }
    
    func testMissingPublicKey_throwsInvalidRealityParameters() {
        XCTAssertThrowsError(try VlessURLParser.parse("vless://some-uuid@example.com:443?security=reality&sni=sni.com&fp=chrome")) { error in
            XCTAssertEqual(error as? VlessParserError, .invalidRealityParameters)
        }
    }
    
    func testMissingSNI_throwsInvalidRealityParameters() {
        XCTAssertThrowsError(try VlessURLParser.parse("vless://some-uuid@example.com:443?security=reality&pbk=key&fp=chrome")) { error in
            XCTAssertEqual(error as? VlessParserError, .invalidRealityParameters)
        }
    }
    
    func testMissingFingerprint_throwsInvalidRealityParameters() {
        XCTAssertThrowsError(try VlessURLParser.parse("vless://some-uuid@example.com:443?security=reality&pbk=key&sni=sni.com")) { error in
            XCTAssertEqual(error as? VlessParserError, .invalidRealityParameters)
        }
    }
}
    
