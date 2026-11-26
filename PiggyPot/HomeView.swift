import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: Store
    @Environment(\.themeColor) private var theme

    @State private var showAdd = false
    @State private var selectedWallet: Wallet?
    @State private var showAll = false
    @State private var showAccounts = false

    private var recent: [Entry] { Array(store.entries.prefix(6)) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    totalCard

                    if store.enabledWallets.isEmpty {
                        emptyWallets
                    } else {
                        walletsGrid
                    }

                    BlockTitle(title: "最近记录",
                               trailing: store.entries.isEmpty ? nil : "共 \(store.entries.count) 笔")
                    recentCard
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("钱迹")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAdd = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(width: 30, height: 30)
                            .background(theme, in: Circle())
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                }
            }
            .sheet(isPresented: $showAdd) {
                AddEntryView()
                    .environmentObject(store)
            }
            .navigationDestination(item: $selectedWallet) { wallet in
                HistoryView(wallet: wallet)
                    .environmentObject(store)
            }
            .navigationDestination(isPresented: $showAll) {
                HistoryView(wallet: nil)
                    .environmentObject(store)
            }
            .navigationDestination(isPresented: $showAccounts) {
                AccountsView()
                    .environmentObject(store)
            }
        }
    }

    // MARK: - 总资产

    private var totalCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("总资产")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(store.enabledWallets.count) 个账户")
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)
            }

            Text(Money.text(store.totalCents))
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .monospacedDigit()
                .minimumScaleFactor(0.5)
                .lineLimit(1)

            HStack(spacing: 22) {
                stat("本月收入", Money.text(store.monthIncomeCents), .green)
                stat("本月支出", Money.text(store.monthExpenseCents), .red)
            }
        }
        .card(padding: 18)
    }

    private func stat(_ title: String, _ value: String, _ tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(tint)
        }
    }

    // MARK: - 账户

    private var emptyWallets: some View {
        VStack(spacing: 10) {
            Image(systemName: "wallet.pass")
                .font(.system(size: 30, weight: .light))
                .foregroundStyle(.tertiary)
            Text("还没有开启账户")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.secondary)
            Text("支付宝、微信、银行卡、现金默认是关的，\n开哪个就显示哪个。")
                .font(.system(size: 13))
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)

            Button {
                showAccounts = true
            } label: {
                Text("去开启")
                    .font(.system(size: 14, weight: .medium))
                    .padding(.horizontal, 20)
                    .frame(height: 36)
                    .background(theme, in: Capsule())
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .card()
    }

    private var walletsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 10),
                            GridItem(.flexible(), spacing: 10)],
                  spacing: 10) {
            ForEach(store.enabledWallets) { wallet in
                Button {
                    selectedWallet = wallet
                } label: {
                    walletCard(wallet)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func walletCard(_ wallet: Wallet) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 7) {
                WalletBadge(wallet: wallet, size: 22)
                Text(wallet.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            Text(Money.text(store.balance(wallet.id)))
                .font(.system(size: 19, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.primary)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card(padding: 14, corner: 18)
    }

    // MARK: - 最近记录

    private var recentCard: some View {
        VStack(spacing: 0) {
            if recent.isEmpty {
                EmptyHint(symbol: "tray", title: "还没有记录", detail: "点右上角的 + 记一笔")
            } else {
                ForEach(Array(recent.enumerated()), id: \.element.id) { index, entry in
                    EntryRow(entry: entry, wallet: store.wallet(entry.walletID))
                    if index < recent.count - 1 {
                        Divider().padding(.leading, 44)
                    }
                }
                if store.entries.count > recent.count {
                    Divider()
                    Button {
                        showAll = true
                    } label: {
                        HStack {
                            Text("全部记录")
                                .font(.system(size: 15))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.tertiary)
                        }
                        .foregroundStyle(theme)
                        .padding(.vertical, 12)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .card(padding: 16)
    }
}
