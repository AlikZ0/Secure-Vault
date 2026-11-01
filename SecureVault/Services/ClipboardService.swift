import Foundation
import UIKit

@MainActor
final class ClipboardService {
    static let timeoutKey = "clipboard.timeout.seconds"
    static let fallbackTimeout: TimeInterval = 60
    private var ownedChangeCount: Int?

    static var configuredTimeout: TimeInterval {
        let stored = UserDefaults.standard.double(forKey: timeoutKey)
        return stored > 0 ? stored : fallbackTimeout
    }

    static func saveTimeout(_ seconds: TimeInterval) {
        UserDefaults.standard.set(seconds, forKey: timeoutKey)
    }

    func copy(_ value: String, expiresIn: TimeInterval? = nil) {
        let duration = max(10, expiresIn ?? Self.configuredTimeout)
        UIPasteboard.general.setItems(
            [["public.utf8-plain-text": value]],
            options: [
                .localOnly: true,
                .expirationDate: Date().addingTimeInterval(duration) as NSDate
            ]
        )
        ownedChangeCount = UIPasteboard.general.changeCount
    }

    @discardableResult
    func clearIfUnchanged() -> Bool {
        guard let count = ownedChangeCount else { return false }
        ownedChangeCount = nil
        guard UIPasteboard.general.changeCount == count else { return false }
        UIPasteboard.general.items = []
        return true
    }

    func forgetTracking() {
        ownedChangeCount = nil
    }
}
