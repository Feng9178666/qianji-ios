import SwiftUI
import UIKit

struct HomeView: View {
    @EnvironmentObject private var store: Store
    @Environment(\.themeColor) private var theme
    @AppStorage("homeCardImage") private var cardImageName = ""

    @State private var showAdd = false
    @State private var selectedWallet: Wallet?
    @State private var showAll = false

    private var recent: [Entry] { Array(store.entries.prefix(6)) }

    private var totalCardImage: UIImage? {
        ImageStore.image(cardImageName.isEmpty ? nil : cardImageName)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    totalCard

                    if !store.enabledWallets.isEmpty {
                        walletsGrid
                    }

                    if !recent.isEmpty {
                        BlockTitle(title: "最近记录", trailing: "共 \(store.entries.count) 笔")
                        recentCard
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("记一笔")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAdd = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(theme)
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
        }
    }

    // MARK: - 总资产

    private var totalCard: some View {
        let onImage = totalCardImage != nil
        let primary: Color = onImage ? .white : .primary
        let secondary: Color = onImage ? Color.white.opacity(0.82) : .secondary
        let faint: Color = onImage ? Color.white.opacity(0.62) : Color(.tertiaryLabel)

        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("总资产")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(secondary)
                Spacer()
                Text("\(store.enabledWallets.count) 个账户")
                    .font(.system(size: 12))
                    .foregroundStyle(faint)
            }

            Text(Money.text(store.totalCents))
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .monospacedDigit()
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .foregroundStyle(primary)

            HStack(spacing: 22) {
                stat("本月收入", Money.text(store.monthIncomeCents), onImage ? .white : .green, faint)
                stat("本月支出", Money.text(store.monthExpenseCents), onImage ? .white : .red, faint)
            }
        }
        .padding(18)
        .background {
            ZStack {
                Color(.secondarySystemGroupedBackground)
                if let image = totalCardImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                    LinearGradient(colors: [Color.black.opacity(0.18), Color.black.opacity(0.55)],
                                   startPoint: .top, endPoint: .bottom)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
    }

    private func stat(_ title: String, _ value: String, _ tint: Color, _ label: Color) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 12))
                .foregroundStyle(label)
            Text(value)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(tint)
        }
    }

    // MARK: - 账户

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
        .card(padding: 16)
    }
}
