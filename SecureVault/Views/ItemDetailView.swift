import SwiftUI

struct ItemDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var vault: VaultViewModel
    let itemID: UUID

    @State private var isPasswordVisible = false
    @State private var isEditing = false
    @State private var showingDeleteAlert = false
    @State private var copiedMessage: String?

    private var item: VaultItem? {
        vault.items.first(where: { $0.id == itemID })
    }

    var body: some View {
        NavigationStack {
            Group {
                if let item {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            VStack(spacing: 10) {
                                Image(systemName: "key.fill")
                                    .font(.system(size: 30))
                                    .foregroundStyle(VaultTheme.accent)
                                    .frame(width: 74, height: 74)
                                    .background(VaultTheme.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 22))
                                Text(item.title)
                                    .font(.title2.bold())
                                    .multilineTextAlignment(.center)
                                Text("Обновлено \(item.updatedAt.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 20)

                            if !item.username.isEmpty {
                                fieldCard(label: "ЛОГИН", value: item.username) {
                                    copy(item.username)
                                }
                            }

                            VaultCard {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("ПАРОЛЬ")
                                        .font(.caption.weight(.semibold))
                                        .tracking(1.4)
                                        .foregroundStyle(.secondary)
                                    HStack(spacing: 10) {
                                        Group {
                                            if isPasswordVisible {
                                                Text(item.password)
                                                    .textSelection(.enabled)
                                            } else {
                                                Text(String(repeating: "•", count: min(max(item.password.count, 8), 18)))
                                            }
                                        }
                                        .font(.system(.body, design: .monospaced))
                                        .lineLimit(3)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        Button { isPasswordVisible.toggle() } label: {
                                            Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                                        }
                                        .accessibilityLabel(isPasswordVisible ? "Скрыть пароль" : "Показать пароль")
                                        Button { copy(item.password) } label: {
                                            Image(systemName: "doc.on.doc")
                                        }
                                        .accessibilityLabel("Скопировать пароль")
                                    }
                                }
                            }

                            if !item.notes.isEmpty {
                                VaultCard {
                                    VStack(alignment: .leading, spacing: 10) {
                                        Text("ЗАМЕТКА")
                                            .font(.caption.weight(.semibold))
                                            .tracking(1.4)
                                            .foregroundStyle(.secondary)
                                        Text(item.notes)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .textSelection(.enabled)
                                    }
                                }
                            }

                            if let copiedMessage {
                                VStack(alignment: .leading, spacing: 12) {
                                    Label(copiedMessage, systemImage: "checkmark.circle.fill")
                                        .font(.subheadline)
                                        .foregroundStyle(.green)
                                    Text("Буфер будет очищен системой через 60 секунд. Вы также можете очистить его сейчас.")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Button("Очистить скопированное") {
                                        let didClear = vault.clipboard.clearIfUnchanged()
                                        self.copiedMessage = didClear
                                            ? "Буфер очищен"
                                            : "Буфер уже изменён или срок копирования истёк"
                                    }
                                    .font(.subheadline.weight(.semibold))
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(16)
                                .background(Color(uiColor: .secondarySystemGroupedBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            }

                            Button(role: .destructive) {
                                showingDeleteAlert = true
                            } label: {
                                Label("Удалить запись", systemImage: "trash")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .padding(.top, 10)
                        }
                        .padding(20)
                    }
                } else {
                    ContentUnavailableView("Запись не найдена", systemImage: "questionmark.circle")
                }
            }
            .background(VaultBackground())
            .navigationTitle("Запись")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Готово") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if item != nil {
                        Button("Изменить") { isEditing = true }
                    }
                }
            }
            .sheet(isPresented: $isEditing) {
                if let item {
                    AddEditItemView(vault: vault, existingItem: item)
                }
            }
            .confirmationDialog(
                "Удалить запись без возможности восстановления?",
                isPresented: $showingDeleteAlert,
                titleVisibility: .visible
            ) {
                Button("Удалить", role: .destructive) {
                    if vault.delete(itemID) { dismiss() }
                }
            }
        }
        .tint(VaultTheme.accent)
    }

    private func fieldCard(label: String, value: String, copyAction: @escaping () -> Void) -> some View {
        VaultCard {
            VStack(alignment: .leading, spacing: 12) {
                Text(label)
                    .font(.caption.weight(.semibold))
                    .tracking(1.4)
                    .foregroundStyle(.secondary)
                HStack(spacing: 12) {
                    Text(value)
                        .lineLimit(3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                    Button(action: copyAction) {
                        Image(systemName: "doc.on.doc")
                    }
                    .accessibilityLabel("Скопировать логин")
                }
            }
        }
    }

    private func copy(_ text: String) {
        vault.clipboard.copy(text)
        copiedMessage = "Скопировано"
    }
}
