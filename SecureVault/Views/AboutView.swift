import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Защита") {
                    Label("Шифрование AES-256-GCM", systemImage: "lock.shield")
                    Label("Ключ защищён Keychain и кодом устройства", systemImage: "faceid")
                    Label("Блокировка при переходе в фон", systemImage: "hand.raised")
                }
                Section("Буфер обмена") {
                    Label("Срок действия копии: 60 секунд", systemImage: "timer")
                    Label("Передача на другие устройства отключена", systemImage: "iphone.slash")
                }
                Section {
                    Text("Приложение не отправляет пароли на сервер. Данные хранятся на этом iPhone, не синхронизируются и не имеют функции восстановления. Если удалить приложение, отключить код-пароль или потерять ключ Keychain, данные можно утратить безвозвратно.")
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Хранение")
                }
            }
            .navigationTitle("О безопасности")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") { dismiss() }
                }
            }
        }
    }
}
