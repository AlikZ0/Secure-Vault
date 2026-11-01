import SwiftUI

struct LockView: View {
    @ObservedObject var vault: VaultViewModel
    @Environment(\.scenePhase) private var scenePhase
    @State private var method: DeviceAuthentication.Method = .passcode

    var body: some View {
        ZStack {
            VaultBackground()
            VStack(spacing: 0) {
                Spacer(minLength: 28)

                Image("LaunchMark")
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(width: 136, height: 136)
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                    .overlay(alignment: .bottomTrailing) {
                        if vault.isUnlocking {
                            ProgressView()
                                .tint(VaultTheme.accent)
                                .padding(10)
                                .background(.regularMaterial, in: Circle())
                        }
                    }
                    .accessibilityHidden(true)
                    .padding(.bottom, 30)

                Text("Secure Vault")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                Text("Ваши пароли остаются только на iPhone")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 9)
                    .padding(.horizontal, 30)

                Spacer().frame(height: 44)

                Button(action: vault.unlock) {
                    HStack(spacing: 12) {
                        if vault.isUnlocking {
                            ProgressView().tint(.white)
                        } else {
                            Image(systemName: method.symbol)
                                .font(.system(size: 21, weight: .medium))
                        }
                        Text(vault.isUnlocking ? "Проверяем доступ…" : method.buttonTitle)
                            .font(.system(size: 16, weight: .semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.82)
                    }
                    .frame(maxWidth: .infinity, minHeight: 58)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white)
                .background(VaultTheme.accent, in: RoundedRectangle(cornerRadius: 18))
                .disabled(vault.isUnlocking)
                .opacity(vault.isUnlocking ? 0.82 : 1)
                .accessibilityLabel(vault.isUnlocking ? "Идёт проверка личности" : method.buttonTitle)
                .padding(.horizontal, 24)

                if let error = vault.errorMessage {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                        .padding(.top, 16)
                        .accessibilityAddTraits(.updatesFrequently)
                } else {
                    Text(vault.isUnlocking ? "Подтвердите вход в системном окне iOS" : method.detail)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 16)
                        .padding(.horizontal, 24)
                }

                Spacer(minLength: 28)

                Label("AES-256-GCM · Без аккаунта и облака", systemImage: "checkmark.shield")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 28)
            }
        }
        .sensoryFeedback(.success, trigger: vault.isUnlocked)
        .onAppear {
            method = DeviceAuthentication.method()
            attemptAutomaticUnlock()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                method = DeviceAuthentication.method()
                attemptAutomaticUnlock()
            }
        }
    }

    private func attemptAutomaticUnlock() {
        // Automatic once on fresh launch / foreground; manual Lock stays locked.
        guard scenePhase == .active, vault.shouldAutoUnlock else { return }
        vault.unlock()
    }
}
