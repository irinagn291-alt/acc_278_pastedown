import UIKit

/// Role: Drawer. Layer-backed cutting tile. Whole chrome is the target. Dimmed when canFollow is false.
@MainActor
final class DrawerTileButton: UIButton {
    private(set) var cuttingID: CuttingID?
    private let caption = UILabel()
    private let meta = UILabel()
    private var widthConstraint: NSLayoutConstraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = true
        layer.cornerRadius = Radius.chip
        layer.cornerCurve = .continuous
        caption.font = TypeScale.uiCaption
        caption.textColor = Palette.uiInk
        caption.numberOfLines = 0
        caption.lineBreakMode = .byWordWrapping
        caption.adjustsFontForContentSizeCategory = true
        caption.setContentCompressionResistancePriority(.required, for: .vertical)
        meta.font = TypeScale.uiCaption
        meta.textColor = Palette.uiMuted
        meta.numberOfLines = 2
        meta.lineBreakMode = .byWordWrapping
        meta.adjustsFontForContentSizeCategory = true
        meta.setContentCompressionResistancePriority(.required, for: .vertical)
        caption.translatesAutoresizingMaskIntoConstraints = false
        meta.translatesAutoresizingMaskIntoConstraints = false
        caption.isUserInteractionEnabled = false
        meta.isUserInteractionEnabled = false
        addSubview(caption)
        addSubview(meta)
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            heightAnchor.constraint(greaterThanOrEqualToConstant: Space.n(9)),
            caption.topAnchor.constraint(equalTo: topAnchor, constant: Space.n(1)),
            caption.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Space.n(1)),
            caption.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Space.n(1)),
            meta.topAnchor.constraint(equalTo: caption.bottomAnchor, constant: Space.unit),
            meta.leadingAnchor.constraint(equalTo: caption.leadingAnchor),
            meta.trailingAnchor.constraint(equalTo: caption.trailingAnchor),
            meta.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Space.n(1)),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    func apply(cutting: Cutting, volumeTitle: String, allowed: Bool, chosen: Bool) {
        cuttingID = cutting.id
        let page = CentoFigures.page(cutting.page)
        let state: String
        switch cutting.state {
        case .fresh: state = "Fresh"
        case .pasted: state = "Pasted"
        case .spent: state = "Spent"
        }
        meta.text = volumeTitle
        isEnabled = allowed
        alpha = allowed ? 1 : 0.4
        backgroundColor = chosen
            ? Palette.uiAccent.withAlphaComponent(0.18)
            : Palette.uiSurface
        layer.borderWidth = chosen ? 1 : 0
        layer.borderColor = Palette.uiAccent.cgColor
        if cutting.state == .spent {
            let struck = NSAttributedString(
                string: cutting.text,
                attributes: [
                    .font: TypeScale.uiCaption,
                    .foregroundColor: Palette.uiMuted,
                    .strikethroughStyle: NSUnderlineStyle.single.rawValue,
                ]
            )
            caption.attributedText = struck
        } else {
            caption.attributedText = nil
            caption.text = cutting.text
        }
        accessibilityLabel = "\(cutting.text). \(volumeTitle), page \(page). \(state)."
        accessibilityTraits = allowed ? .button : [.button, .notEnabled]
    }

    func setTileWidth(_ width: CGFloat?) {
        widthConstraint?.isActive = false
        if let width {
            widthConstraint = widthAnchor.constraint(equalToConstant: width)
            widthConstraint?.isActive = true
        } else {
            widthConstraint = nil
        }
    }

    func playClash() {
        guard !Motion.reduce else { return }
        transform = .identity
        UIView.animate(withDuration: Motion.duration * 0.5, delay: 0, options: [.curveEaseOut]) {
            self.transform = CGAffineTransform(translationX: Motion.shiverPoints, y: 0)
        } completion: { _ in
            UIView.animate(withDuration: Motion.duration, delay: 0, usingSpringWithDamping: 0.55, initialSpringVelocity: 0, options: [.curveEaseOut]) {
                self.transform = .identity
            }
        }
    }

    override var isHighlighted: Bool {
        didSet {
            alpha = isEnabled ? (isHighlighted ? 0.72 : 1) : 0.4
        }
    }
}
