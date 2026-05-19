//
//  ContentView.swift
//  GermanCards
//
//  Created by lingji-yidong on 19/5/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var store = WordStore()

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

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
        .tint(Color(red: 0.10, green: 0.36, blue: 0.72))
    }
}

#Preview {
    ContentView()
}
