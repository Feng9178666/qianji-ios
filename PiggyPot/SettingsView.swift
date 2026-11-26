import SwiftUI
import PhotosUI
import UIKit
import UniformTypeIdentifiers

struct SettingsView: View {
    @EnvironmentObject private var store: Store
    @Environment(\.themeColor) private var theme

    @AppStorage("appearance") private var appearance = 0
    @AppStorage("themeHex") private var themeHex = Palette.default
    @AppStorage("homeCardImage") private var cardImageName = ""
    @AppStorage("avatarImage") private var avatarName = ""

    @State private var cardItem: PhotosPickerItem?
    @State private var avatarItem: PhotosPickerItem?
    @State private var exportDocument: JSONDocument?
    @State private var showExporter = false
    @State private var showImporter = false
    @State private var pendingImport: Data?
    @State private var showImportConfirm = false
    @State private var message: String?

    private var customColor: Binding<Color> {
        Binding(
            get: { Color(hex: themeHex) },
            set: { themeHex = $0.hexString }
        )
    }

    private var cardImage: UIImage? {
        ImageStore.image(cardImageName.isEmpty ? nil : cardImageName)
    }

    private var avatarImage: UIImage? {
        ImageStore.image(avatarName.isEmpty ? nil : avatarName)
    }

    var body: some View {
        NavigationStack {
            List {
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
                                Text("\(store.enabledWallets.count)/\(store.wallets.count) 已开启")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                } header: {
                    Text("记账")
                }

                Section {
                    HStack(spacing: 12) {
                        PhotosPicker(selection: $avatarItem, matching: .images) {
                            HStack(spacing: 12) {
                                if let avatarImage {
                                    Image(uiImage: avatarImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 29, height: 29)
                                        .clipShape(Circle())
                                } else {
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 13))
                                        .foregroundStyle(.secondary)
                                        .frame(width: 29, height: 29)
                                        .background(Color(.tertiarySystemFill), in: Circle())
                                }
                                Text("头像")
                                    .font(.system(size: 17))
                                    .foregroundStyle(.primary)
                            }
                        }
                        Spacer()
                        if avatarImage == nil {
                            Text("未设置")
                                .font(.system(size: 15))
                                .foregroundStyle(.secondary)
                        } else {
                            Button("恢复") {
                                ImageStore.delete(avatarName)
                                avatarName = ""
                                avatarItem = nil
                            }
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                        }
                    }

                    Picker("模式", selection: $appearance) {
                        Text("自动").tag(0)
                        Text("浅色").tag(1)
                        Text("深色").tag(2)
                    }
                    .pickerStyle(.segmented)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))

                    HStack(spacing: 14) {
                        ForEach(Palette.themes) { item in
                            Button {
                                themeHex = item.hex
                            } label: {
                                Circle()
                                    .fill(Color(hex: item.hex))
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundStyle(.white)
                                            .opacity(themeHex.uppercased() == item.hex.uppercased() ? 1 : 0)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 2)

                    ColorPicker("自定义颜色", selection: customColor, supportsOpacity: false)
                } header: {
                    Text("外观")
                } footer: {
                    Text("设了头像后，首页右上角那个加号会换成头像，点它还是记一笔。")
                }

                Section {
                    HStack(spacing: 12) {
                        if let cardImage {
                            Image(uiImage: cardImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 56, height: 38)
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                        PhotosPicker(selection: $cardItem, matching: .images) {
                            Text(cardImageName.isEmpty ? "给首页卡片选张背景" : "换一张背景")
                                .font(.system(size: 16))
                                .foregroundStyle(.primary)
                        }
                        Spacer()
                        if !cardImageName.isEmpty {
                            Button("恢复") {
                                ImageStore.delete(cardImageName)
                                cardImageName = ""
                                cardItem = nil
                            }
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("首页卡片")
                }

                Section {
                    Button {
                        exportBackup()
                    } label: {
                        rowLabel("导出数据", symbol: "square.and.arrow.up", color: .blue)
                    }

                    Button {
                        showImporter = true
                    } label: {
                        rowLabel("导入数据", symbol: "square.and.arrow.down", color: .green)
                    }
                } header: {
                    Text("数据")
                } footer: {
                    if let message {
                        Text(message)
                    }
                }

                Section("社区") {
                    if let url = URL(string: "https://qm.qq.com/q/Ximw7wvyGA") {
                        Link(destination: url) {
                            HStack(spacing: 12) {
                                Image(systemName: "bubble.left.and.bubble.right.fill")
                                    .font(.system(size: 13, weight: .semibold))
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
                }

                Section("关于") {
                    infoRow("版本", versionText)
                    infoRow("开发者", "Lxp")
                    if let url = URL(string: "https://ac.6778.top") {
                        Link(destination: url) {
                            HStack {
                                Text("官网")
                                    .foregroundStyle(.primary)
                                Spacer()
                                Text("ac.6778.top")
                                    .foregroundStyle(.secondary)
                                Image(systemName: "arrow.up.forward")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: cardItem) { _, item in
                guard let item else { return }
                Task { @MainActor in
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let name = ImageStore.save(data) {
                        cardImageName = name
                    }
                }
            }
            .onChange(of: avatarItem) { _, item in
                guard let item else { return }
                Task { @MainActor in
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let name = ImageStore.save(data) {
                        avatarName = name
                    }
                }
            }
            .fileExporter(isPresented: $showExporter,
                          document: exportDocument,
                          contentType: .json,
                          defaultFilename: "记一笔备份.json") { result in
                switch result {
                case .success:
                    message = "已导出"
                case .failure:
                    message = "导出失败"
                }
            }
            .sheet(isPresented: $showImporter) {
                DocumentPicker(
                    onPick: { url in
                        showImporter = false
                        if let data = try? Data(contentsOf: url) {
                            pendingImport = data
                            showImportConfirm = true
                        } else {
                            message = "这个文件读不了"
                        }
                    },
                    onCancel: {
                        showImporter = false
                    }
                )
                .ignoresSafeArea()
            }
            .confirmationDialog("用这份备份覆盖现在的记录？",
                                isPresented: $showImportConfirm,
                                titleVisibility: .visible) {
                Button("覆盖导入", role: .destructive) {
                    if let data = pendingImport {
                        message = store.importData(data) ? "导入好了" : "文件格式不对"
                    }
                    pendingImport = nil
                }
                Button("取消", role: .cancel) {
                    pendingImport = nil
                }
            }
        }
    }

    private func rowLabel(_ title: String, symbol: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 29, height: 29)
                .background(color, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
            Text(title)
                .font(.system(size: 17))
                .foregroundStyle(.primary)
            Spacer()
        }
        .padding(.vertical, 2)
    }

    private func infoRow(_ key: String, _ value: String) -> some View {
        HStack {
            Text(key)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
    }

    private func exportBackup() {
        guard let data = store.exportData() else {
            message = "导出失败"
            return
        }
        exportDocument = JSONDocument(data: data)
        showExporter = true
        message = nil
    }

    private var versionText: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
}

/// 用系统文件选择器，asCopy 直接把文件复制进沙盒，避开安全作用域的坑
struct DocumentPicker: UIViewControllerRepresentable {
    var onPick: (URL) -> Void
    var onCancel: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick, onCancel: onCancel)
    }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.json, .plainText, .data, .item],
                                                   asCopy: true)
        picker.allowsMultipleSelection = false
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        private let onPick: (URL) -> Void
        private let onCancel: () -> Void

        init(onPick: @escaping (URL) -> Void, onCancel: @escaping () -> Void) {
            self.onPick = onPick
            self.onCancel = onCancel
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else {
                onCancel()
                return
            }
            onPick(url)
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            onCancel()
        }
    }
}

struct JSONDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    var data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        guard let contents = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        data = contents
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
