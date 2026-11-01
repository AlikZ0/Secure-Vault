import SwiftUI

struct VaultHomeView: View {
    @ObservedObject var vault: VaultViewModel
    @State private var searchText = ""
    @State private var showingAdd = false
    @State private var showingAbout = false
    @State private var selectedItem: VaultItem?

    private var filteredItems: [VaultItem] {
        if searchText.isEmpty { return vault.items }
        return vault.items.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.username.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                VaultBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        summaryCard
                            .padding(.top, 10)
                        if vault.items.isEmpty {
                            emptyState
                        } else if filteredItems.isEmpty {
                            ContentUnavailableView.search(text: searchText)
                                .padding(.top, 34)
                        } else {
                            Text("ЗАПИСИ")
                                .font(.caption.weight(.bold))
                                .tracking(1.7)
                                .foregroundStyle(.secondary)
                                .padding(.top, 12)
                            ForEach(filteredItems) { item in
                                Button { selectedItem = item } label: {
                                    VaultItemRow(item: item)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("Хранилище")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Поиск по названию")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { vault.lock() } label: {
                        Image(systemName: "lock.fill")
                    }
                    .accessibilityLabel("Заблокировать")
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button { showingAbout = true } label: {
                        Image(systemName: "info.circle")
                    }
                    Button { showingAdd = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                    .accessibilityLabel("Добавить запись")
                }
            }
            .sheet(isPresented: $showingAdd) {
                AddEditItemView(vault: vault, existingItem: nil)
            }
            .sheet(item: $selectedItem) { item in
                ItemDetailView(vault: vault, itemID: item.id)
            }
            .sheet(isPresented: $showingAbout) {
                AboutView()
            }
        }
        .tint(VaultTheme.accent)
    }

    private var summaryCard: some View {
        HStack(spacing: 15) {
            Image(systemName: "shield.lefthalf.filled")
                .font(.system(size: 27))
                .foregroundStyle(VaultTheme.accent)
                .frame(width: 52, height: 52)
                .background(VaultTheme.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 15))
            VStack(alignment: .leading, spacing: 4) {
                Text("Сейф разблокирован")
                    .font(.headline)
                Text("\(vault.items.count) \(entryWord(vault.items.count)) · Локальное шифрование")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            Image(systemName: "checkmark.seal.fill")
                .foregroundStyle(.green)
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var emptyState: some View {
        VStack(spacing: 18) {
            Image(systemName: "key.horizontal")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(VaultTheme.accent)
                .padding(20)
                .background(VaultTheme.accent.opacity(0.1), in: Circle())
            Text("Пока нет записей")
                .font(.title3.bold())
            Text("Добавьте первый пароль. Все поля будут зашифрованы перед сохранением.")
                .foregroundStyle(.secondary)
                .font(.subheadline)
                .multilineTextAlignment(.center)
            Button("Добавить пароль") { showingAdd = true }
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
        .padding(.top, 62)
    }

    private func entryWord(_ count: Int) -> String {
        let mod100 = count % 100
        if (11...14).contains(mod100) { return "записей" }
        switch count % 10 {
        case 1: return "запись"
        case 2...4: return "записи"
        default: return "записей"
        }
    }
}

private struct VaultItemRow: View {
    let item: VaultItem

    var body: some View {
        VaultCard {
            HStack(spacing: 14) {
                Image(systemName: "key.fill")
                    .font(.title3)
                    .foregroundStyle(VaultTheme.accent)
                    .frame(width: 46, height: 46)
                    .background(VaultTheme.accent.opacity(0.10), in: RoundedRectangle(cornerRadius: 13))
                VStack(alignment: .leading, spacing: 5) {
                    Text(item.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    Text(item.username.isEmpty ? "Защищённая запись" : item.username)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 6)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
        }
    }
}
