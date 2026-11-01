import SwiftUI

struct LockView: View {
    @ObservedObject var vault: VaultViewModel

    var body: some View {
        ZStack {
            VaultBackground()
            VStack(spacing: 0) {
                Spacer()
                ZStack {
                    RoundedRectangle(cornerRadius: 34, style: .continuous)
                        .fill(VaultTheme.accent.opacity(0.14))
                        .frame(width: 116, height: 116)
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 56, weight: .medium))
                        .foregroundStyle(VaultTheme.accent)
                }
                .padding(.bottom, 30)

                Text("Secure Vault")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                Text("Ваши пароли остаются только на iPhone")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 10)
                Spacer().frame(height: 54)

                Button(action: vault.unlock) {
                    HStack(spacing: 10) {
                        if vault.isUnlocking {
                            ProgressView().tint(.white)
                        } else {
                            Image(systemName: "faceid")
                        }
                        Text(vault.isUnlocking ? "Разблокировка…" : "Разблокировать")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white)
                .background(VaultTheme.accent, in: RoundedRectangle(cornerRadius: 17))
                .disabled(vault.isUnlocking)
                .padding(.horizontal, 28)

                Text("Face ID, Touch ID или код-пароль устройства")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.top, 18)
                Spacer()
                Label("AES-256-GCM · Без аккаунта и облака", systemImage: "checkmark.shield")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 30)
            }
        }
    }
}
