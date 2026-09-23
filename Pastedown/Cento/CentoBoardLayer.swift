import UIKit

/// Role: Cento. Scrolling canvas layer. Strips seat here. An empty array renders Blank.
final class CentoBoardLayer: CALayer {
    private var stripLayers: [CuttingID: StripLayer] = [:]
    private(set) var frames: [CuttingID: CGRect] = [:]
    private(set) var strips: [Strip] = []

    override init() {
        super.init()
        backgroundColor = Palette.uiBackground.cgColor
    }

    override init(layer: Any) {
        super.init(layer: layer)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    @discardableResult
    func render(
        strips: [Strip],
        width: CGFloat,
        scale: CGFloat,
        pasted: CuttingID?,
        clash: CuttingID?,
        minHeight: CGFloat = 0
    ) -> CGFloat {
        self.strips = strips
        let font = TypeScale.uiBody
        let inset = Space.gutter
        let naturalHeights = strips.map { StripSeating.height(for: $0.text, width: width, font: font) }
        var y = Space.n(2)
        var nextFrames: [CuttingID: CGRect] = [:]
        var keep: Set<CuttingID> = []
        for (index, strip) in strips.enumerated() {
            let height = naturalHeights[index]
            let frame = CGRect(x: inset, y: y, width: max(width - inset * 2, Space.n(12)), height: height)
            nextFrames[strip.cuttingID] = frame
            let layer = stripLayers[strip.cuttingID] ?? StripLayer()
            if stripLayers[strip.cuttingID] == nil {
                addSublayer(layer)
                stripLayers[strip.cuttingID] = layer
            }
            layer.render(strip, in: CGRect(origin: .zero, size: frame.size), scale: scale)
            layer.position = CGPoint(x: frame.midX, y: frame.midY)
            layer.bounds = CGRect(origin: .zero, size: frame.size)
            keep.insert(strip.cuttingID)
            if pasted == strip.cuttingID {
                layer.playPaste()
            }
            y += height - Space.unit
        }
        if let clash, let layer = stripLayers[clash] {
            layer.playClash()
        }
        for (id, layer) in stripLayers where !keep.contains(id) {
            layer.removeFromSuperlayer()
            stripLayers.removeValue(forKey: id)
        }
        frames = nextFrames
        return max(y + Space.n(4), minHeight, Space.n(8))
    }

    func footLayer() -> StripLayer? {
        guard let last = strips.last else { return nil }
        return stripLayers[last.cuttingID]
    }
}
