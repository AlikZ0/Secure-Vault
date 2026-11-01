import CryptoKit
import Foundation

struct VaultRepository {
    private let fileURL: URL

    init() throws {
        let fileManager = FileManager.default
        var directory = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        // The encryption key is device-only: backing up this ciphertext to another
        // device would produce an unrestorable vault, so exclude this directory.
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try directory.setResourceValues(values)
        fileURL = directory.appendingPathComponent("vault.v1.enc", isDirectory: false)
    }

    var hasEncryptedFile: Bool {
        FileManager.default.fileExists(atPath: fileURL.path)
    }

    func load(using key: SymmetricKey) throws -> [VaultItem] {
        guard hasEncryptedFile else { return [] }
        let encrypted = try Data(contentsOf: fileURL)
        return try CryptoService.decrypt(encrypted, with: key)
    }

    func save(_ items: [VaultItem], using key: SymmetricKey) throws {
        let encrypted = try CryptoService.encrypt(items, with: key)
        try encrypted.write(to: fileURL, options: [.atomic, .completeFileProtection])
    }
}
