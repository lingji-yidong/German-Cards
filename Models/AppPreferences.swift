import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

enum AppAppearance: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system:
            return "System"
        case .light:
            return "Light"
        case .dark:
            return "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

enum GrammarLanguage: String, CaseIterable, Identifiable {
    case traditionalChinese
    case simplifiedChinese
    case english

    var id: String { rawValue }

    var title: String {
        switch self {
        case .traditionalChinese:
            return "繁體中文"
        case .simplifiedChinese:
            return "简体中文"
        case .english:
            return "English"
        }
    }
}

enum AppTheme {
    static let brand = Color(red: 0.10, green: 0.36, blue: 0.72)

    #if canImport(UIKit)
    static let background = Color(uiColor: .systemGroupedBackground)
    static let surface = Color(uiColor: .secondarySystemGroupedBackground)
    static let elevatedSurface = Color(uiColor: .systemBackground)
    static let softSurface = Color(uiColor: .tertiarySystemGroupedBackground)
    static let primaryText = Color(uiColor: .label)
    static let secondaryText = Color(uiColor: .secondaryLabel)
    static let separator = Color(uiColor: .separator).opacity(0.45)
    #elseif canImport(AppKit)
    // AppKit uses NSColor names; keep theme tokens stable across iOS, Catalyst, and native macOS builds.
    static let background = Color(nsColor: .windowBackgroundColor)
    static let surface = Color(nsColor: .controlBackgroundColor)
    static let elevatedSurface = Color(nsColor: .textBackgroundColor)
    static let softSurface = Color(nsColor: .underPageBackgroundColor)
    static let primaryText = Color(nsColor: .labelColor)
    static let secondaryText = Color(nsColor: .secondaryLabelColor)
    static let separator = Color(nsColor: .separatorColor).opacity(0.45)
    #endif
}
