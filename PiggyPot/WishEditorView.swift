import SwiftUI
import PhotosUI
import UIKit

struct WishEditorView: View {
    @EnvironmentObject private var store: Store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.themeColor) private var theme

    private let original: Wish?

    @State private var title: String
    @State private var targetText: String
    @State private var symbol: String
    @State private var colorHex: String
    @State private var hasDeadline: Bool
    @State private var deadline: Date
    @State private var iconName: String?
    @State private var backgroundName: String?
    @State private var iconItem: PhotosPickerItem?
    @State private var backgroundItem: PhotosPickerItem?
    @State private var showDelete = false

    init(wish: Wish?) {
        original = wish
        _title = State(initialValue: wish?.title ?? "")
        _targetText = State(initialValue: wish.map { Money.editable($0.targetCents) } ?? "")
        _symbol = State(initialValue: wish?.symbol ?? "gift.fill")
        _colorHex = State(initialValue: wish?.colorHex ?? Palette.default)
        _hasDeadline = State(initialValue: wish?.deadline != nil)
        _deadline = State(initialValue: wish?.deadline ?? Date().addingTimeInterval(86400 * 30))
        _iconName = State(initialValue: wish?.iconImageName)
        _backgroundName = State(initialValue: wish?.backgroundImageName)
    }

    private var targetCents: Int? {
        guard let value = Money.parse(targetText), value > 0 else { return nil }
        return value
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && targetCents != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 14) {
                        previewIcon(size: 52)
                        TextField("想买什么，比如 新耳机", text: $title)
                            .font(.system(size: 17))
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    HStack {
                        Text("价格")
                        Spacer()
                        Text("¥")
                            .foregroundStyle(.secondary)
                        TextField("0", text: $targetText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .font(.system(size: 17, design: .rounded))
                            .frame(maxWidth: 140)
                    }
                } footer: {
                    Text("攒到这么多就算达成。")
                }

                Section {
                    HStack(spacing: 12) {
                        PhotosPicker(selection: $iconItem, matching: .images) {
                            Label("从相册选图标", systemImage: "photo")
                                .font(.system(size: 15))
                        }
                        Spacer()
                        if iconName != nil {
                            Button("用符号") {
                                iconName = nil
                                iconItem = nil
                            }
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                        }
                    }

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 6), spacing: 12) {
                        ForEach(Symbols.wishItems, id: \.self) { item in
                            Button {
                                symbol = item
                                iconName = nil
                            } label: {
                                Image(systemName: item)
                                    .font(.system(size: 18))
                                    .frame(width: 38, height: 38)
                                    .foregroundStyle(isSelectedSymbol(item) ? Color.white : Color.secondary)
                                    .background(
                                        Circle().fill(isSelectedSymbol(item) ? Color(hex: colorHex) : Color(.tertiarySystemFill))
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("图标")
                } footer: {
                    Text("可以从相册挑一张图，也可以用下面的符号。")
                }

                Section {
                    HStack(spacing: 12) {
                        if let image = ImageStore.image(backgroundName) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 56, height: 40)
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                        PhotosPicker(selection: $backgroundItem, matching: .images) {
                            Label(backgroundName == nil ? "选一张背景图" : "换一张背景图", systemImage: "photo.on.rectangle.angled")
                                .font(.system(size: 15))
                        }
                        Spacer()
                        if backgroundName != nil {
                            Button("移除") {
                                ImageStore.delete(backgroundName)
                                backgroundName = nil
                                backgroundItem = nil
                            }
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("卡片背景")
                } footer: {
                    Text("选一张图，心愿卡片就用它当底。")
                }

                Section("颜色") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 5), spacing: 12) {
                        ForEach(Palette.colors) { item in
                            Button {
                                colorHex = item.hex
                            } label: {
                                Circle()
                                    .fill(Color(hex: item.hex))
                                    .frame(width: 38, height: 38)
                                    .overlay(
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 15, weight: .bold))
                                            .foregroundStyle(.white)
                                            .opacity(colorHex.uppercased() == item.hex.uppercased() ? 1 : 0)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    Toggle("设定日期", isOn: $hasDeadline.animation())
                    if hasDeadline {
                        DatePicker("目标日期", selection: $deadline, displayedComponents: .date)
                    }
                } footer: {
                    Text("可选。设了会显示还剩几天。")
                }

                if let original, !original.deposits.isEmpty {
                    Section("攒钱记录") {
                        ForEach(original.deposits) { deposit in
                            HStack {
                                Text(DateText.day.string(from: deposit.date))
                                    .font(.system(size: 14))
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("+\(Money.text(deposit.cents))")
                                    .font(.system(size: 15, weight: .medium, design: .rounded))
                                    .monospacedDigit()
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                }

                if let original {
                    Section {
                        Button("删除这个心愿", role: .destructive) {
                            showDelete = true
                        }
                    }
                    .confirmationDialog("删除「\(original.title)」？", isPresented: $showDelete, titleVisibility: .visible) {
                        Button("删除", role: .destructive) {
                            store.deleteWish(original)
                            dismiss()
                        }
                        Button("取消", role: .cancel) {}
                    }
                }
            }
            .navigationTitle(original == nil ? "新心愿" : "编辑心愿")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                        .disabled(!canSave)
                        .fontWeight(.semibold)
                }
            }
            .onChange(of: iconItem) { _, item in
                guard let item else { return }
                Task { @MainActor in
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let name = ImageStore.save(data) {
                        iconName = name
                    }
                }
            }
            .onChange(of: backgroundItem) { _, item in
                guard let item else { return }
                Task { @MainActor in
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let name = ImageStore.save(data) {
                        backgroundName = name
                    }
                }
            }
        }
    }

    private func isSelectedSymbol(_ item: String) -> Bool {
        iconName == nil && symbol == item
    }

    @ViewBuilder
    private func previewIcon(size: CGFloat) -> some View {
        if let image = ImageStore.image(iconName) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: size * 0.28, style: .continuous))
        } else {
            Circle()
                .fill(Color(hex: colorHex).gradient)
                .frame(width: size, height: size)
                .overlay(
                    Image(systemName: symbol)
                        .font(.system(size: size * 0.44, weight: .semibold))
                        .foregroundStyle(.white)
                )
        }
    }

    private func save() {
        guard let targetCents else { return }
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)

        if var wish = original {
            wish.title = trimmed
            wish.targetCents = targetCents
            wish.symbol = symbol
            wish.colorHex = colorHex
            wish.deadline = hasDeadline ? deadline : nil
            wish.iconImageName = iconName
            wish.backgroundImageName = backgroundName
            store.updateWish(wish)
        } else {
            store.addWish(Wish(title: trimmed,
                               targetCents: targetCents,
                               symbol: symbol,
                               colorHex: colorHex,
                               deadline: hasDeadline ? deadline : nil,
                               iconImageName: iconName,
                               backgroundImageName: backgroundName))
        }
        dismiss()
    }
}
