import Foundation
import UIKit

@MainActor
final class ClipboardService {
    static let timeout: TimeInterval = 60
    private var ownedChangeCount: Int?

    /// Never reads another app's clipboard. iOS removes our copied value at expiry.
    func copy(_ value: String) {
        UIPasteboard.general.setItems(
            [["public.utf8-plain-text": value]],
            options: [
                .localOnly: true,
                .expirationDate: Date().addingTimeInterval(Self.timeout) as NSDate
            ]
        )
        ownedChangeCount = UIPasteboard.general.changeCount
    }

    /// Does not erase clipboard contents if another app has copied something since us.
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
