import Foundation
import SwiftUI

#if canImport(UIKit) && !targetEnvironment(macCatalyst)
import UIKit
#endif

enum AppIconController {
    @MainActor
    static func apply(appearance: AppAppearance, systemColorScheme: ColorScheme) async {
        #if canImport(UIKit) && !targetEnvironment(macCatalyst)
        guard UIApplication.shared.supportsAlternateIcons else { return }

        let iconName: String?
        switch appearance {
        case .system:
            // The primary icon contains iOS luminosity and tinted variants.
            iconName = nil
        case .light:
            iconName = "AppIconLight"
        case .dark:
            iconName = "AppIconDark"
        }

        guard UIApplication.shared.alternateIconName != iconName else { return }
        try? await UIApplication.shared.setAlternateIconName(iconName)
        #endif
    }
}
