import UIKit

/// Role: Design. Paper tints for strips, taken only from the fixed palette tokens.
enum PaperTint {
    static func color(for id: CuttingID) -> UIColor {
        let swatches = [
            Palette.uiSurface,
            Palette.uiAccent.withAlphaComponent(0.14),
            Palette.uiMuted.withAlphaComponent(0.12),
            Palette.uiInk.withAlphaComponent(0.05),
        ]
        var hasher = Hasher()
        hasher.combine(id.rawValue)
        let index = abs(hasher.finalize()) % swatches.count
        return swatches[index]
    }
}
