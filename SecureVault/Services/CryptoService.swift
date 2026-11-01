import CryptoKit
import Foundation

enum CryptoService {
    enum CryptoError: LocalizedError {
        case combinedDataUnavailable

        var errorDescription: String? {
            "Не удалось сформировать зашифрованный файл."
        }
    }

    static func encrypt(_ items: [VaultItem], with key: SymmetricKey) throws -> Data {
        let plaintext = try JSONEncoder().encode(items)
        let sealed = try AES.GCM.seal(plaintext, using: key)
        guard let combined = sealed.combined else {
            throw CryptoError.combinedDataUnavailable
        }
        return combined
    }

    static func decrypt(_ encryptedData: Data, with key: SymmetricKey) throws -> [VaultItem] {
        let sealed = try AES.GCM.SealedBox(combined: encryptedData)
        let plaintext = try AES.GCM.open(sealed, using: key)
        return try JSONDecoder().decode([VaultItem].self, from: plaintext)
    }
}
