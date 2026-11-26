import SwiftUI
import UIKit

/// 账户图标：有网络图标用网络图，否则彩色圆 + 符号
struct WalletBadge: View {
    let wallet: Wallet
    var size: CGFloat = 26

    @State private var remoteImage: UIImage?

    var body: some View {
        Group {
            if let asset = wallet.iconAsset, let image = UIImage(named: asset) {
                Image(uiImage: image).resizable().scaledToFill()
            } else if let remoteImage {
                Image(uiImage: remoteImage).resizable().scaledToFill()
            } else {
                fallback
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.28, style: .continuous))
        .task(id: wallet.iconURL) {
            guard wallet.iconAsset == nil,
                  let text = wallet.iconURL,
                  let url = URL(string: text),
                  !text.isEmpty else { return }
            remoteImage = await RemoteIconCache.load(url, key: text)
        }
    }

    private var fallback: some View {
        Circle()
            .fill(wallet.color.gradient)
            .overlay(
                Image(systemName: wallet.symbol)
                    .font(.system(size: size * 0.5, weight: .semibold))
                    .foregroundStyle(.white)
            )
    }
}

/// 心愿图标：自定义图片优先，否则彩色圆 + 符号
struct WishIcon: View {
    let wish: Wish
    var size: CGFloat = 36

    var body: some View {
        Group {
            if let image = ImageStore.image(wish.iconImageName) {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                Circle()
                    .fill(Color(hex: wish.colorHex).gradient)
                    .overlay(
                        Image(systemName: wish.symbol)
                            .font(.system(size: size * 0.46, weight: .semibold))
                            .foregroundStyle(.white)
                    )
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.28, style: .continuous))
    }
}

struct CardBackground: ViewModifier {
    var hPad: CGFloat = 16
    var vPad: CGFloat = 16
    var corner: CGFloat = 20

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, hPad)
            .padding(.vertical, vPad)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
    }
}

extension View {
    func card(padding: CGFloat = 16, corner: CGFloat = 20) -> some View {
        modifier(CardBackground(hPad: padding, vPad: padding, corner: corner))
    }

    func card(hPad: CGFloat, vPad: CGFloat, corner: CGFloat = 20) -> some View {
        modifier(CardBackground(hPad: hPad, vPad: vPad, corner: corner))
    }
}

struct BlockTitle: View {
    let title: String
    var trailing: String? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
            Spacer()
            if let trailing {
                Text(trailing)
                    .font(.system(size: 13))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 4)
        .padding(.top, 10)
    }
}

struct EntryRow: View {
    let entry: Entry
    let wallet: Wallet?
    var showsTime = true

    var body: some View {
        HStack(spacing: 12) {
            if let wallet {
                WalletBadge(wallet: wallet, size: 32)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.note.isEmpty ? (wallet?.name ?? "未命名") : entry.note)
                    .font(.system(size: 15))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            Text(Money.signedText(entry.signedCents))
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(entry.kind == .income ? Color.green : Color.primary)
        }
        .frame(minHeight: 44)
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }

    private var subtitle: String {
        var parts: [String] = []
        if let wallet { parts.append(wallet.name) }
        if showsTime { parts.append(DateText.clock.string(from: entry.date)) }
        return parts.joined(separator: " · ")
    }
}

struct EmptyHint: View {
    let symbol: String
    let title: String
    var detail: String? = nil

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 30, weight: .light))
                .foregroundStyle(.tertiary)
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.secondary)
            if let detail {
                Text(detail)
                    .font(.system(size: 13))
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
    }
}
