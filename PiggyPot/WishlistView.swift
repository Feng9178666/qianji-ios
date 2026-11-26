import SwiftUI
import UIKit

struct WishlistView: View {
    @EnvironmentObject private var store: Store
    @Environment(\.themeColor) private var theme

    @State private var showNew = false
    @State private var editing: Wish?
    @State private var depositing: Wish?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    summaryCard

                    if store.wishes.isEmpty {
                        emptyCard
                    } else {
                        ForEach(store.wishes) { wish in
                            wishCard(wish)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("心愿")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showNew = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
            }
            .sheet(isPresented: $showNew) {
                WishEditorView(wish: nil)
                    .environmentObject(store)
            }
            .sheet(item: $editing) { wish in
                WishEditorView(wish: wish)
                    .environmentObject(store)
            }
            .sheet(item: $depositing) { wish in
                WishDepositView(wish: wish)
                    .environmentObject(store)
            }
        }
    }

    // MARK: - 汇总

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("一共攒了")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(store.wishes.count) 个心愿")
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)
            }
            Text(Money.text(store.totalWishSaved))
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .monospacedDigit()
            if store.totalWishTarget > 0 {
                Text("目标 \(Money.text(store.totalWishTarget))")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
        .card(padding: 16)
    }

    private var emptyCard: some View {
        VStack(spacing: 10) {
            Image(systemName: "heart.text.square")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(.tertiary)
            Text("还没有心愿")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.secondary)
            Text("把想买的东西加进来，标上价格，\n然后一笔一笔往里攒。")
                .font(.system(size: 13))
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
            Button {
                showNew = true
            } label: {
                Text("加一个心愿")
                    .font(.system(size: 14, weight: .medium))
                    .padding(.horizontal, 18)
                    .frame(height: 36)
                    .background(theme, in: Capsule())
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 26)
        .card()
    }

    // MARK: - 心愿卡片

    private func wishCard(_ wish: Wish) -> some View {
        let background = ImageStore.image(wish.backgroundImageName)
        let onImage = background != nil
        let primary: Color = onImage ? .white : .primary
        let secondary: Color = onImage ? Color.white.opacity(0.85) : .secondary
        let faint: Color = onImage ? Color.white.opacity(0.6) : Color(.tertiaryLabel)

        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                WishIcon(wish: wish, size: 36)

                VStack(alignment: .leading, spacing: 2) {
                    Text(wish.title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(primary)
                        .lineLimit(1)
                    Text(subtitle(wish))
                        .font(.system(size: 12))
                        .foregroundStyle(secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                if wish.isDone {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(.green)
                } else {
                    Button {
                        depositing = wish
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 26))
                            .foregroundStyle(onImage ? Color.white : theme)
                    }
                    .buttonStyle(.plain)
                }
            }

            progressBar(wish, onImage: onImage)

            HStack(alignment: .firstTextBaseline) {
                Text(Money.text(wish.savedCents))
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(primary)
                Text("/ \(Money.text(wish.targetCents))")
                    .font(.system(size: 12))
                    .foregroundStyle(faint)
                Spacer()
                Text("\(Int(wish.progress * 100))%")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(secondary)
            }
        }
        .padding(16)
        .background {
            ZStack {
                Color(.secondarySystemGroupedBackground)
                if let background {
                    Image(uiImage: background)
                        .resizable()
                        .scaledToFill()
                    LinearGradient(colors: [Color.black.opacity(0.2), Color.black.opacity(0.55)],
                                   startPoint: .top, endPoint: .bottom)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .onTapGesture {
            editing = wish
        }
    }

    private func progressBar(_ wish: Wish, onImage: Bool) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule(style: .continuous)
                    .fill(onImage ? Color.white.opacity(0.3) : Color(.tertiarySystemFill))
                Capsule(style: .continuous)
                    .fill(onImage ? Color.white : Color(hex: wish.colorHex))
                    .frame(width: max(6, geo.size.width * wish.progress))
            }
        }
        .frame(height: 8)
    }

    private func subtitle(_ wish: Wish) -> String {
        if wish.isDone { return "已经攒够了" }
        var parts: [String] = []
        parts.append("还差 \(Money.text(wish.remainingCents))")
        if let deadline = wish.deadline {
            let days = Calendar.current.dateComponents([.day],
                                                       from: DateText.startOfDay(Date()),
                                                       to: DateText.startOfDay(deadline)).day ?? 0
            if days >= 0 {
                parts.append(days == 0 ? "今天到期" : "还有 \(days) 天")
            } else {
                parts.append("已过期")
            }
        }
        return parts.joined(separator: " · ")
    }
}
