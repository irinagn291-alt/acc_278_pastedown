import UIKit

/// Role: Cento. Root screen. The paste-up board never leaves home. Sheets arrive over it.
@MainActor
final class CentoBoardViewController: UIViewController {
    let session: CentoSession
    private let page = UIStackView()
    private let header = UIStackView()
    private let job = UILabel()
    private let nextTap = UILabel()
    private let topRail = UIStackView()
    private let workspace = UIView()
    private let board = CentoBoardView()
    private let gutter = MarkTallyView()
    private let slot = CentoSlotCard()
    private let rail = DrawerRailView()
    private let paste = GlassActionButton(title: "Paste", showsFace: true)
    private let peel = SurfaceActionButton(title: "Peel")
    private let actions = UIStackView()
    private let banner = UILabel()
    private let success = UIImageView()
    private lazy var cuttingsButton = CentoChrome.iconButton(
        symbol: "text.quote",
        label: "Cuttings",
        target: self,
        action: #selector(openCuttings)
    )
    private lazy var volumesButton = CentoChrome.iconButton(
        symbol: "books.vertical",
        label: "Volumes",
        target: self,
        action: #selector(openVolumes)
    )
    private lazy var gatheringButton = CentoChrome.iconButton(
        symbol: "square.grid.2x2",
        label: "Sealed",
        target: self,
        action: #selector(openGathering)
    )
    private lazy var settingsButton = CentoChrome.iconButton(
        symbol: "gearshape",
        label: "Settings",
        target: self,
        action: #selector(openSettings)
    )
    private var lastPasted: CuttingID?
    private var lastClashFoot: CuttingID?
    private var pasteBusy = false
    private var regularConstraints: [NSLayoutConstraint] = []
    private var compactConstraints: [NSLayoutConstraint] = []
    private var pasteWidth: NSLayoutConstraint?
    private var boardMinHeight: NSLayoutConstraint?

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
        view.backgroundColor = Palette.uiBackground
        view.clipsToBounds = true
        job.text = "Build today's cento"
        job.font = TypeScale.uiTitle
        job.textColor = Palette.uiInk
        job.numberOfLines = 0
        job.adjustsFontForContentSizeCategory = true
        job.setContentCompressionResistancePriority(.required, for: .vertical)
        job.setContentHuggingPriority(.required, for: .vertical)
        nextTap.text = "Select a cutting in the drawer, then tap Paste to add the next line."
        nextTap.font = TypeScale.uiBody
        nextTap.textColor = Palette.uiMuted
        nextTap.numberOfLines = 0
        nextTap.adjustsFontForContentSizeCategory = true
        nextTap.setContentCompressionResistancePriority(.required, for: .vertical)
        nextTap.setContentHuggingPriority(.required, for: .vertical)
        banner.font = TypeScale.uiCaption
        banner.textColor = Palette.uiMuted
        banner.numberOfLines = 0
        banner.adjustsFontForContentSizeCategory = true
        banner.setContentCompressionResistancePriority(.required, for: .vertical)
        success.image = UIImage(named: "pdn_SuccessMark")
        success.contentMode = .scaleAspectFit
        success.alpha = 0
        success.isAccessibilityElement = false
        gatheringButton.accessibilityLabel = "Sealed centos"
        topRail.axis = .horizontal
        topRail.spacing = Space.unit
        topRail.alignment = .fill
        topRail.distribution = .fillEqually
        topRail.setContentHuggingPriority(.required, for: .vertical)
        topRail.setContentCompressionResistancePriority(.required, for: .vertical)
        header.axis = .vertical
        header.spacing = Space.unit
        header.alignment = .fill
        header.setContentHuggingPriority(.required, for: .vertical)
        header.setContentCompressionResistancePriority(.required, for: .vertical)
        actions.axis = .horizontal
        actions.spacing = Space.n(1)
        actions.distribution = .fill
        actions.setContentHuggingPriority(.required, for: .vertical)
        actions.setContentCompressionResistancePriority(.required, for: .vertical)
        page.axis = .vertical
        page.spacing = Space.n(1)
        page.alignment = .fill
        page.translatesAutoresizingMaskIntoConstraints = false
        workspace.translatesAutoresizingMaskIntoConstraints = false
        workspace.backgroundColor = Palette.uiBackground
        paste.addTarget(self, action: #selector(pasteTapped), for: .touchUpInside)
        peel.addTarget(self, action: #selector(peelTapped), for: .touchUpInside)
        rail.onPick = { [weak self] id in
            self?.session.selectedCuttingID = id
            self?.reload(animated: false)
        }
        rail.onOpenAll = { [weak self] in
            self?.openCuttings()
        }
        gutter.onClash = { [weak self] in
            self?.openClash()
        }

        header.addArrangedSubview(job)
        header.addArrangedSubview(nextTap)
        header.addArrangedSubview(banner)
        header.addArrangedSubview(topRail)
        [header, workspace, slot, rail].forEach { page.addArrangedSubview($0) }
        view.addSubview(page)
        view.addSubview(actions)
        view.addSubview(success)
        workspace.addSubview(board)
        workspace.addSubview(gutter)
        [board, gutter, slot, rail, actions, success].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        workspace.setContentHuggingPriority(.defaultLow, for: .vertical)
        workspace.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        board.setContentHuggingPriority(.defaultLow, for: .vertical)
        board.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        slot.setContentHuggingPriority(.required, for: .vertical)
        slot.setContentCompressionResistancePriority(.required, for: .vertical)
        rail.setContentHuggingPriority(.required, for: .vertical)
        rail.setContentCompressionResistancePriority(.required, for: .vertical)
        gutter.setContentHuggingPriority(.required, for: .vertical)
        gutter.setContentCompressionResistancePriority(.required, for: .vertical)

        topRail.addArrangedSubview(cuttingsButton)
        topRail.addArrangedSubview(volumesButton)
        topRail.addArrangedSubview(gatheringButton)
        topRail.addArrangedSubview(settingsButton)
        actions.addArrangedSubview(paste)
        actions.addArrangedSubview(peel)
        pasteWidth = paste.widthAnchor.constraint(equalTo: actions.widthAnchor, multiplier: 0.62)
        boardMinHeight = board.heightAnchor.constraint(greaterThanOrEqualToConstant: Space.n(22))

        let gutterPad = Space.gutter
        NSLayoutConstraint.activate([
            page.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: Space.unit),
            page.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: gutterPad),
            page.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -gutterPad),
            page.bottomAnchor.constraint(equalTo: actions.topAnchor, constant: -Space.n(1)),

            actions.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: gutterPad),
            actions.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -gutterPad),
            actions.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -Space.n(2)),

            rail.heightAnchor.constraint(greaterThanOrEqualToConstant: Space.n(11)),

            success.centerXAnchor.constraint(equalTo: board.centerXAnchor),
            success.centerYAnchor.constraint(equalTo: board.centerYAnchor),
            success.widthAnchor.constraint(equalToConstant: Space.n(8)),
            success.heightAnchor.constraint(equalToConstant: Space.n(8)),
        ])

        regularConstraints = [
            board.topAnchor.constraint(equalTo: workspace.topAnchor),
            board.leadingAnchor.constraint(equalTo: workspace.leadingAnchor),
            board.bottomAnchor.constraint(equalTo: workspace.bottomAnchor),
            board.trailingAnchor.constraint(equalTo: gutter.leadingAnchor, constant: -Space.n(2)),
            gutter.topAnchor.constraint(equalTo: workspace.topAnchor),
            gutter.trailingAnchor.constraint(equalTo: workspace.trailingAnchor),
            gutter.bottomAnchor.constraint(lessThanOrEqualTo: workspace.bottomAnchor),
            gutter.widthAnchor.constraint(equalTo: workspace.widthAnchor, multiplier: 1.0 / 3.0),
        ]
        compactConstraints = [
            gutter.topAnchor.constraint(equalTo: workspace.topAnchor),
            gutter.leadingAnchor.constraint(equalTo: workspace.leadingAnchor),
            gutter.trailingAnchor.constraint(equalTo: workspace.trailingAnchor),
            board.topAnchor.constraint(equalTo: gutter.bottomAnchor, constant: Space.n(1)),
            board.leadingAnchor.constraint(equalTo: workspace.leadingAnchor),
            board.trailingAnchor.constraint(equalTo: workspace.trailingAnchor),
            board.bottomAnchor.constraint(equalTo: workspace.bottomAnchor),
        ]

        session.onChange = { [weak self] in
            self?.reload(animated: false)
        }
        applySplit(for: traitCollection)
        reload(animated: false)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reload(animated: false)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        applySplit(for: traitCollection)
    }

    func applyReviewHookIfNeeded() {
        guard let destination = session.consumeReviewDestination() else { return }
        switch destination {
        case .today, .cento:
            break
        case .log, .cuttings:
            openCuttings()
        case .goals, .gathering:
            openGathering()
        case .volumes, .sold, .lent, .lost:
            openVolumes()
        case .settings:
            openSettings()
        }
    }

    private func applySplit(for traits: UITraitCollection) {
        let regular = traits.horizontalSizeClass == .regular
        NSLayoutConstraint.deactivate(regularConstraints)
        NSLayoutConstraint.deactivate(compactConstraints)
        if regular {
            NSLayoutConstraint.activate(regularConstraints)
            actions.axis = .horizontal
            pasteWidth?.isActive = true
            boardMinHeight?.isActive = false
            gutter.setContentHuggingPriority(.required, for: .vertical)
        } else {
            NSLayoutConstraint.activate(compactConstraints)
            actions.axis = .vertical
            pasteWidth?.isActive = false
            boardMinHeight?.isActive = true
            gutter.setContentHuggingPriority(.required, for: .vertical)
        }
        nextTap.font = regular ? TypeScale.uiCallout : TypeScale.uiBody
        job.font = regular ? TypeScale.uiDisplay : TypeScale.uiTitle
        slot.isHidden = session.todayStrips.isEmpty
        reload(animated: false)
    }

    private func reload(animated: Bool) {
        let strips = session.todayStrips
        let clashes = session.root.clashMarks
        let regular = traitCollection.horizontalSizeClass == .regular
        board.render(
            strips: strips,
            pasted: lastPasted,
            clash: lastClashFoot,
            blankCopy: strips.isEmpty
                ? (
                    "No lines on today's cento yet.",
                    session.root.cuttings.isEmpty
                        ? "Write a cutting, then paste it as the first line."
                        : "Pick a cutting in the drawer, then tap Paste to add the next line.",
                    session.root.cuttings.isEmpty ? "Open Cuttings" : nil
                )
                : nil,
            onBlank: { [weak self] in
                self?.openCuttings()
            }
        )
        slot.isHidden = strips.isEmpty
        slot.isAccessibilityElement = !strips.isEmpty
        rail.render(
            cuttings: session.root.cuttings,
            root: session.root,
            foot: session.footCutting,
            selected: session.selectedCuttingID,
            boarded: Set(session.todayCento.cuttingIDs)
        )
        let rows = clashes.reversed().map { mark in
            let refused = self.session.root.cutting(mark.refusedID)?.text ?? "A cutting"
            return (refused, CentoDates.daykey(mark.daykey, calendar: self.session.calendar))
        }
        gutter.apply(strips: strips.count, clashes: clashes.count, rows: rows, showsList: regular)
        paste.isEnabled = session.pasteIsEnabled && !pasteBusy
        peel.isEnabled = session.peelIsEnabled && !pasteBusy
        if let warning = session.warning {
            banner.isHidden = false
            switch warning {
            case .recoveredFromBackup:
                banner.text = "The last save was recovered from a backup copy."
            case .startedEmpty:
                banner.text = "The store could not be read, so the board started empty."
            }
        } else if let persistError = session.persistError {
            banner.isHidden = false
            banner.text = persistError
        } else {
            banner.isHidden = true
            banner.text = nil
        }
        lastPasted = nil
        lastClashFoot = nil
        view.setNeedsLayout()
        if animated { return }
    }

    @objc private func pasteTapped() {
        guard !pasteBusy, let id = session.pasteTargetID() else { return }
        pasteBusy = true
        paste.isEnabled = false
        Task {
            do {
                let outcome = try await session.commit(.paste(id, at: Date()))
                if case .clash = outcome.mark {
                    lastClashFoot = session.todayCento.footID
                    rail.playClash(for: id)
                    board.canvas.footLayer()?.playClash()
                    UIAccessibility.post(notification: .announcement, argument: "Same volume. The foot keeps its line.")
                } else {
                    lastPasted = id
                    flashSuccess()
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                    if session.root.onboardingComplete == false {
                        await session.finishOnboarding()
                    }
                }
            } catch let fault as CentoFault {
                banner.isHidden = false
                banner.text = fault.boardLine
            } catch {
                banner.isHidden = false
                banner.text = "Paste could not be stored."
            }
            pasteBusy = false
            reload(animated: false)
        }
    }

    @objc private func peelTapped() {
        guard !pasteBusy else { return }
        pasteBusy = true
        Task {
            do {
                _ = try await session.commit(.peel(at: Date()))
            } catch let fault as CentoFault {
                banner.isHidden = false
                banner.text = fault.boardLine
            } catch {
                banner.isHidden = false
                banner.text = "Peel could not be stored."
            }
            pasteBusy = false
            reload(animated: false)
        }
    }

    private func flashSuccess() {
        guard success.image != nil else { return }
        if Motion.reduce {
            success.alpha = 0
            return
        }
        success.alpha = 1
        UIView.animate(withDuration: Motion.duration, delay: Motion.duration, options: .curveEaseOut) {
            self.success.alpha = 0
        }
    }

    @objc func openCuttings() {
        let sheet = DrawerSheetViewController(session: session)
        CentoChrome.presentSheet(sheet, from: self, prefersLarge: true)
    }

    @objc func openVolumes() {
        let sheet = VolumesSheetViewController(session: session)
        CentoChrome.presentSheet(sheet, from: self)
    }

    @objc func openGathering() {
        let sheet = GatheringViewController(session: session)
        CentoChrome.presentSheet(sheet, from: self, prefersLarge: true)
    }

    @objc func openSettings() {
        let sheet = SettingsViewController(session: session)
        sheet.onReplayOnboarding = { [weak self] in
            guard let self else { return }
            let onboarding = OnboardingViewController(session: self.session)
            CentoChrome.presentFull(onboarding, from: self)
        }
        CentoChrome.presentSheet(sheet, from: self)
    }

    func openClash() {
        let sheet = ClashMarkSheetViewController(session: session)
        CentoChrome.presentSheet(sheet, from: self)
    }
}
