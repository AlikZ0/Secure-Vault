import CryptoKit
import Foundation
import LocalAuthentication

@MainActor
final class VaultViewModel: ObservableObject {
    @Published private(set) var items: [VaultItem] = []
    @Published private(set) var isUnlocked = false
    @Published private(set) var isUnlocking = false
    @Published private(set) var shouldAutoUnlock = true
    @Published var errorMessage: String?

    private var key: SymmetricKey?
    private var unlockGeneration = 0
    private var authenticationContext: LAContext?
    let clipboard = ClipboardService()

    func unlock() {
        guard !isUnlocked && !isUnlocking else { return }
        isUnlocking = true  // Visible progress on the very first tap.
        shouldAutoUnlock = false
        errorMessage = nil
        let attempt = unlockGeneration
        let context = LAContext()
        authenticationContext = context

        Task { [weak self] in
            do {
                // The system prompt starts before any Keychain or file I/O.
                try await DeviceAuthentication.authenticate(using: context)
                guard let self, self.unlockGeneration == attempt else { return }

                // Keychain and disk I/O must not block SwiftUI's main actor.
                let (unlockedKey, loadedItems) = try await Task.detached(priority: .userInitiated) {
                    let repository = try VaultRepository()
                    let unlockedKey = try KeychainService.unlockKey(
                        using: context,
                        encryptedStoreExists: repository.hasEncryptedFile
                    )
                    let loadedItems = try repository.load(using: unlockedKey)
                    if !repository.hasEncryptedFile {
                        try repository.save(loadedItems, using: unlockedKey)
                    }
                    return (unlockedKey, loadedItems)
                }.value

                guard self.unlockGeneration == attempt else { return }
                self.authenticationContext = nil
                self.key = unlockedKey
                self.items = loadedItems.sorted { $0.updatedAt > $1.updatedAt }
                self.isUnlocking = false
                self.isUnlocked = true
            } catch {
                guard let self, self.unlockGeneration == attempt else { return }
                self.authenticationContext = nil
                self.isUnlocking = false
                if !DeviceAuthentication.isUserCancellation(error) {
                    self.errorMessage = DeviceAuthentication.message(for: error)
                }
            }
        }
    }

    func lock(autoUnlockOnNextActivation: Bool = false) {
        unlockGeneration += 1
        authenticationContext?.invalidate() // Cancels any in-flight authentication.
        authenticationContext = nil
        key = nil
        items.removeAll()
        isUnlocked = false
        isUnlocking = false
        shouldAutoUnlock = autoUnlockOnNextActivation
        errorMessage = nil
        clipboard.forgetTracking()
    }

    @discardableResult
    func upsert(_ item: VaultItem) -> Bool {
        guard let key, isUnlocked else { return false }
        var next = items
        if let index = next.firstIndex(where: { $0.id == item.id }) {
            next[index] = item
        } else {
            next.append(item)
        }
        return persist(next, key: key)
    }

    @discardableResult
    func delete(_ id: UUID) -> Bool {
        guard let key, isUnlocked else { return false }
        return persist(items.filter { $0.id != id }, key: key)
    }

    private func persist(_ next: [VaultItem], key: SymmetricKey) -> Bool {
        do {
            try VaultRepository().save(next, using: key)
            items = next.sorted { $0.updatedAt > $1.updatedAt }
            return true
        } catch {
            errorMessage = "Не удалось сохранить изменения: \(error.localizedDescription)"
            return false
        }
    }
}
