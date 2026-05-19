import SwiftUI

extension View {
    @ViewBuilder
    func germanCardsAutocapitalization(_ mode: GermanCardsAutocapitalization) -> some View {
        #if os(iOS)
        switch mode {
        case .never:
            self.textInputAutocapitalization(.never)
        case .words:
            self.textInputAutocapitalization(.words)
        }
        #else
        self
        #endif
    }

    @ViewBuilder
    func germanCardsURLKeyboard() -> some View {
        #if os(iOS)
        self.keyboardType(.URL)
        #else
        self
        #endif
    }

    @ViewBuilder
    func germanCardsSearchSubmitLabel() -> some View {
        #if os(iOS)
        self.submitLabel(.search)
        #else
        self
        #endif
    }
}

enum GermanCardsAutocapitalization {
    case never
    case words
}
