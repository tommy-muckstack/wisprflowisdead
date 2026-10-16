import AppKit

enum BrandAssets {
    static let icon = load("AppIcon")

    static func menuBarIcon() -> NSImage {
        let image = load("Tombstone")
        image.size = NSSize(width: 18, height: 18)
        // macOS templates keep the tombstone legible in light/dark menu bars.
        image.isTemplate = true
        image.accessibilityDescription = "WisprFlowIsDead"
        return image
    }

    private static func load(_ name: String) -> NSImage {
        guard let url = Bundle.module.url(forResource: name, withExtension: "png", subdirectory: "Branding"),
              let image = NSImage(contentsOf: url) else {
            assertionFailure("Missing bundled branding asset: \(name)")
            return NSImage(size: NSSize(width: 18, height: 18))
        }
        return image
    }
}
