import UIKit

/// Role: Gathering. Sealed-day streak, labeled counts, collage wall, and clash rows.
@MainActor
final class GatheringViewController: UIViewController {
    private let session: CentoSession
    private let scroll = UIScrollView()
    private let page = UIStackView()
    private let job = UILabel()
    private let streak = SealedStreakView()
    private let longest = GatheringMetricCard()
    private let outlived = GatheringMetricCard()
    private let gone = GatheringMetricCard()
    private let metrics = UIStackView()
    private let wallTitle = UILabel()
    private let wall = CollageWallLayer()
    private let emptyCard = UIView()
    private let emptyHeadline = UILabel()
    private let emptyLine = UILabel()
    private let clashTitle = UILabel()
    private let clashStack = UIStackView()
    private let back = GlassActionButton(title: "Back to the board")
    private var clashRows: [ClashMark] = []

    init(session: CentoSession) {
        self.session = session
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Sealed centos"
        view.backgroundColor = Palette.uiBackground
        view.clipsToBounds = true
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Close",
            style: .plain,
            target: self,
            action: #selector(backToBoard)
        )
        navigationItem.leftBarButtonItem?.accessibilityLabel = "Close sealed centos"
        job.text = "Read the sealed-day streak, then open a cento or return to today's board."
        job.font = TypeScale.uiBody
        job.textColor = Palette.uiMuted
        job.numberOfLines = 0
        job.adjustsFontForContentSizeCategory = true

        wallTitle.font = TypeScale.uiTitle
        wallTitle.textColor = Palette.uiInk
        wallTitle.text = "Sealed centos"
        wallTitle.adjustsFontForContentSizeCategory = true
        wallTitle.numberOfLines = 0
        clashTitle.font = TypeScale.uiTitle
        clashTitle.textColor = Palette.uiInk
        clashTitle.text = "Clash marks"
        clashTitle.adjustsFontForContentSizeCategory = true
        clashTitle.numberOfLines = 0

        metrics.axis = .vertical
        metrics.spacing = Space.n(2)
        metrics.distribution = .fill
        metrics.addArrangedSubview(longest)
        let pair = UIStackView(arrangedSubviews: [outlived, gone])
        pair.axis = .horizontal
        pair.spacing = Space.n(2)
        pair.distribution = .fillEqually
        metrics.addArrangedSubview(pair)

        CentoChrome.applyCard(to: emptyCard)
        emptyCard.clipsToBounds = true
        emptyHeadline.font = TypeScale.uiTitle
        emptyHeadline.textColor = Palette.uiInk
        emptyHeadline.numberOfLines = 0
        emptyHeadline.adjustsFontForContentSizeCategory = true
        emptyHeadline.text = "No day has sealed yet."
        emptyLine.font = TypeScale.uiBody
        emptyLine.textColor = Palette.uiMuted
        emptyLine.numberOfLines = 0
        emptyLine.adjustsFontForContentSizeCategory = true
        emptyLine.text = "A day with two or more strips seals at midnight and hangs here."
        emptyHeadline.translatesAutoresizingMaskIntoConstraints = false
        emptyLine.translatesAutoresizingMaskIntoConstraints = false
        emptyCard.addSubview(emptyHeadline)
        emptyCard.addSubview(emptyLine)

        clashStack.axis = .vertical
        clashStack.spacing = Space.n(1)
        back.addTarget(self, action: #selector(backToBoard), for: .touchUpInside)

        page.axis = .vertical
        page.spacing = Space.n(2)
        page.alignment = .fill
        page.translatesAutoresizingMaskIntoConstraints = false
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.alwaysBounceVertical = true
        [job, streak, metrics, wallTitle, wall, emptyCard, clashTitle, clashStack].forEach {
            page.addArrangedSubview($0)
            $0.setContentHuggingPriority(.required, for: .vertical)
            $0.setContentCompressionResistancePriority(.required, for: .vertical)
        }
        scroll.addSubview(page)
        view.addSubview(scroll)
        view.addSubview(back)
        back.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: Space.unit),
            scroll.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: Space.gutter),
            scroll.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -Space.gutter),
            scroll.bottomAnchor.constraint(equalTo: back.topAnchor, constant: -Space.n(1)),
            back.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: Space.gutter),
            back.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -Space.gutter),
            back.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -Space.n(2)),
            page.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor),
            page.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor),
            page.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor),
            page.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor),
            page.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor),
            emptyHeadline.topAnchor.constraint(equalTo: emptyCard.topAnchor, constant: Space.n(2)),
            emptyHeadline.leadingAnchor.constraint(equalTo: emptyCard.leadingAnchor, constant: Space.gutter),
            emptyHeadline.trailingAnchor.constraint(equalTo: emptyCard.trailingAnchor, constant: -Space.gutter),
            emptyLine.topAnchor.constraint(equalTo: emptyHeadline.bottomAnchor, constant: Space.unit),
            emptyLine.leadingAnchor.constraint(equalTo: emptyHeadline.leadingAnchor),
            emptyLine.trailingAnchor.constraint(equalTo: emptyHeadline.trailingAnchor),
            emptyLine.bottomAnchor.constraint(equalTo: emptyCard.bottomAnchor, constant: -Space.n(2)),
        ])

        wall.onOpen = { [weak self] cento in
            guard let self else { return }
            let reader = SealedCentoReaderViewController(session: self.session, cento: cento)
            self.navigationController?.pushViewController(reader, animated: !Motion.reduce)
        }
        reload()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reload()
    }

    private func reload() {
        let tally = GatheringTally.from(session.root, today: session.today, calendar: session.calendar)
        let week = GatheringTally.week(ending: session.today, centos: session.root.centos, calendar: session.calendar)
        streak.apply(streak: tally.consecutiveSealedDays, days: week)
        longest.apply(
            title: "Longest sealed cento",
            value: tally.longestCento == 0
                ? "No sealed cento yet"
                : CentoFigures.counted(tally.longestCento, singular: "line", plural: "lines")
        )
        outlived.apply(
            title: "Lines that outlived their volume",
            value: tally.outlivedLineCount == 0
                ? "None yet"
                : CentoFigures.counted(tally.outlivedLineCount, singular: "line", plural: "lines")
        )
        gone.apply(
            title: "Gone volumes on those lines",
            value: tally.goneVolumeCount == 0
                ? "None yet"
                : CentoFigures.counted(tally.goneVolumeCount, singular: "volume", plural: "volumes")
        )
        let sealed = session.root.centos.filter { $0.seal == .sealed }
        wall.isHidden = sealed.isEmpty
        wallTitle.isHidden = sealed.isEmpty
        emptyCard.isHidden = !sealed.isEmpty
        wall.render(sealed, root: session.root, calendar: session.calendar)
        clashRows = session.root.clashMarks.reversed()
        rebuildClashRows()
    }

    private func rebuildClashRows() {
        clashStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        if clashRows.isEmpty {
            clashStack.addArrangedSubview(
                clashCard(
                    title: "No clashes yet.",
                    detail: "A same-volume paste writes a mark and keeps the foot.",
                    mark: nil
                )
            )
            return
        }
        for mark in clashRows {
            let refused = session.root.cutting(mark.refusedID)?.text ?? "A cutting"
            clashStack.addArrangedSubview(
                clashCard(
                    title: refused,
                    detail: CentoDates.daykey(mark.daykey, calendar: session.calendar),
                    mark: mark
                )
            )
        }
    }

    private func clashCard(title: String, detail: String, mark: ClashMark?) -> UIButton {
        let button = UIButton(type: .system)
        button.addTarget(self, action: #selector(openClash), for: .touchUpInside)
        button.isEnabled = mark != nil
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
        button.backgroundColor = Palette.uiSurface
        button.layer.cornerRadius = Radius.card
        button.layer.cornerCurve = .continuous
        button.clipsToBounds = true
        button.accessibilityLabel = mark == nil ? "\(title) \(detail)" : "\(title). \(detail). Open clash marks."
        NSLayoutConstraint.activate([
            button.heightAnchor.constraint(greaterThanOrEqualToConstant: Space.tap),
            stack.topAnchor.constraint(equalTo: button.topAnchor, constant: Space.n(2)),
            stack.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: Space.gutter),
            stack.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -Space.gutter),
            stack.bottomAnchor.constraint(equalTo: button.bottomAnchor, constant: -Space.n(2)),
        ])
        return button
    }

    @objc private func openClash() {
        guard !clashRows.isEmpty else { return }
        let sheet = ClashMarkSheetViewController(session: session)
        navigationController?.pushViewController(sheet, animated: !Motion.reduce)
    }

    @objc private func backToBoard() {
        dismiss(animated: !Motion.reduce)
    }
}
