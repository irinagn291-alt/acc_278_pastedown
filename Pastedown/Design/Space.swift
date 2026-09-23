import CoreGraphics

/// Role: Design. One spacing accessor. 8 pt grid. Only multiples of the unit.
enum Space {
    static let unit: CGFloat = 8
    static let gutter: CGFloat = 16
    static let tap: CGFloat = 44

    static func n(_ count: Int) -> CGFloat {
        unit * CGFloat(count)
    }
}
