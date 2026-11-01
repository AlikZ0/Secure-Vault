import Foundation

enum PasswordGenerator {
    private static let lowercase = Array("abcdefghjkmnpqrstuvwxyz")
    private static let uppercase = Array("ABCDEFGHJKMNPQRSTUVWXYZ")
    private static let digits = Array("23456789")
    private static let symbols = Array("!@#$%^&*-_+=?")

    static func generate(length: Int = 20) -> String {
        let size = max(12, min(64, length))
        let groups = [lowercase, uppercase, digits, symbols]
        let pool = groups.flatMap { $0 }
        var random = SystemRandomNumberGenerator()
        var result: [Character] = []

        // Guarantee one character from each category.
        for group in groups {
            if let value = group.randomElement(using: &random) {
                result.append(value)
            }
        }
        while result.count < size {
            if let value = pool.randomElement(using: &random) {
                result.append(value)
            }
        }
        result.shuffle(using: &random)
        return String(result)
    }
}
