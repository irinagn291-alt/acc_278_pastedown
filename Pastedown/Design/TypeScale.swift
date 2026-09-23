import SwiftUI
import UIKit

/// Role: Design. SF Pro only, six steps. Display for headers and numerals, Text for body.
enum TypeScale {
    static var display: Font { Font(uiDisplay) }
    static var title: Font { Font(uiTitle) }
    static var body: Font { Font(uiBody) }
    static var callout: Font { Font(uiCallout) }
    static var caption: Font { Font(uiCaption) }
    static var numeral: Font { Font(uiNumeral) }

    static var uiDisplay: UIFont { scaled(.semibold, size: 28, style: .title1) }
    static var uiTitle: UIFont { scaled(.semibold, size: 22, style: .title2) }
    static var uiBody: UIFont { scaled(.regular, size: 17, style: .body) }
    static var uiCallout: UIFont { scaled(.regular, size: 15, style: .callout) }
    static var uiCaption: UIFont { scaled(.regular, size: 13, style: .caption1) }
    static var uiNumeral: UIFont {
        let base = scaled(.semibold, size: 28, style: .title1)
        let numbers = base.fontDescriptor.addingAttributes([
            .featureSettings: [[
                UIFontDescriptor.FeatureKey.type: kNumberSpacingType,
                UIFontDescriptor.FeatureKey.selector: kMonospacedNumbersSelector,
            ]],
        ])
        return UIFontMetrics(forTextStyle: .title1).scaledFont(for: UIFont(descriptor: numbers, size: 28))
    }

    private static func scaled(_ weight: UIFont.Weight, size: CGFloat, style: UIFont.TextStyle) -> UIFont {
        let base = UIFont.systemFont(ofSize: size, weight: weight)
        return UIFontMetrics(forTextStyle: style).scaledFont(for: base)
    }
}
