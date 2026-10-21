import UIKit

/// Role: Store. Full-page empty surface. Art, one headline, one line, one full-width action.
/// The art size is a constant derived from the view's own bounds, so a large source image
/// cannot stretch the page past the screen.
@MainActor
final class EmptyStateView: UIView {
    private let art = UIImageView()
    private let headline = UILabel()
    private let line = UILabel()
    private let action = GlassActionButton(title: "Continue")
    private let artSide: NSLayoutConstraint
    var onAction: (() -> Void)?

    override init(frame: CGRect) {
        artSide = art.widthAnchor.constraint(equalToConstant: Space.n(20))
        super.init(frame: frame)
        backgroundColor = Palette.uiBackground
        clipsToBounds = true
        art.contentMode = .scaleAspectFit
        art.isAccessibilityElement = false
        art.setContentHuggingPriority(.defaultLow, for: .horizontal)
        art.setContentHuggingPriority(.defaultLow, for: .vertical)
        art.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        art.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        headline.font = TypeScale.uiTitle
        headline.textColor = Palette.uiInk
        headline.numberOfLines = 0
        headline.adjustsFontForContentSizeCategory = true
        headline.setContentCompressionResistancePriority(.required, for: .vertical)
        line.font = TypeScale.uiBody
        line.textColor = Palette.uiMuted
        line.numberOfLines = 0
        line.adjustsFontForContentSizeCategory = true
        line.setContentCompressionResistancePriority(.required, for: .vertical)
        art.translatesAutoresizingMaskIntoConstraints = false
        headline.translatesAutoresizingMaskIntoConstraints = false
        line.translatesAutoresizingMaskIntoConstraints = false
        action.translatesAutoresizingMaskIntoConstraints = false
        addSubview(art)
        addSubview(headline)
        addSubview(line)
        addSubview(action)
        action.addTarget(self, action: #selector(tap), for: .touchUpInside)
        let square = art.heightAnchor.constraint(equalTo: art.widthAnchor)
        square.priority = UILayoutPriority(999)
        NSLayoutConstraint.activate([
            art.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: Space.n(3)),
            art.centerXAnchor.constraint(equalTo: centerXAnchor),
            artSide,
            square,
            art.heightAnchor.constraint(lessThanOrEqualTo: heightAnchor, multiplier: 0.42),
            headline.topAnchor.constraint(equalTo: art.bottomAnchor, constant: Space.n(2)),
            headline.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Space.gutter),
            headline.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Space.gutter),
            line.topAnchor.constraint(equalTo: headline.bottomAnchor, constant: Space.n(1)),
            line.leadingAnchor.constraint(equalTo: headline.leadingAnchor),
            line.trailingAnchor.constraint(equalTo: headline.trailingAnchor),
            action.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Space.gutter),
            action.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Space.gutter),
            action.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -Space.n(2)),
            line.bottomAnchor.constraint(lessThanOrEqualTo: action.topAnchor, constant: -Space.n(2)),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override func layoutSubviews() {
        let side = fittedArtSide(in: bounds.size)
        if abs(artSide.constant - side) > 0.5 {
            artSide.constant = side
        }
        super.layoutSubviews()
    }

    func apply(art name: String, headline: String, line: String, action title: String, onAction: (() -> Void)?) {
        self.onAction = onAction
        art.image = UIImage(named: name)
        art.isHidden = art.image == nil
        self.headline.text = headline
        self.line.text = line
        action.setCaption(title)
        setNeedsLayout()
    }

    /// Largest square that stays on screen: under half the width, under the room left for copy and the action.
    func fittedArtSide(in size: CGSize) -> CGFloat {
        guard size.width > 1, size.height > 1 else { return 0 }
        let textWidth = max(size.width - Space.gutter * 2, 1)
        let headlineHeight = headline.sizeThatFits(CGSize(width: textWidth, height: size.height)).height
        let lineHeight = line.sizeThatFits(CGSize(width: textWidth, height: size.height)).height
        let actionHeight = max(action.intrinsicContentSize.height, Space.tap)
        let chrome = Space.n(3) + Space.n(2) + headlineHeight + Space.n(1) + lineHeight + Space.n(2) + actionHeight + Space.n(2)
        let room = max(size.height - chrome, 0)
        let cap = min(size.width * 0.46, size.height * 0.42, room)
        return max(cap, 0)
    }

    @objc private func tap() {
        onAction?()
    }
}
