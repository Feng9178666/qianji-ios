import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: Store
    @Environment(\.themeColor) private var theme

    @AppStorage("appearance") private var appearance = 0
    @AppStorage("themeHex") private var themeHex = Palette.default

    private var customColor: Binding<Color> {
        Binding(
            get: { Color(hex: themeHex) },
            set: { themeHex = $0.hexString }
        )
    }

    var body: some View {
        NavigationStack {
            List {
                Section("外观") {
                    Picker("外观", selection: $appearance) {
                        Text("自动").tag(0)
                        Text("浅色").tag(1)
                        Text("深色").tag(2)
                    }
                    .pickerStyle(.segmented)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }

                Section {
                    HStack(spacing: 16) {
                        ForEach(Palette.themes) { item in
                            Button {
                                themeHex = item.hex
                            } label: {
                                Circle()
                                    .fill(Color(hex: item.hex))
                                    .frame(width: 34, height: 34)
                                    .overlay(
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundStyle(.white)
                                            .opacity(themeHex.uppercased() == item.hex.uppercased() ? 1 : 0)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 4)

                    ColorPicker("自定义颜色", selection: customColor, supportsOpacity: false)
                } header: {
                    Text("主题色")
                } footer: {
                    Text("按钮、进度条、高亮都用这个颜色。")
                }

                Section {
                    NavigationLink {
                        AccountsView()
                            .environmentObject(store)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "wallet.pass.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: 29, height: 29)
                                .background(theme, in: RoundedRectangle(cornerRadius: 7, style: .continuous))

                            VStack(alignment: .leading, spacing: 2) {
                                Text("账户管理")
                                    .font(.system(size: 17))
                                Text("开启要用的账户 · \(store.enabledWallets.count)/\(store.wallets.count) 已开启")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }

                Section {
                    if let url = URL(string: "https://qm.qq.com/q/Ximw7wvyGA") {
                        Link(destination: url) {
                            HStack(spacing: 12) {
                                Image(systemName: "bubble.left.and.bubble.right.fill")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .frame(width: 29, height: 29)
                                    .background(Color(hex: "2CA5E0"), in: RoundedRectangle(cornerRadius: 7, style: .continuous))

                                Text("加入官方群")
                                    .font(.system(size: 17))
                                    .foregroundStyle(.primary)

                                Spacer()

                                Image(systemName: "arrow.up.forward")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                } footer: {
                    Text("点这里直接打开群邀请。")
                }

                Section("关于") {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text(versionText)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    HStack {
                        Text("应用")
                        Spacer()
                        Text("钱迹")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var versionText: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}
