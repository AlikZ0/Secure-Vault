import SwiftUI

@main
struct SecureVaultApp: App {
    @StateObject private var vault = VaultViewModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ZStack {
                if vault.isUnlocked {
                    VaultHomeView(vault: vault)
                } else {
                    LockView(vault: vault)
                }

                if scenePhase != .active && vault.isUnlocked {
                    PrivacyShieldView()
                        .ignoresSafeArea()
                        .zIndex(100)
                        .accessibilityHidden(true)
                }
            }
            .privacySensitive()
            .alert(
                "Ошибка",
                isPresented: Binding(
                    get: { vault.isUnlocked && vault.errorMessage != nil },
                    set: { if !$0 { vault.errorMessage = nil } }
                )
            ) {
                Button("Понятно", role: .cancel) { vault.errorMessage = nil }
            } message: {
                Text(vault.errorMessage ?? "Неизвестная ошибка")
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .background {
                    vault.lock(autoUnlockOnNextActivation: true)
                }
            }
        }
    }
}
