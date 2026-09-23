import UIKit

/// Role: Gathering. Wall of sealed centos. Each card is the sealed strips themselves.
@MainActor
final class CollageWallLayer: UIView {
    var onOpen: ((Cento) -> Void)?
    private let stack = UIStackView()
    private var cards: [SealedCentoCard] = []
    private var centos: [Cento] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = Palette.uiBackground
        stack.axis = .vertical
        stack.spacing = Space.n(2)
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        setContentHuggingPriority(.required, for: .vertical)
        setContentCompressionResistancePriority(.required, for: .vertical)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    func render(_ centos: [Cento], root: StoreRoot, calendar: Calendar) {
        self.centos = centos.filter { $0.seal == .sealed }.sorted { $0.daykey > $1.daykey }
        while cards.count < self.centos.count {
            let card = SealedCentoCard()
            card.addTarget(self, action: #selector(open(_:)), for: .touchUpInside)
            cards.append(card)
            stack.addArrangedSubview(card)
        }
        while cards.count > self.centos.count {
            let extra = cards.removeLast()
            extra.removeFromSuperview()
        }
        for (index, cento) in self.centos.enumerated() {
            cards[index].apply(cento, root: root, calendar: calendar)
        }
    }

    func measuredHeight() -> CGFloat {
        let width = max(bounds.width, Space.n(20))
        return stack.systemLayoutSizeFitting(
            CGSize(width: width, height: 0),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height
    }

    @objc private func open(_ sender: SealedCentoCard) {
        guard let cento = sender.cento else { return }
        onOpen?(cento)
    }
}

@MainActor
final class SealedCentoCard: UIButton {
    private(set) var cento: Cento?
    private let day = UILabel()
    private let count = UILabel()
    private let lines = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = Palette.uiSurface
        layer.cornerRadius = Radius.card
        layer.cornerCurve = .continuous
        clipsToBounds = true
        day.font = TypeScale.uiTitle
        day.textColor = Palette.uiInk
        day.numberOfLines = 0
        day.adjustsFontForContentSizeCategory = true
        count.font = TypeScale.uiCaption
        count.textColor = Palette.uiMuted
        count.numberOfLines = 0
        count.adjustsFontForContentSizeCategory = true
        lines.axis = .vertical
        lines.spacing = Space.n(1)
        lines.isUserInteractionEnabled = false
        day.translatesAutoresizingMaskIntoConstraints = false
        count.translatesAutoresizingMaskIntoConstraints = false
        lines.translatesAutoresizingMaskIntoConstraints = false
        day.isUserInteractionEnabled = false
        count.isUserInteractionEnabled = false
        day.setContentHuggingPriority(.required, for: .vertical)
        count.setContentHuggingPriority(.required, for: .vertical)
        lines.setContentHuggingPriority(.required, for: .vertical)
        day.setContentCompressionResistancePriority(.required, for: .vertical)
        count.setContentCompressionResistancePriority(.required, for: .vertical)
        lines.setContentCompressionResistancePriority(.required, for: .vertical)
        let block = UIStackView(arrangedSubviews: [day, count, lines])
        block.axis = .vertical
        block.spacing = Space.n(1)
        block.alignment = .fill
        block.isUserInteractionEnabled = false
        block.translatesAutoresizingMaskIntoConstraints = false
        addSubview(block)
        NSLayoutConstraint.activate([
            block.topAnchor.constraint(equalTo: topAnchor, constant: Space.n(2)),
            block.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Space.gutter),
            block.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Space.gutter),
            block.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Space.n(2)),
        ])
        setContentHuggingPriority(.required, for: .vertical)
        setContentCompressionResistancePriority(.required, for: .vertical)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    func apply(_ cento: Cento, root: StoreRoot, calendar: Calendar) {
        self.cento = cento
        day.text = CentoDates.daykey(cento.daykey, calendar: calendar)
        count.text = CentoFigures.counted(cento.cuttingIDs.count, singular: "sealed line", plural: "sealed lines")
        lines.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let strips = Strip.poem(from: cento, root: root)
        for strip in strips {
            lines.addArrangedSubview(stripPlate(strip))
        }
        let quotes = strips.map(\.text).joined(separator: " ")
        accessibilityLabel = "\(day.text ?? ""). \(count.text ?? ""). \(quotes). Open this sealed cento."
        accessibilityTraits = .button
    }

    private func stripPlate(_ strip: Strip) -> UIView {
        let plate = UIView()
        plate.backgroundColor = Palette.uiBackground
        plate.layer.cornerRadius = Radius.chip
        plate.layer.cornerCurve = .continuous
        plate.isUserInteractionEnabled = false
        let quote = UILabel()
        quote.text = strip.text
        quote.font = TypeScale.uiBody
        quote.textColor = Palette.uiInk
        quote.numberOfLines = 0
        quote.adjustsFontForContentSizeCategory = true
        let source = UILabel()
        let title = strip.volumeTitle.isEmpty ? "Volume" : strip.volumeTitle
        source.text = "\(title), page \(CentoFigures.page(strip.page))"
        source.font = TypeScale.uiCaption
        source.textColor = Palette.uiMuted
        source.numberOfLines = 0
        source.adjustsFontForContentSizeCategory = true
        let stack = UIStackView(arrangedSubviews: [quote, source])
        stack.axis = .vertical
        stack.spacing = Space.unit / 2
        stack.translatesAutoresizingMaskIntoConstraints = false
        plate.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: plate.topAnchor, constant: Space.n(1)),
            stack.leadingAnchor.constraint(equalTo: plate.leadingAnchor, constant: Space.n(1)),
            stack.trailingAnchor.constraint(equalTo: plate.trailingAnchor, constant: -Space.n(1)),
            stack.bottomAnchor.constraint(equalTo: plate.bottomAnchor, constant: -Space.n(1)),
        ])
        return plate
    }
}
