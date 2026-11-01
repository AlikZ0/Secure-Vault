import CryptoKit
import Foundation
import LocalAuthentication
import Security

enum KeychainService {
    enum KeychainError: LocalizedError {
        case passcodeRequired
        case lostKey
        case unexpectedKeyData
        case osStatus(OSStatus)
        case accessControlCreation

        var errorDescription: String? {
            switch self {
            case .passcodeRequired:
                return "Установите код-пароль iPhone в настройках, затем повторите попытку."
            case .lostKey:
                return "Найден зашифрованный файл, но ключ отсутствует в Keychain. Восстановить данные без исходного ключа невозможно."
            case .unexpectedKeyData:
                return "Повреждён ключ шифрования в Keychain."
            case .osStatus(let status):
                if status == errSecUserCanceled || status == errSecAuthFailed {
                    return "Разблокировка отменена или не пройдена."
                }
                return "Ошибка Keychain (код \(status))."
            case .accessControlCreation:
                return "Не удалось настроить защиту ключа."
            }
        }
    }

    private static let service = "SecureVault.LocalEncryptionKey"
    private static let account = "master-key-v1"

    /// This device-only key requires user presence whenever fetched from Keychain.
    /// Do not replace it when the encrypted database already exists.
    static func unlockKey(using context: LAContext, encryptedStoreExists: Bool) throws -> SymmetricKey {
        // The same, already authenticated context avoids another system prompt.
        // Never replace a key that protects existing encrypted data.

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecUseAuthenticationContext as String: context,
            kSecUseOperationPrompt as String: "Подтвердите доступ к Secure Vault"
        ]

        var result: CFTypeRef?
        let initialStatus = SecItemCopyMatching(query as CFDictionary, &result)
        if initialStatus == errSecSuccess {
            return try decodeKey(result)
        }
        guard initialStatus == errSecItemNotFound else {
            throw KeychainError.osStatus(initialStatus)
        }
        guard !encryptedStoreExists else {
            throw KeychainError.lostKey
        }

        let key = SymmetricKey(size: .bits256)
        let data = key.withUnsafeBytes { Data($0) }
        var accessControlError: Unmanaged<CFError>?
        guard let control = SecAccessControlCreateWithFlags(
            nil,
            kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
            .userPresence,
            &accessControlError
        ) else {
            throw KeychainError.accessControlCreation
        }

        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessControl as String: control,
            kSecAttrSynchronizable as String: false
        ]
        let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
        if addStatus == errSecDuplicateItem {
            // Another unlock may have created it. Use the existing key; never overwrite.
            result = nil
            let retryStatus = SecItemCopyMatching(query as CFDictionary, &result)
            guard retryStatus == errSecSuccess else { throw KeychainError.osStatus(retryStatus) }
            return try decodeKey(result)
        }
        guard addStatus == errSecSuccess else { throw KeychainError.osStatus(addStatus) }
        // Require biometric/passcode approval on the first launch as well.
        result = nil
        let verifyStatus = SecItemCopyMatching(query as CFDictionary, &result)
        guard verifyStatus == errSecSuccess else { throw KeychainError.osStatus(verifyStatus) }
        return try decodeKey(result)
    }

    private static func decodeKey(_ value: CFTypeRef?) throws -> SymmetricKey {
        guard let data = value as? Data, data.count == 32 else {
            throw KeychainError.unexpectedKeyData
        }
        return SymmetricKey(data: data)
    }
}
