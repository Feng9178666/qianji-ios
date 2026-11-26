import SwiftUI

struct AccountsView: View {
    @EnvironmentObject private var store: Store
    @Environment(\.themeColor) private var theme

    @State private var editing: Wallet?
    @State private var showNew = false
    @State private var editMode: EditMode = .inactive

    var body: some View {
        List {
            Section {
                ForEach(store.wallets) { wallet in
                    HStack(spacing: 12) {
                        HStack(spacing: 12) {
                            WalletBadge(wallet: wallet, size: 32)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(wallet.name)
                                    .font(.system(size: 16))
                                Text("\(Money.text(store.balance(wallet.id))) · \(countText(wallet))")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer(minLength: 8)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            editing = wallet
                        }

                        Toggle("", isOn: Binding(
                            get: { wallet.isEnabled },
                            set: { _ in store.toggleWallet(wallet) }
                        ))
                        .labelsHidden()
                        .tint(theme)
                    }
                    .padding(.vertical, 2)
                }
                .onDelete(perform: delete)
                .onMove(perform: store.moveWallets)
            } header: {
                Text("账户")
            } footer: {
                Text("打开开关才会出现在首页和记账里。关掉只是隐藏，记录不会丢。")
            }

            Section {
                Button {
                    showNew = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "plus")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(theme)
                            .frame(width: 29, height: 29)
                            .background(theme.opacity(0.12), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                        Text("新增账户")
                            .font(.system(size: 17))
                            .foregroundStyle(.primary)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .environment(\.editMode, $editMode)
        .navigationTitle("账户管理")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(editMode.isEditing ? "完成" : "编辑") {
                    withAnimation {
                        editMode = editMode.isEditing ? .inactive : .active
                    }
                }
            }
        }
        .sheet(item: $editing) { wallet in
            AccountEditorView(wallet: wallet)
                .environmentObject(store)
        }
        .sheet(isPresented: $showNew) {
            AccountEditorView(wallet: nil)
                .environmentObject(store)
        }
    }

    private func countText(_ wallet: Wallet) -> String {
        let count = store.entries(for: wallet.id).count
        return "\(count) 笔记录"
    }

    private func delete(_ offsets: IndexSet) {
        for index in offsets {
            store.deleteWallet(store.wallets[index])
        }
    }
}
