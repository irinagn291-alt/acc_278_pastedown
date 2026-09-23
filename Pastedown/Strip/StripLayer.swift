import UIKit

/// Role: Strip. CAShapeLayer torn paper plus CATextLayer quote. Projection only. Never a store record.
final class StripLayer: CALayer {
    let paper = CAShapeLayer()
    let quote = CATextLayer()
    private let sourcePlate = CALayer()
    private let source = CATextLayer()
    private(set) var strip: Strip?

    override init() {
        super.init()
        paper.fillColor = Palette.uiSurface.cgColor
        paper.strokeColor = Palette.uiMuted.withAlphaComponent(0.35).cgColor
        paper.lineWidth = 1
        paper.fillRule = .evenOdd
        quote.isWrapped = true
        quote.contentsScale = UITraitCollection.current.displayScale
        quote.alignmentMode = .left
        quote.truncationMode = .none
        quote.foregroundColor = Palette.uiInk.cgColor
        sourcePlate.backgroundColor = Palette.uiSurface.withAlphaComponent(0.94).cgColor
        sourcePlate.cornerRadius = Radius.chip
        sourcePlate.cornerCurve = .continuous
        source.isWrapped = false
        source.alignmentMode = .left
        source.truncationMode = .end
        source.foregroundColor = Palette.uiInk.cgColor
        addSublayer(paper)
        addSublayer(quote)
        addSublayer(sourcePlate)
        addSublayer(source)
    }

    override init(layer: Any) {
        super.init(layer: layer)
        if let other = layer as? StripLayer {
            strip = other.strip
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    func render(_ strip: Strip, in bounds: CGRect, scale: CGFloat) {
        self.strip = strip
        self.bounds = bounds
        paper.frame = bounds
        quote.contentsScale = scale
        source.contentsScale = scale
        let font = TypeScale.uiBody
        let sourceFont = TypeScale.uiCaption
        let torn = TornEdgePath.make(in: bounds.insetBy(dx: Space.unit, dy: Space.unit), seed: strip.cuttingID)
        paper.path = torn.cgPath
        paper.fillColor = PaperTint.color(for: strip.cuttingID).cgColor
        paper.fillRule = .evenOdd
        Elevation.apply(to: paper, path: torn.cgPath)
        let textInset = Space.gutter
        let plateHeight = max(sourceFont.lineHeight + Space.unit, Space.n(3))
        let quoteBottomGap = plateHeight + Space.n(3)
        let quoteTop = bounds.minY + Space.n(2)
        let quoteHeight = max(bounds.height - quoteBottomGap - Space.n(2), font.lineHeight * 1.45)
        quote.frame = CGRect(
            x: bounds.minX + textInset,
            y: quoteTop,
            width: max(bounds.width - textInset * 2, Space.n(8)),
            height: quoteHeight
        )
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineHeightMultiple = 1.45
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: Palette.uiInk,
            .paragraphStyle: paragraph,
            .kern: 0,
        ]
        quote.string = NSAttributedString(string: strip.text, attributes: attributes)
        let sourceY = max(quote.frame.maxY + Space.unit, bounds.maxY - plateHeight - Space.n(2))
        sourcePlate.frame = CGRect(
            x: bounds.minX + textInset,
            y: sourceY,
            width: quote.frame.width,
            height: plateHeight
        )
        source.frame = sourcePlate.frame.insetBy(dx: Space.unit, dy: Space.unit / 2)
        let sourceTitle = strip.volumeTitle.isEmpty ? "Volume" : strip.volumeTitle
        let sourceText = "\(sourceTitle), page \(CentoFigures.page(strip.page))"
        let sourceAttributes: [NSAttributedString.Key: Any] = [
            .font: sourceFont,
            .foregroundColor: Palette.uiInk,
        ]
        source.string = NSAttributedString(string: sourceText, attributes: sourceAttributes)
        sourcePlate.isHidden = false
        source.isHidden = false
        quote.opacity = 1
        let angle = StripSeating.angle(seat: strip.seat)
        setAffineTransform(CGAffineTransform(rotationAngle: angle))
    }

    func playPaste() {
        if Motion.reduce {
            opacity = 1
            return
        }
        opacity = 0
        Motion.fade(self, to: 1)
        Motion.settle(self)
    }

    func playClash() {
        Motion.shiver(self)
    }
}
