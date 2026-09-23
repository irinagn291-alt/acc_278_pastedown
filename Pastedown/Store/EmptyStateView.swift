import UIKit

/// Role: Store. Full-page empty surface. Art, one headline, one line, one full-width action.
@MainActor
final class EmptyStateView: UIView {
    private let art = UIImageView()
    private let headline = UILabel()
    private let line = UILabel()
    private let action = GlassActionButton(title: "Continue")
    var onAction: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = Palette.uiBackground
        art.contentMode = .scaleAspectFit
        art.isAccessibilityElement = false
        headline.font = TypeScale.uiTitle
        headline.textColor = Palette.uiInk
        headline.numberOfLines = 2
        headline.adjustsFontForContentSizeCategory = true
        line.font = TypeScale.uiBody
        line.textColor = Palette.uiMuted
        line.numberOfLines = 0
        line.adjustsFontForContentSizeCategory = true
        art.translatesAutoresizingMaskIntoConstraints = false
        headline.translatesAutoresizingMaskIntoConstraints = false
        line.translatesAutoresizingMaskIntoConstraints = false
        action.translatesAutoresizingMaskIntoConstraints = false
        addSubview(art)
        addSubview(headline)
        addSubview(line)
        addSubview(action)
        action.addTarget(self, action: #selector(tap), for: .touchUpInside)
        NSLayoutConstraint.activate([
            art.topAnchor.constraint(equalTo: topAnchor, constant: Space.n(3)),
            art.centerXAnchor.constraint(equalTo: centerXAnchor),
            art.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.46),
            art.heightAnchor.constraint(equalTo: art.widthAnchor),
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

    func apply(art name: String, headline: String, line: String, action title: String, onAction: (() -> Void)?) {
        self.onAction = onAction
        art.image = UIImage(named: name)
        art.isHidden = art.image == nil
        self.headline.text = headline
        self.line.text = line
        action.setCaption(title)
    }

    @objc private func tap() {
        onAction?()
    }
}
