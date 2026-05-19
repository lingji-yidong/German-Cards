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
    }
}

#Preview {
    ContentView()
}
