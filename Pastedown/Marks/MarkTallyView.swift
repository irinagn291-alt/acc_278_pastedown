import UIKit

/// Role: ClashMark. Foot counter and clash tally. Monospaced digits. Home surface for the adjacent-volume ban.
@MainActor
final class MarkTallyView: UIView {
    var onClash: (() -> Void)?
    private let content = UIStackView()
    private let lineTitle = UILabel()
    private let lineValue = UILabel()
    private let lineUnit = UILabel()
    private let clashButton = UIButton(type: .system)
    private let clashStack = UIStackView()
    private let clashTitle = UILabel()
    private let clashValue = UILabel()
    private let clashHint = UILabel()
    private let listTitle = UILabel()
    private let list = UIStackView()
    private let listEmpty = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = Palette.uiSurface
        layer.cornerRadius = Radius.card
        layer.cornerCurve = .continuous
        clipsToBounds = true

        content.axis = .vertical
        content.spacing = Space.n(2)
        content.translatesAutoresizingMaskIntoConstraints = false
        content.alignment = .fill
        content.setContentHuggingPriority(.required, for: .vertical)
        content.setContentCompressionResistancePriority(.required, for: .vertical)

        lineTitle.font = TypeScale.uiCaption
        lineTitle.textColor = Palette.uiMuted
        lineTitle.text = "Lines on the board"
        lineTitle.numberOfLines = 0
        lineTitle.adjustsFontForContentSizeCategory = true
        lineTitle.setContentCompressionResistancePriority(.required, for: .vertical)
        lineTitle.setContentHuggingPriority(.required, for: .vertical)
        lineValue.font = TypeScale.uiNumeral
        lineValue.textColor = Palette.uiInk
        lineValue.adjustsFontForContentSizeCategory = true
        lineValue.setContentCompressionResistancePriority(.required, for: .vertical)
        lineUnit.font = TypeScale.uiCaption
        lineUnit.textColor = Palette.uiMuted
        lineUnit.numberOfLines = 0
        lineUnit.adjustsFontForContentSizeCategory = true
        lineUnit.setContentCompressionResistancePriority(.required, for: .vertical)
        lineUnit.setContentHuggingPriority(.required, for: .vertical)

        clashButton.backgroundColor = Palette.uiAccent.withAlphaComponent(0.08)
        clashButton.layer.cornerRadius = Radius.chip
        clashButton.layer.cornerCurve = .continuous
        clashButton.clipsToBounds = true
        clashButton.contentHorizontalAlignment = .fill
        clashButton.contentVerticalAlignment = .fill
        clashButton.accessibilityLabel = "Same-volume pastes refused"
        clashButton.addTarget(self, action: #selector(openClash), for: .touchUpInside)

        clashStack.axis = .vertical
        clashStack.spacing = Space.n(1)
        clashStack.alignment = .fill
        clashStack.isUserInteractionEnabled = false
        clashStack.translatesAutoresizingMaskIntoConstraints = false

        clashTitle.font = TypeScale.uiCaption
        clashTitle.textColor = Palette.uiMuted
        clashTitle.text = "Same-volume pastes refused"
        clashTitle.numberOfLines = 0
        clashTitle.adjustsFontForContentSizeCategory = true
        clashTitle.setContentCompressionResistancePriority(.required, for: .vertical)

        clashValue.font = TypeScale.uiNumeral
        clashValue.textColor = Palette.uiAccent
        clashValue.adjustsFontForContentSizeCategory = true
        clashValue.setContentCompressionResistancePriority(.required, for: .vertical)

        clashHint.font = TypeScale.uiCaption
        clashHint.textColor = Palette.uiMuted
        clashHint.text = "Open clash marks"
        clashHint.numberOfLines = 0
        clashHint.adjustsFontForContentSizeCategory = true
        clashHint.setContentCompressionResistancePriority(.required, for: .vertical)

        listTitle.font = TypeScale.uiTitle
        listTitle.textColor = Palette.uiInk
        listTitle.text = "Clash marks"
        listTitle.numberOfLines = 0
        listTitle.adjustsFontForContentSizeCategory = true

        list.axis = .vertical
        list.spacing = Space.n(1)
        list.alignment = .fill

        listEmpty.font = TypeScale.uiBody
        listEmpty.textColor = Palette.uiMuted
        listEmpty.numberOfLines = 0
        listEmpty.adjustsFontForContentSizeCategory = true
        listEmpty.text = "No same-volume pastes have been refused yet. Paste from another volume to add the next line."

        let lineBlock = UIStackView(arrangedSubviews: [lineTitle, lineValue, lineUnit])
        lineBlock.axis = .vertical
        lineBlock.spacing = Space.unit
        lineBlock.alignment = .leading

        addSubview(content)
        clashStack.addArrangedSubview(clashTitle)
        clashStack.addArrangedSubview(clashValue)
        clashStack.addArrangedSubview(clashHint)
        clashButton.addSubview(clashStack)
        content.addArrangedSubview(lineBlock)
        content.addArrangedSubview(clashButton)
        content.addArrangedSubview(listTitle)
        content.addArrangedSubview(list)
        content.addArrangedSubview(listEmpty)

        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: topAnchor, constant: Space.n(2)),
            content.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Space.gutter),
            content.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Space.gutter),
            content.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Space.n(2)),
            clashButton.heightAnchor.constraint(greaterThanOrEqualToConstant: Space.tap),
            clashStack.topAnchor.constraint(equalTo: clashButton.topAnchor, constant: Space.n(1)),
            clashStack.leadingAnchor.constraint(equalTo: clashButton.leadingAnchor, constant: Space.n(1)),
            clashStack.trailingAnchor.constraint(equalTo: clashButton.trailingAnchor, constant: -Space.n(1)),
            clashStack.bottomAnchor.constraint(equalTo: clashButton.bottomAnchor, constant: -Space.n(1)),
        ])
        setContentHuggingPriority(.required, for: .vertical)
        setContentCompressionResistancePriority(.required, for: .vertical)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    func apply(strips: Int, clashes: Int, rows: [(title: String, detail: String)], showsList: Bool) {
        let lineWord = strips == 1 ? "line" : "lines"
        lineValue.text = CentoFigures.count(strips)
        lineUnit.text = "\(lineWord) pasted onto today's cento"
        clashValue.text = CentoFigures.count(clashes)
        clashHint.text = clashes == 0
            ? "None refused yet. Open clash marks"
            : "\(CentoFigures.counted(clashes, singular: "refused paste", plural: "refused pastes")). Open clash marks"
        clashButton.accessibilityValue = "\(CentoFigures.counted(clashes, singular: "refused paste", plural: "refused pastes")). Opens the clash marks list."
        listTitle.isHidden = !showsList
        list.isHidden = !showsList || rows.isEmpty
        listEmpty.isHidden = !showsList || !rows.isEmpty
        list.arrangedSubviews.forEach { $0.removeFromSuperview() }
        if showsList {
            for row in rows {
                list.addArrangedSubview(listRow(title: row.title, detail: row.detail))
            }
        }
        setContentHuggingPriority(.required, for: .vertical)
        setContentCompressionResistancePriority(.required, for: .vertical)
    }

    private func listRow(title: String, detail: String) -> UIView {
        let button = UIButton(type: .system)
        button.addTarget(self, action: #selector(openClash), for: .touchUpInside)
        let head = UILabel()
        head.text = title
        head.font = TypeScale.uiBody
        head.textColor = Palette.uiInk
        head.numberOfLines = 0
        head.adjustsFontForContentSizeCategory = true
        let foot = UILabel()
        foot.text = detail
        foot.font = TypeScale.uiCaption
        foot.textColor = Palette.uiMuted
        foot.numberOfLines = 0
        foot.adjustsFontForContentSizeCategory = true
        let stack = UIStackView(arrangedSubviews: [head, foot])
        stack.axis = .vertical
        stack.spacing = Space.unit / 2
        stack.isUserInteractionEnabled = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        button.addSubview(stack)
        button.backgroundColor = Palette.uiBackground
        button.layer.cornerRadius = Radius.chip
        button.layer.cornerCurve = .continuous
        button.clipsToBounds = true
        button.accessibilityLabel = "\(title). \(detail). Open clash marks."
        NSLayoutConstraint.activate([
            button.heightAnchor.constraint(greaterThanOrEqualToConstant: Space.tap),
            stack.topAnchor.constraint(equalTo: button.topAnchor, constant: Space.n(1)),
            stack.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: Space.n(1)),
            stack.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -Space.n(1)),
            stack.bottomAnchor.constraint(equalTo: button.bottomAnchor, constant: -Space.n(1)),
        ])
        return button
    }

    @objc private func openClash() {
        onClash?()
    }
}
