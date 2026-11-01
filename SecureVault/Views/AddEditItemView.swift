import SwiftUI

struct AddEditItemView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var vault: VaultViewModel
    let existingItem: VaultItem?

    @State private var title: String
    @State private var username: String
    @State private var password: String
    @State private var notes: String
    @State private var passwordVisible = false
    @State private var passwordLength = 20

    init(vault: VaultViewModel, existingItem: VaultItem?) {
        self.vault = vault
        self.existingItem = existingItem
        _title = State(initialValue: existingItem?.title ?? "")
        _username = State(initialValue: existingItem?.username ?? "")
        _password = State(initialValue: existingItem?.password ?? "")
        _notes = State(initialValue: existingItem?.notes ?? "")
    }

    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !password.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Название") {
                    TextField("Например, GitHub", text: $title)
                        .textInputAutocapitalization(.sentences)
                        .autocorrectionDisabled()
                }
                Section("Учётные данные") {
                    TextField("Логин или email (необязательно)", text: $username)
                        .textContentType(.username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.emailAddress)

                    HStack(spacing: 12) {
                        Group {
                            if passwordVisible {
                                TextField("Пароль", text: $password)
                            } else {
                                SecureField("Пароль", text: $password)
                            }
                        }
                        .textContentType(.password)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        Button { passwordVisible.toggle() } label: {
                            Image(systemName: passwordVisible ? "eye.slash" : "eye")
                        }
                        .accessibilityLabel(passwordVisible ? "Скрыть пароль" : "Показать пароль")
                    }
                }

                Section {
                    HStack {
                        Text("Длина пароля")
                        Spacer()
                        Text("\(passwordLength)")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: Binding(
                        get: { Double(passwordLength) },
                        set: { passwordLength = Int($0) }
                    ), in: 12...64, step: 1)
                    Button {
                        password = PasswordGenerator.generate(length: passwordLength)
                        passwordVisible = false
                    } label: {
                        Label("Сгенерировать надёжный пароль", systemImage: "dice.fill")
                    }
                } header: {
                    Text("Генератор")
                } footer: {
                    Text("Буквы, цифры и специальные символы. Генерация полностью локальная.")
                }

                Section("Заметка") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 92)
                        .accessibilityLabel("Заметка")
                }
            }
            .navigationTitle(existingItem == nil ? "Новая запись" : "Редактирование")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") { save() }
                        .fontWeight(.semibold)
                        .disabled(!isValid)
                }
            }
        }
        .tint(VaultTheme.accent)
    }

    private func save() {
        let now = Date()
        let item = VaultItem(
            id: existingItem?.id ?? UUID(),
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            username: username.trimmingCharacters(in: .whitespacesAndNewlines),
            password: password,
            notes: notes,
            createdAt: existingItem?.createdAt ?? now,
            updatedAt: now
        )
        if vault.upsert(item) { dismiss() }
    }
}
