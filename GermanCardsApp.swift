//
//  GermanCardsApp.swift
//  GermanCards
//
//  Created by lingji-yidong on 19/5/26.
//

import SwiftUI

@main
struct GermanCardsApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                #if targetEnvironment(macCatalyst)
                .frame(minWidth: 390, minHeight: 620)
                #endif
        }
        #if targetEnvironment(macCatalyst)
        .defaultSize(width: 430, height: 860)
        #endif
    }
}
