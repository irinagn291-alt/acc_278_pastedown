import UIKit

/// Role: Gathering. One labeled count. The value sits directly under its own title.
@MainActor
final class GatheringMetricCard: UIView {
    private let title = UILabel()
    private let value = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        CentoChrome.applyCard(to: self)
        clipsToBounds = true
        title.font = TypeScale.uiCaption
        title.textColor = Palette.uiMuted
        title.numberOfLines = 0
        title.adjustsFontForContentSizeCategory = true
        title.setContentHuggingPriority(.required, for: .vertical)
        title.setContentCompressionResistancePriority(.required, for: .vertical)
        value.font = TypeScale.uiTitle
        value.textColor = Palette.uiInk
        value.numberOfLines = 0
        value.adjustsFontForContentSizeCategory = true
        value.setContentHuggingPriority(.required, for: .vertical)
        value.setContentCompressionResistancePriority(.required, for: .vertical)
        title.translatesAutoresizingMaskIntoConstraints = false
        value.translatesAutoresizingMaskIntoConstraints = false
        addSubview(title)
        addSubview(value)
        NSLayoutConstraint.activate([
            title.topAnchor.constraint(equalTo: topAnchor, constant: Space.n(2)),
            title.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Space.gutter),
            title.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Space.gutter),
            value.topAnchor.constraint(equalTo: title.bottomAnchor, constant: Space.unit),
            value.leadingAnchor.constraint(equalTo: title.leadingAnchor),
            value.trailingAnchor.constraint(equalTo: title.trailingAnchor),
            value.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Space.n(2)),
        ])
        setContentHuggingPriority(.required, for: .vertical)
        setContentCompressionResistancePriority(.required, for: .vertical)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    func apply(title text: String, value amount: String) {
        title.text = text
        value.text = amount
        accessibilityLabel = "\(text). \(amount)"
        isAccessibilityElement = true
    }
}
