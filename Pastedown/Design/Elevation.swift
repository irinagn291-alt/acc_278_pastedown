import UIKit

/// Role: Design. One elevation language. Soft drop shadow on every raised surface.
enum Elevation {
    static let opacity: Float = 0.14
    static var radius: CGFloat { Space.n(2) }
    static var offset: CGSize { CGSize(width: 0, height: Space.unit) }

    static func apply(to layer: CALayer, path: CGPath? = nil) {
        layer.shadowColor = Palette.uiInk.cgColor
        layer.shadowOpacity = opacity
        layer.shadowRadius = radius
        layer.shadowOffset = offset
        layer.shadowPath = path
        layer.masksToBounds = false
    }
}
