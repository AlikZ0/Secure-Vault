import SwiftUI

enum VaultTheme {
    static let accent = Color(red: 0.36, green: 0.62, blue: 0.98)
    static let textSecondary = Color.secondary
}

struct VaultBackground: View {
    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground)
            GeometryReader { geometry in
                Circle()
                    .fill(VaultTheme.accent.opacity(0.12))
                    .frame(width: 320, height: 320)
                    .blur(radius: 90)
                    .position(x: geometry.size.width * 0.95, y: 50)
                Circle()
                    .fill(Color.indigo.opacity(0.07))
                    .frame(width: 290, height: 290)
                    .blur(radius: 100)
                    .position(x: 0, y: geometry.size.height * 0.85)
            }
        }
        .ignoresSafeArea()
    }
}

struct PrivacyShieldView: View {
    var body: some View {
        ZStack {
            Color(uiColor: .systemBackground)
            VStack(spacing: 12) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 48, weight: .medium))
                    .foregroundStyle(VaultTheme.accent)
                Text("Secure Vault")
                    .font(.headline)
            }
        }
    }
}

struct VaultCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}
