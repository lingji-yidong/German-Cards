#if os(macOS)
import AppKit
import OSLog

@MainActor
final class AppIconAppearanceController: NSObject, NSApplicationDelegate {
    nonisolated private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "GermanCards",
        category: "AppIcon"
    )

    private var appearanceObservation: NSKeyValueObservation?

    func applicationDidFinishLaunching(_ notification: Notification) {
        updateApplicationIcon()
        appearanceObservation = NSApplication.shared.observe(
            \.effectiveAppearance,
            options: [.new]
        ) { [weak self] _, _ in
            Task { @MainActor [weak self] in
                self?.updateApplicationIcon()
            }
        }
    }

    private func updateApplicationIcon() {
        let appearance = NSApplication.shared.effectiveAppearance.bestMatch(
            from: [.aqua, .darkAqua]
        )
        let resourceName = appearance == .darkAqua ? "AppIcon" : "AppIconMacLight"

        guard let icon = Bundle.main.image(forResource: NSImage.Name(resourceName)) else {
            Self.logger.error("Unable to load application icon asset: \(resourceName, privacy: .public)")
            return
        }

        NSApplication.shared.applicationIconImage = icon
        Self.logger.info("Updated application icon: \(resourceName, privacy: .public)")
    }
}
#endif
