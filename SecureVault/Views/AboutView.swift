import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(ClipboardService.timeoutKey) private var clipboardTimeout = ClipboardService.fallbackTimeout

    private let timeoutOptions: [TimeInterval] = [30, 60, 120, 300, 600]

    var body: some View {
        NavigationStack {
            Form {
                Section("Защита") {
                    Label("Шифрование AES-256-GCM", systemImage: "lock.shield")
                    Label("Face ID, Touch ID или код устройства", systemImage: "faceid")
                    Label("Блокировка при переходе в фон", systemImage: "hand.raised")
                }

                Section("Буфер обмена") {
                    Picker("Хранить скопированный пароль", selection: $clipboardTimeout) {
                        ForEach(timeoutOptions, id: \.self) { option in
                            Text(timeoutLabel(option)).tag(option)
                        }
                    }
                    .pickerStyle(.navigationLink)

                    Label("Передача на другие устройства отключена", systemImage: "iphone.slash")
                    Text("После истечения времени iOS сама удалит скопированное значение. При желании его можно очистить вручную раньше.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section {
                    Text("Приложение не отправляет пароли на сервер. Данные хранятся только на этом iPhone, не синхронизируются и не имеют функции восстановления. Если удалить приложение, отключить код-пароль или потерять ключ Keychain, данные можно утратить безвозвратно.")
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Хранение")
                }
            }
            .navigationTitle("Настройки и защита")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") { dismiss() }
                }
            }
        }
    }

    private func timeoutLabel(_ seconds: TimeInterval) -> String {
        switch Int(seconds) {
        case 30: return "30 секунд"
        case 60: return "1 минута"
        case 120: return "2 минуты"
        case 300: return "5 минут"
        case 600: return "10 минут"
        default: return "\(Int(seconds)) сек."
        }
    }
}
