import SwiftUI

@main
struct PiggyPotApp: App {
    @StateObject private var store = Store()
    @AppStorage("appearance") private var appearance = 0
    @AppStorage("themeHex") private var themeHex = Palette.default

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environment(\.themeColor, Color(hex: themeHex))
                .tint(Color(hex: themeHex))
                .preferredColorScheme(appearance == 1 ? .light : (appearance == 2 ? .dark : nil))
        }
    }
}

struct RootView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("记账", systemImage: "yensign.circle.fill")
                }
            WishlistView()
                .tabItem {
                    Label("心愿", systemImage: "heart.fill")
                }
            SettingsView()
                .tabItem {
                    Label("设置", systemImage: "gearshape.fill")
                }
        }
    }
}
