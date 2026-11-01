import CryptoKit
import XCTest
@testable import SecureVault

final class SecureVaultTests: XCTestCase {
    func testEncryptedRoundTrip() throws {
        let key = SymmetricKey(size: .bits256)
        let original = VaultItem(title: "Банк", username: "example", password: "Secret-123!", notes: "Личное")
        let encrypted = try CryptoService.encrypt([original], with: key)
        let decrypted = try CryptoService.decrypt(encrypted, with: key)
        XCTAssertEqual(decrypted, [original])
        XCTAssertFalse(encrypted.range(of: Data("Secret-123!".utf8)) != nil)
        XCTAssertFalse(encrypted.range(of: Data("Банк".utf8)) != nil)
    }

    func testWrongKeyFailsAuthentication() throws {
        let encrypted = try CryptoService.encrypt(
            [VaultItem(title: "test", password: "private")],
            with: SymmetricKey(size: .bits256)
        )
        XCTAssertThrowsError(try CryptoService.decrypt(encrypted, with: SymmetricKey(size: .bits256)))
    }

    func testTamperingFailsAuthentication() throws {
        let key = SymmetricKey(size: .bits256)
        var encrypted = try CryptoService.encrypt([VaultItem(title: "x", password: "y")], with: key)
        encrypted[encrypted.index(before: encrypted.endIndex)] ^= 0x01
        XCTAssertThrowsError(try CryptoService.decrypt(encrypted, with: key))
    }

    func testPasswordGeneratorHasAllGroups() {
        let result = PasswordGenerator.generate(length: 20)
        XCTAssertEqual(result.count, 20)
        XCTAssertTrue(result.contains(where: { $0.isLowercase }))
        XCTAssertTrue(result.contains(where: { $0.isUppercase }))
        XCTAssertTrue(result.contains(where: { $0.isNumber }))
        XCTAssertTrue(result.contains(where: { "!@#$%^&*-_+=?".contains($0) }))
    }
}
