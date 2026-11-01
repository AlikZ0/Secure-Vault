import Foundation

struct VaultItem: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var website: String
    var username: String
    var password: String
    var notes: String
    let createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        website: String = "",
        username: String = "",
        password: String,
        notes: String = "",
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.website = website
        self.username = username
        self.password = password
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    enum CodingKeys: String, CodingKey {
        case id, title, website, username, password, notes, createdAt, updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        self.website = try container.decodeIfPresent(String.self, forKey: .website) ?? ""
        self.username = try container.decodeIfPresent(String.self, forKey: .username) ?? ""
        self.password = try container.decodeIfPresent(String.self, forKey: .password) ?? ""
        self.notes = try container.decodeIfPresent(String.self, forKey: .notes) ?? ""
        self.createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        self.updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? self.createdAt
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(website, forKey: .website)
        try container.encode(username, forKey: .username)
        try container.encode(password, forKey: .password)
        try container.encode(notes, forKey: .notes)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}

extension VaultItem {
    var trimmedWebsite: String {
        website.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var resolvedURL: URL? {
        let raw = trimmedWebsite.isEmpty ? title.trimmingCharacters(in: .whitespacesAndNewlines) : trimmedWebsite
        guard !raw.isEmpty else { return nil }
        if let direct = URL(string: raw), direct.scheme != nil, direct.host != nil {
            return direct
        }
        if let direct = URL(string: "https://\(raw)"), direct.host != nil {
            return direct
        }
        return nil
    }

    var displayHost: String? {
        guard let host = resolvedURL?.host?.lowercased() else { return nil }
        return host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
    }

    var displaySubtitle: String {
        if let host = displayHost, !host.isEmpty { return host }
        if !username.isEmpty { return username }
        return "Защищённая запись"
    }
}
