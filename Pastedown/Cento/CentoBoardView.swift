import UIKit

/// Role: Cento. Owns one scrolling canvas layer inside a UIScrollView. Home mechanic surface.
@MainActor
final class CentoBoardView: UIView {
    let scroller = UIScrollView()
    let canvasHost = UIView()
    let canvas = CentoBoardLayer()
    private let emptyCard = UIView()
    private let emptyTitle = UILabel()
    private let emptyLine = UILabel()
    private let emptyAction = SurfaceActionButton(title: "Open Cuttings")
    private let verseCard = UIView()
    private let verseTitle = UILabel()
    private let verseBody = UILabel()
    private var lastStrips: [Strip] = []
    private var lastWidth: CGFloat = 0
    private var lastHeight: CGFloat = 0
    private var lastBlankCopy: (headline: String, line: String, action: String?)?
    private var lastBlankAction: (() -> Void)?
    private let column = UIStackView()
    private var hostHeight: NSLayoutConstraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = Palette.uiBackground
        clipsToBounds = true
        scroller.translatesAutoresizingMaskIntoConstraints = false
        canvasHost.translatesAutoresizingMaskIntoConstraints = false
        emptyCard.translatesAutoresizingMaskIntoConstraints = false
        scroller.alwaysBounceVertical = true
        scroller.showsVerticalScrollIndicator = true
        scroller.contentInsetAdjustmentBehavior = .never
        scroller.clipsToBounds = true
        canvasHost.layer.addSublayer(canvas)
        canvasHost.clipsToBounds = true
        verseCard.translatesAutoresizingMaskIntoConstraints = false
        CentoChrome.applyCard(to: verseCard)
        verseCard.clipsToBounds = true
        verseTitle.font = TypeScale.uiCaption
        verseTitle.textColor = Palette.uiMuted
        verseTitle.text = "Cento so far"
        verseTitle.numberOfLines = 0
        verseTitle.adjustsFontForContentSizeCategory = true
        verseBody.font = TypeScale.uiBody
        verseBody.textColor = Palette.uiInk
        verseBody.numberOfLines = 0
        verseBody.adjustsFontForContentSizeCategory = true
        verseTitle.translatesAutoresizingMaskIntoConstraints = false
        verseBody.translatesAutoresizingMaskIntoConstraints = false
        verseCard.addSubview(verseTitle)
        verseCard.addSubview(verseBody)
        column.axis = .vertical
        column.spacing = Space.n(1)
        column.alignment = .fill
        column.translatesAutoresizingMaskIntoConstraints = false
        column.addArrangedSubview(verseCard)
        column.addArrangedSubview(canvasHost)
        addSubview(scroller)
        scroller.addSubview(column)
        addSubview(emptyCard)
        isAccessibilityElement = false

        CentoChrome.applyCard(to: emptyCard)
        emptyCard.clipsToBounds = true
        emptyTitle.font = TypeScale.uiTitle
        emptyTitle.textColor = Palette.uiInk
        emptyTitle.numberOfLines = 0
        emptyTitle.adjustsFontForContentSizeCategory = true
        emptyLine.font = TypeScale.uiBody
        emptyLine.textColor = Palette.uiMuted
        emptyLine.numberOfLines = 0
        emptyLine.adjustsFontForContentSizeCategory = true
        emptyTitle.translatesAutoresizingMaskIntoConstraints = false
        emptyLine.translatesAutoresizingMaskIntoConstraints = false
        emptyAction.translatesAutoresizingMaskIntoConstraints = false
        emptyAction.addTarget(self, action: #selector(tapEmpty), for: .touchUpInside)
        let emptyStack = UIStackView(arrangedSubviews: [emptyTitle, emptyLine, emptyAction])
        emptyStack.axis = .vertical
        emptyStack.spacing = Space.n(1)
        emptyStack.translatesAutoresizingMaskIntoConstraints = false
        emptyCard.addSubview(emptyStack)

        hostHeight = canvasHost.heightAnchor.constraint(equalToConstant: Space.n(8))
        hostHeight?.isActive = true
        NSLayoutConstraint.activate([
            scroller.topAnchor.constraint(equalTo: topAnchor),
            scroller.leadingAnchor.constraint(equalTo: leadingAnchor),
            scroller.trailingAnchor.constraint(equalTo: trailingAnchor),
            scroller.bottomAnchor.constraint(equalTo: bottomAnchor),
            column.topAnchor.constraint(equalTo: scroller.contentLayoutGuide.topAnchor),
            column.leadingAnchor.constraint(equalTo: scroller.contentLayoutGuide.leadingAnchor),
            column.trailingAnchor.constraint(equalTo: scroller.contentLayoutGuide.trailingAnchor),
            column.bottomAnchor.constraint(equalTo: scroller.contentLayoutGuide.bottomAnchor),
            column.widthAnchor.constraint(equalTo: scroller.frameLayoutGuide.widthAnchor),
            verseTitle.topAnchor.constraint(equalTo: verseCard.topAnchor, constant: Space.n(2)),
            verseTitle.leadingAnchor.constraint(equalTo: verseCard.leadingAnchor, constant: Space.gutter),
            verseTitle.trailingAnchor.constraint(equalTo: verseCard.trailingAnchor, constant: -Space.gutter),
            verseBody.topAnchor.constraint(equalTo: verseTitle.bottomAnchor, constant: Space.unit),
            verseBody.leadingAnchor.constraint(equalTo: verseTitle.leadingAnchor),
            verseBody.trailingAnchor.constraint(equalTo: verseTitle.trailingAnchor),
            verseBody.bottomAnchor.constraint(equalTo: verseCard.bottomAnchor, constant: -Space.n(2)),
            emptyCard.topAnchor.constraint(equalTo: topAnchor, constant: Space.n(1)),
            emptyCard.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Space.gutter),
            emptyCard.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Space.gutter),
            emptyCard.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -Space.n(1)),
            emptyStack.topAnchor.constraint(equalTo: emptyCard.topAnchor, constant: Space.n(2)),
            emptyStack.leadingAnchor.constraint(equalTo: emptyCard.leadingAnchor, constant: Space.gutter),
            emptyStack.trailingAnchor.constraint(equalTo: emptyCard.trailingAnchor, constant: -Space.gutter),
            emptyStack.bottomAnchor.constraint(equalTo: emptyCard.bottomAnchor, constant: -Space.n(2)),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    func render(
        strips: [Strip],
        pasted: CuttingID?,
        clash: CuttingID?,
        blankCopy: (headline: String, line: String, action: String?)?,
        onBlank: (() -> Void)?
    ) {
        lastStrips = strips
        lastWidth = bounds.width
        lastHeight = bounds.height
        lastBlankCopy = blankCopy
        lastBlankAction = onBlank
        let width = max(bounds.width, Space.n(20))
        let height = canvas.render(
            strips: strips,
            width: width,
            scale: window?.screen.scale ?? traitCollection.displayScale,
            pasted: pasted,
            clash: clash,
            minHeight: 0
        )
        canvas.frame = CGRect(x: 0, y: 0, width: width, height: height)
        canvasHost.bounds = canvas.frame
        hostHeight?.constant = max(height, Space.n(8))
        if let blankCopy, strips.isEmpty {
            emptyCard.isHidden = false
            emptyTitle.text = blankCopy.headline
            emptyLine.text = blankCopy.line
            if let action = blankCopy.action {
                emptyAction.isHidden = false
                emptyAction.isEnabled = true
                emptyAction.setCaption(action)
            } else {
                emptyAction.isHidden = true
            }
        } else {
            emptyCard.isHidden = true
        }
        if strips.isEmpty {
            verseCard.isHidden = true
            verseBody.text = nil
        } else {
            verseCard.isHidden = false
            verseBody.text = strips.map(\.text).joined(separator: "\n")
        }
        rebuildAccess()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard abs(bounds.width - lastWidth) > 0.5 || abs(bounds.height - lastHeight) > 0.5 else { return }
        render(
            strips: lastStrips,
            pasted: nil,
            clash: nil,
            blankCopy: emptyCard.isHidden ? nil : lastBlankCopy,
            onBlank: lastBlankAction
        )
    }

    @objc private func tapEmpty() {
        lastBlankAction?()
    }

    private func rebuildAccess() {
        var elements: [UIAccessibilityElement] = []
        for strip in canvas.strips {
            guard let frame = canvas.frames[strip.cuttingID] else { continue }
            let element = UIAccessibilityElement(accessibilityContainer: self)
            let seat = CentoFigures.count(strip.seat + 1)
            let volume = strip.volumeTitle.isEmpty ? "Volume" : strip.volumeTitle
            element.accessibilityLabel = "\(strip.text). \(volume). Seat \(seat)."
            element.accessibilityFrameInContainerSpace = frame
            elements.append(element)
        }
        accessibilityElements = elements
    }
}

/// Role: Cento. Bounded next-line slot. Own row under the canvas, never drawn over the drawer.
@MainActor
final class CentoSlotCard: UIView {
    private let title = UILabel()
    private let line = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = Palette.uiAccent.withAlphaComponent(0.08)
        layer.cornerRadius = Radius.card
        layer.cornerCurve = .continuous
        clipsToBounds = true
        title.font = TypeScale.uiTitle
        title.textColor = Palette.uiInk
        title.text = "Next line lands here"
        title.numberOfLines = 0
        title.adjustsFontForContentSizeCategory = true
        title.setContentCompressionResistancePriority(.required, for: .vertical)
        title.setContentHuggingPriority(.required, for: .vertical)
        line.font = TypeScale.uiBody
        line.textColor = Palette.uiMuted
        line.text = "Select a cutting in the drawer, then tap Paste."
        line.numberOfLines = 0
        line.adjustsFontForContentSizeCategory = true
        line.setContentCompressionResistancePriority(.required, for: .vertical)
        line.setContentHuggingPriority(.required, for: .vertical)
        title.translatesAutoresizingMaskIntoConstraints = false
        line.translatesAutoresizingMaskIntoConstraints = false
        addSubview(title)
        addSubview(line)
        NSLayoutConstraint.activate([
            title.topAnchor.constraint(equalTo: topAnchor, constant: Space.n(2)),
            title.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Space.gutter),
            title.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Space.gutter),
            line.topAnchor.constraint(equalTo: title.bottomAnchor, constant: Space.unit),
            line.leadingAnchor.constraint(equalTo: title.leadingAnchor),
            line.trailingAnchor.constraint(equalTo: title.trailingAnchor),
            line.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Space.n(2)),
            heightAnchor.constraint(greaterThanOrEqualToConstant: Space.n(10)),
        ])
        setContentHuggingPriority(.required, for: .vertical)
        setContentCompressionResistancePriority(.required, for: .vertical)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }
}
