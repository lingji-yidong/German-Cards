//
//  ContentView.swift
//  GermanCards
//
//  Created by lingji-yidong on 19/5/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var store = WordStore()
    @AppStorage("app_appearance") private var appearanceRaw = AppAppearance.system.rawValue
    @Environment(\.colorScheme) private var systemColorScheme

    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Grammar", systemImage: "text.book.closed")
                }

            SearchView(store: store)
                .tabItem {
                    Label("Cards", systemImage: "rectangle.stack")
                }

            SettingsView(store: store)
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
        .tint(AppTheme.brand)
        .preferredColorScheme((AppAppearance(rawValue: appearanceRaw) ?? .system).colorScheme)
        .task(id: "\(appearanceRaw)-\(systemColorScheme == .dark ? "dark" : "light")") {
            let appearance = AppAppearance(rawValue: appearanceRaw) ?? .system
            await AppIconController.apply(appearance: appearance, systemColorScheme: systemColorScheme)
        }
    }
}

#if DEBUG
#Preview {
    ContentView()
}
#endif
