//
//  GermanCardsApp.swift
//  GermanCards
//
//  Created by lingji-yidong on 19/5/26.
//

import SwiftUI

@main
struct GermanCardsApp: App {
    #if os(macOS)
    @NSApplicationDelegateAdaptor(AppIconAppearanceController.self) private var appIconController
    #endif

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
