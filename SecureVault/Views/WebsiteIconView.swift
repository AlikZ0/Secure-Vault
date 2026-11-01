import SwiftUI

struct WebsiteIconView: View {
    let item: VaultItem
    var size: CGFloat = 44
    var cornerRadius: CGFloat = 14

    private var faviconURL: URL? {
        guard let host = item.displayHost else { return nil }
        return URL(string: "https://www.google.com/s2/favicons?sz=128&domain_url=\(host)")
    }

    var body: some View {
        Group {
            if let faviconURL {
                AsyncImage(url: faviconURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .padding(size * 0.2)
                            .frame(width: size, height: size)
                            .background(iconBackground)
                    default:
                        fallback
                    }
                }
            } else {
                fallback
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    private var fallback: some View {
        ZStack {
            iconBackground
            Image(systemName: item.resolvedURL == nil ? "key.fill" : "globe")
                .font(.system(size: size * 0.42, weight: .medium))
                .foregroundStyle(VaultTheme.accent)
        }
        .frame(width: size, height: size)
    }

    private var iconBackground: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(VaultTheme.accent.opacity(0.12))
    }
}
