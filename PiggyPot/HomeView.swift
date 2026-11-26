import SwiftUI
import UIKit

/// 总资产数字滚动
struct AnimatedMoney: View, Animatable {
    var value: Double

    var animatableData: Double {
        get { value }
        set { value = newValue }
    }

    var body: some View {
        Text(Money.text(Int(value.rounded())))
            .monospacedDigit()
    }
}

struct HomeView: View {
    @EnvironmentObject private var store: Store
    @Environment(\.themeColor) private var theme
    @AppStorage("homeCardImage") private var cardImageName = ""

    @State private var showAdd = false
    @State private var selectedWallet: Wallet?
    @State private var showAll = false
    @State private var depositWish: Wish?
    @State private var editWish: Wish?
    @State private var animatedTotal: Double = 0

    private var recent: [Entry] { Array(store.entries.prefix(6)) }
    private var wishes: [Wish] { store.homeWishes }

    private var totalCardImage: UIImage? {
        ImageStore.image(cardImageName.isEmpty ? nil : cardImageName)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 10) {
                    totalCard

                    if !store.enabledWallets.isEmpty {
                        walletsGrid
                    }

                    if !wishes.isEmpty {
                        BlockTitle(title: "心愿")
                        wishSection
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
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, theme)
                            .font(.system(size: 25))
                    }
                    .buttonStyle(.plain)
                }
            }
            .sheet(isPresented: $showAdd) {
                AddEntryView()
                    .environmentObject(store)
            }
            .sheet(item: $depositWish) { wish in
                WishDepositView(wish: wish)
                    .environmentObject(store)
            }
            .sheet(item: $editWish) { wish in
                WishEditorView(wish: wish)
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
            .onAppear {
                animatedTotal = 0
                withAnimation(.easeOut(duration: 0.9)) {
                    animatedTotal = Double(store.totalCents)
                }
            }
            .onChange(of: store.totalCents) { _, newValue in
                withAnimation(.easeOut(duration: 0.55)) {
                    animatedTotal = Double(newValue)
                }
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

            AnimatedMoney(value: animatedTotal)
                .font(.system(size: 40, weight: .bold, design: .rounded))
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
            GeometryReader { geo in
                ZStack {
                    Color(.secondarySystemGroupedBackground)
                    if let image = totalCardImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: geo.size.width, height: geo.size.height)
                            .clipped()
                        LinearGradient(colors: [Color.black.opacity(0.18), Color.black.opacity(0.55)],
                                       startPoint: .top, endPoint: .bottom)
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
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

    // MARK: - 心愿

    private var wishSection: some View {
        VStack(spacing: 0) {
            ForEach(Array(wishes.enumerated()), id: \.element.id) { index, wish in
                wishRow(wish)
                if index < wishes.count - 1 {
                    Divider().padding(.leading, 44)
                }
            }
        }
        .card(padding: 14)
    }

    private func wishRow(_ wish: Wish) -> some View {
        HStack(spacing: 12) {
            WishIcon(wish: wish, size: 32)

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    Text(wish.title)
                        .font(.system(size: 15))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    Spacer(minLength: 4)
                    Text("\(Int(wish.progress * 100))%")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                ProgressView(value: wish.progress)
                    .tint(Color(hex: wish.colorHex))
                Text("\(Money.text(wish.savedCents)) / \(Money.text(wish.targetCents))")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            if !wish.isDone {
                Button {
                    depositWish = wish
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, theme)
                        .font(.system(size: 23))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            editWish = wish
        }
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
        .card(padding: 14)
    }
}
