import SwiftUI

struct LockView: View {
    @ObservedObject var vault: VaultViewModel
    @Environment(\.scenePhase) private var scenePhase
    @State private var method: DeviceAuthentication.Method = .passcode

    var body: some View {
        ZStack {
            VaultBackground()
            VStack(spacing: 20) {
                Spacer(minLength: 30)

                ZStack {
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .frame(width: 148, height: 148)
                        .overlay(
                            RoundedRectangle(cornerRadius: 32, style: .continuous)
                                .stroke(VaultTheme.accent.opacity(0.25), lineWidth: 1)
                        )
                    Image("LaunchMark")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 27, style: .continuous))
                        .shadow(color: VaultTheme.accent.opacity(0.15), radius: 18, y: 10)
                }
                .overlay(alignment: .bottomTrailing) {
                    if vault.isUnlocking {
                        ProgressView()
                            .tint(VaultTheme.accent)
                            .padding(10)
                            .background(.regularMaterial, in: Circle())
                    }
                }

                VStack(spacing: 10) {
                    Text("Secure Vault")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                    Text("Локальный сейф для паролей. Face ID, Touch ID или код устройства — в зависимости от того, что доступно на iPhone.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                VStack(spacing: 12) {
                    HStack(spacing: 10) {
                        chip("Локально", system: "iphone")
                        chip("AES-256", system: "lock.shield")
                        chip("Без облака", system: "icloud.slash")
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 20)

                Spacer(minLength: 18)

                VStack(spacing: 14) {
                    Button(action: vault.unlock) {
                        HStack(spacing: 12) {
                            if vault.isUnlocking {
                                ProgressView().tint(.white)
                            } else {
                                Image(systemName: method.symbol)
                                    .font(.system(size: 20, weight: .medium))
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

                    if let error = vault.errorMessage {
                        Label(error, systemImage: "exclamationmark.triangle.fill")
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 4)
                            .accessibilityAddTraits(.updatesFrequently)
                    } else {
                        Text(vault.isUnlocking ? "Подтвердите вход в системном окне iOS" : method.detail)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 10)
                    }
                }
                .padding(.horizontal, 24)

                Spacer(minLength: 18)

                Text("Пароли остаются только на этом устройстве")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 24)
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

    private func chip(_ text: String, system: String) -> some View {
        Label(text, systemImage: system)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.thinMaterial, in: Capsule())
    }

    private func attemptAutomaticUnlock() {
        guard scenePhase == .active, vault.shouldAutoUnlock else { return }
        vault.unlock()
    }
}
