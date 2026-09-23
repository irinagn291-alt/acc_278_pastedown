import SwiftUI
import UIKit

/// Role: Design. One colour accessor. Named colours live in Assets.xcassets.
/// Hex is recorded here once and nowhere else.
enum Palette {
    /// background `#FFFFFF`
    static var background: Color { Color("background") }
    /// surface `#FFFFFF`
    static var surface: Color { Color("surface") }
    /// ink `#000000`
    static var ink: Color { Color("ink") }
    /// accent `#CC7C00`
    static var accent: Color { Color("accent") }
    /// muted `#6B6B6B`
    static var muted: Color { Color("muted") }

    static var uiBackground: UIColor { UIColor(named: "background") ?? .white }
    static var uiSurface: UIColor { UIColor(named: "surface") ?? .white }
    static var uiInk: UIColor { UIColor(named: "ink") ?? .black }
    static var uiAccent: UIColor { UIColor(named: "accent") ?? .systemOrange }
    static var uiMuted: UIColor { UIColor(named: "muted") ?? .gray }
}
