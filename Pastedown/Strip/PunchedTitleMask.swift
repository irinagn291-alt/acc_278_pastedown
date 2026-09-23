import CoreText
import UIKit

/// Role: Strip. Gone volume title is punched out of the paper as an even-odd subpath.
enum PunchedTitleMask {
    static func combine(paper: UIBezierPath, title: String, font: UIFont, in rect: CGRect) -> UIBezierPath {
        let combined = UIBezierPath(cgPath: paper.cgPath)
        let holeRect = CGRect(
            x: rect.minX + Space.gutter,
            y: rect.maxY - Space.n(4),
            width: max(rect.width - Space.gutter * 2, Space.n(8)),
            height: Space.n(3)
        )
        if let hole = textPath(title, font: font, in: holeRect) {
            combined.append(hole)
        }
        combined.usesEvenOddFillRule = true
        return combined
    }

    private static func textPath(_ title: String, font: UIFont, in rect: CGRect) -> UIBezierPath? {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        let attributed = NSAttributedString(string: trimmed, attributes: attributes)
        let line = CTLineCreateWithAttributedString(attributed)
        let runs = CTLineGetGlyphRuns(line) as NSArray
        let path = UIBezierPath()
        for index in 0 ..< runs.count {
            let run = unsafeBitCast(runs[index], to: CTRun.self)
            let count = CTRunGetGlyphCount(run)
            guard count > 0 else { continue }
            var glyphs = [CGGlyph](repeating: 0, count: count)
            var positions = [CGPoint](repeating: .zero, count: count)
            CTRunGetGlyphs(run, CFRange(location: 0, length: count), &glyphs)
            CTRunGetPositions(run, CFRange(location: 0, length: count), &positions)
            let runFont = font as CTFont
            for glyphIndex in 0 ..< count {
                guard let glyphPath = CTFontCreatePathForGlyph(runFont, glyphs[glyphIndex], nil) else { continue }
                let shifted = UIBezierPath(cgPath: glyphPath)
                let transform = CGAffineTransform(translationX: rect.minX + positions[glyphIndex].x, y: rect.minY)
                    .scaledBy(x: 1, y: -1)
                    .translatedBy(x: 0, y: -font.ascender)
                shifted.apply(transform)
                path.append(shifted)
            }
        }
        return path
    }
}
