import UIKit

/// Role: Drawer. Next cuttings as a scrolling chip strip. All cuttings stays a whole trailing control.
@MainActor
final class DrawerRailView: UIView {
    var onPick: ((CuttingID) -> Void)?
    var onOpenAll: (() -> Void)?
    private let scroller = UIScrollView()
    private let stack = UIStackView()
    private let more = SurfaceActionButton(title: "All cuttings")
    private var tiles: [DrawerTileButton] = []
    private var tileByID: [CuttingID: DrawerTileButton] = [:]
    private var lastCuttings: [Cutting] = []
    private var lastRoot: StoreRoot?
    private var lastFoot: Cutting?
    private var lastSelected: CuttingID?
    private var lastBoarded: Set<CuttingID> = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = Palette.uiBackground
        clipsToBounds = true
        scroller.translatesAutoresizingMaskIntoConstraints = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        scroller.alwaysBounceHorizontal = true
        scroller.alwaysBounceVertical = false
        scroller.showsHorizontalScrollIndicator = true
        scroller.indicatorStyle = .black
        scroller.clipsToBounds = true
        stack.axis = .horizontal
        stack.spacing = Space.n(1)
        stack.alignment = .fill
        stack.distribution = .fill
        more.addTarget(self, action: #selector(openAll), for: .touchUpInside)
        more.accessibilityLabel = "All cuttings"
        more.setCaption("All cuttings")
        more.setContentHuggingPriority(.required, for: .horizontal)
        more.setContentCompressionResistancePriority(.required, for: .horizontal)
        addSubview(scroller)
        addSubview(more)
        scroller.addSubview(stack)
        NSLayoutConstraint.activate([
            heightAnchor.constraint(greaterThanOrEqualToConstant: Space.n(11)),
            scroller.topAnchor.constraint(equalTo: topAnchor),
            scroller.leadingAnchor.constraint(equalTo: leadingAnchor),
            scroller.bottomAnchor.constraint(equalTo: bottomAnchor),
            scroller.trailingAnchor.constraint(equalTo: more.leadingAnchor, constant: -Space.n(1)),
            more.topAnchor.constraint(equalTo: topAnchor, constant: Space.unit),
            more.trailingAnchor.constraint(equalTo: trailingAnchor),
            more.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Space.unit),
            more.widthAnchor.constraint(greaterThanOrEqualToConstant: Space.n(20)),
            stack.topAnchor.constraint(equalTo: scroller.contentLayoutGuide.topAnchor, constant: Space.unit),
            stack.leadingAnchor.constraint(equalTo: scroller.contentLayoutGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: scroller.contentLayoutGuide.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: scroller.contentLayoutGuide.bottomAnchor, constant: -Space.unit),
            stack.heightAnchor.constraint(equalTo: scroller.frameLayoutGuide.heightAnchor, constant: -Space.n(2)),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    func render(
        cuttings: [Cutting],
        root: StoreRoot,
        foot: Cutting?,
        selected: CuttingID?,
        boarded: Set<CuttingID> = []
    ) {
        lastCuttings = cuttings
        lastRoot = root
        lastFoot = foot
        lastSelected = selected
        lastBoarded = boarded
        let ordered = DrawerOrdering.ordered(cuttings).filter { !boarded.contains($0.id) }
        tileByID.removeAll(keepingCapacity: true)
        while tiles.count < ordered.count {
            let tile = DrawerTileButton()
            tile.addTarget(self, action: #selector(pick(_:)), for: .touchUpInside)
            tiles.append(tile)
        }
        while tiles.count > ordered.count {
            let extra = tiles.removeLast()
            extra.removeFromSuperview()
        }
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        stack.axis = .horizontal
        stack.distribution = .fill
        let tileWidth = Space.n(22)
        for (index, cutting) in ordered.enumerated() {
            let allowed = CentoEngine.canFollow(foot: foot, next: cutting)
            let title = root.volume(cutting.volumeID)?.title ?? "Volume"
            tiles[index].setTileWidth(tileWidth)
            tiles[index].apply(
                cutting: cutting,
                volumeTitle: title,
                allowed: allowed,
                chosen: cutting.id == selected
            )
            stack.addArrangedSubview(tiles[index])
            tileByID[cutting.id] = tiles[index]
        }
        more.setCaption("All cuttings")
        invalidateIntrinsicContentSize()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard let root = lastRoot else { return }
        render(
            cuttings: lastCuttings,
            root: root,
            foot: lastFoot,
            selected: lastSelected,
            boarded: lastBoarded
        )
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: Space.n(11))
    }

    func playClash(for id: CuttingID) {
        tileByID[id]?.playClash()
    }

    @objc private func pick(_ sender: DrawerTileButton) {
        guard let id = sender.cuttingID else { return }
        onPick?(id)
    }

    @objc private func openAll() {
        onOpenAll?()
    }
}
