import SwiftUI

struct ItemDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var vault: VaultViewModel
    let itemID: UUID

    @State private var isPasswordVisible = false
    @State private var isEditing = false
    @State private var showingDeleteAlert = false
    @State private var copiedMessage: String?
    @AppStorage(ClipboardService.timeoutKey) private var clipboardTimeout = ClipboardService.fallbackTimeout

    private var item: VaultItem? {
        vault.items.first(where: { $0.id == itemID })
    }

    private var shareText: String {
        guard let item else { return "" }
        var lines = [item.title]
        if let host = item.displayHost { lines.append("Сайт: \(host)") }
        if !item.username.isEmpty { lines.append("Логин: \(item.username)") }
        lines.append("Пароль: \(item.password)")
        if !item.notes.isEmpty { lines.append("Заметка: \(item.notes)") }
        return lines.joined(separator: "\n")
    }

    var body: some View {
        NavigationStack {
            Group {
                if let item {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            VStack(spacing: 12) {
                                WebsiteIconView(item: item, size: 82, cornerRadius: 24)
                                Text(item.title)
                                    .font(.title2.bold())
                                    .multilineTextAlignment(.center)
                                if let host = item.displayHost {
                                    Label(host, systemImage: "globe")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                Text("Обновлено \(item.updatedAt.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 20)

                            if let host = item.displayHost {
                                fieldCard(label: "САЙТ", value: host) {
                                    copy(host)
                                }
                            }

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

                            VaultCard {
                                VStack(alignment: .leading, spacing: 10) {
                                    Label("Поделиться записью", systemImage: "square.and.arrow.up")
                                        .font(.headline)
                                    Text("Поделится названием, сайтом, логином, паролем и заметкой этой записи.")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    ShareLink(item: shareText) {
                                        Label("Открыть меню “Поделиться”", systemImage: "square.and.arrow.up")
                                            .frame(maxWidth: .infinity)
                                    }
                                    .buttonStyle(.borderedProminent)
                                }
                            }

                            if let copiedMessage {
                                VStack(alignment: .leading, spacing: 12) {
                                    Label(copiedMessage, systemImage: "checkmark.circle.fill")
                                        .font(.subheadline)
                                        .foregroundStyle(.green)
                                    Text("Буфер будет очищен системой через \(timeoutLabel(clipboardTimeout)). Вы также можете очистить его сейчас.")
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
                ToolbarItemGroup(placement: .topBarTrailing) {
                    if let item {
                        ShareLink(item: shareText) {
                            Image(systemName: "square.and.arrow.up")
                        }
                        .accessibilityLabel("Поделиться записью")
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
                    .accessibilityLabel("Скопировать \(label.lowercased())")
                }
            }
        }
    }

    private func timeoutLabel(_ seconds: TimeInterval) -> String {
        switch Int(seconds) {
        case 30: return "30 секунд"
        case 60: return "1 минуту"
        case 120: return "2 минуты"
        case 300: return "5 минут"
        case 600: return "10 минут"
        default: return "\(Int(seconds)) сек."
        }
    }

    private func copy(_ text: String) {
        vault.clipboard.copy(text)
        copiedMessage = "Скопировано"
    }
}
