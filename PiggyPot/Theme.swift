import SwiftUI
import UIKit

enum Palette {
    struct Item: Identifiable, Hashable {
        let hex: String
        let name: String
        var id: String { hex }
    }

    /// 主题色，设置页里可一键选
    static let themes: [Item] = [
        Item(hex: "F09E2E", name: "黄"),
        Item(hex: "F472B6", name: "粉"),
        Item(hex: "34C759", name: "绿"),
        Item(hex: "3B82F6", name: "蓝"),
        Item(hex: "8B5CF6", name: "紫")
    ]

    static let colors: [Item] = [
        Item(hex: "F09E2E", name: "琥珀"),
        Item(hex: "3B82F6", name: "蓝"),
        Item(hex: "34C759", name: "绿"),
        Item(hex: "FF3B30", name: "红"),
        Item(hex: "8B5CF6", name: "紫"),
        Item(hex: "F472B6", name: "粉"),
        Item(hex: "22B8CF", name: "青"),
        Item(hex: "FF9500", name: "橙"),
        Item(hex: "8E8E93", name: "灰"),
        Item(hex: "5856D6", name: "靛")
    ]

    static let `default` = "F09E2E"
}

enum Symbols {
    static let items: [String] = [
        "wallet.pass.fill",
        "creditcard.fill",
        "banknote",
        "yensign.circle.fill",
        "bubble.left.fill",
        "iphone",
        "building.columns.fill",
        "gift.fill",
        "cart.fill",
        "cup.and.saucer.fill",
        "car.fill",
        "house.fill"
    ]

    static let wishItems: [String] = [
        "gift.fill",
        "headphones",
        "laptopcomputer",
        "iphone",
        "applewatch",
        "camera.fill",
        "airpods",
        "gamecontroller.fill",
        "bicycle",
        "airplane",
        "sofa.fill",
        "bag.fill"
    ]
}

extension Color {
    init(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        s = s.replacingOccurrences(of: "#", with: "")
        var value: UInt64 = 0
        Scanner(string: s).scanHexInt64(&value)
        let r = Double((value >> 16) & 0xFF) / 255.0
        let g = Double((value >> 8) & 0xFF) / 255.0
        let b = Double(value & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: 1)
    }

    var hexString: String {
        let ui = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "%02X%02X%02X",
                      Int(round(r * 255)), Int(round(g * 255)), Int(round(b * 255)))
    }
}

extension Wallet {
    var color: Color { Color(hex: colorHex) }
}

private struct ThemeColorKey: EnvironmentKey {
    static let defaultValue = Color(hex: Palette.default)
}

extension EnvironmentValues {
    var themeColor: Color {
        get { self[ThemeColorKey.self] }
        set { self[ThemeColorKey.self] = newValue }
    }
}

/// 本地图片存储：心愿图标、心愿背景图
enum ImageStore {
    static var directory: URL {
        let fm = FileManager.default
        let base = (try? fm.url(for: .applicationSupportDirectory,
                                in: .userDomainMask,
                                appropriateFor: nil,
                                create: true)) ?? fm.temporaryDirectory
        let dir = base.appendingPathComponent("images", isDirectory: true)
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    static func save(_ data: Data) -> String? {
        guard let image = UIImage(data: data) else { return nil }
        // 压到不至于太大，照片也别超过 1600px
        let scaled = image.scaled(maxSide: 1600)
        guard let jpeg = scaled.jpegData(compressionQuality: 0.85) else { return nil }
        let name = UUID().uuidString
        let url = directory.appendingPathComponent(name + ".jpg")
        do {
            try jpeg.write(to: url, options: .atomic)
            return name
        } catch {
            return nil
        }
    }

    static func image(_ name: String?) -> UIImage? {
        guard let name, !name.isEmpty else { return nil }
        return UIImage(contentsOfFile: directory.appendingPathComponent(name + ".jpg").path)
    }

    static func delete(_ name: String?) {
        guard let name, !name.isEmpty else { return }
        try? FileManager.default.removeItem(at: directory.appendingPathComponent(name + ".jpg"))
    }
}

/// 网络图标本地缓存：只下载一次，之后都读本地
enum RemoteIconCache {
    static var directory: URL { ImageStore.directory }

    private static func file(_ key: String) -> URL {
        let safe = key.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? "icon"
        return directory.appendingPathComponent("remote-" + safe + ".img")
    }

    static func cached(_ key: String) -> UIImage? {
        guard let data = try? Data(contentsOf: file(key)) else { return nil }
        return UIImage(data: data)
    }

    static func load(_ url: URL, key: String) async -> UIImage? {
        if let image = cached(key) { return image }
        guard let (data, _) = try? await URLSession.shared.data(from: url),
              let image = UIImage(data: data) else { return nil }
        try? data.write(to: file(key), options: .atomic)
        return image
    }
}

extension UIImage {
    func scaled(maxSide: CGFloat) -> UIImage {
        let longest = max(size.width, size.height)
        guard longest > maxSide else { return self }
        let scale = maxSide / longest
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
