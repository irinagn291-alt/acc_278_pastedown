import CoreGraphics
import UIKit

/// Role: Strip. Seat angle under one degree, alternating by index. Not persisted.
enum StripSeating {
    static func angle(seat: Int) -> CGFloat {
        let sign: CGFloat = seat.isMultiple(of: 2) ? 1 : -1
        return sign * (0.7 * .pi / 180)
    }

    static func height(for text: String, width: CGFloat, font: UIFont) -> CGFloat {
        let inset = Space.gutter * 2
        let usable = max(width - inset, Space.n(8))
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineHeightMultiple = 1.45
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .paragraphStyle: paragraph,
        ]
        let bounds = (text as NSString).boundingRect(
            with: CGSize(width: usable, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attributes,
            context: nil
        )
        let fiveLines = font.lineHeight * 1.45 * 5
        let textHeight = max(ceil(bounds.height), min(ceil(bounds.height), fiveLines))
        let grown = max(textHeight, font.lineHeight * 1.45)
        let sourceLine = max(TypeScale.uiCaption.lineHeight + Space.n(3), Space.n(4))
        return grown + Space.n(5) + sourceLine
    }
}
