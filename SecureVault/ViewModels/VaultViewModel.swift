import CryptoKit
import Foundation

@MainActor
final class VaultViewModel: ObservableObject {
    @Published private(set) var items: [VaultItem] = []
    @Published private(set) var isUnlocked = false
    @Published private(set) var isUnlocking = false
    @Published var errorMessage: String?

    private var key: SymmetricKey?
    private var unlockGeneration = 0
    let clipboard = ClipboardService()

    func unlock() {
        guard !isUnlocked && !isUnlocking else { return }
        isUnlocking = true
        errorMessage = nil
        let attempt = unlockGeneration

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let result: Result<(SymmetricKey, [VaultItem]), Error> = Result {
                let repo = try VaultRepository()
                let key = try KeychainService.unlockKey(encryptedStoreExists: repo.hasEncryptedFile)
                let items = try repo.load(using: key)
                if !repo.hasEncryptedFile {
                    try repo.save(items, using: key)
                }
                return (key, items)
            }
            DispatchQueue.main.async { [weak self] in
                guard let self, self.unlockGeneration == attempt else { return }
                self.isUnlocking = false
                switch result {
                case .success(let (key, items)):
                    self.key = key
                    self.items = items.sorted { $0.updatedAt > $1.updatedAt }
                    self.isUnlocked = true
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func lock() {
        unlockGeneration += 1
        key = nil
        items.removeAll()
        isUnlocked = false
        isUnlocking = false
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
