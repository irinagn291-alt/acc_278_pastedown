import UIKit

/// Role: App. Shared chrome for sheets, glass verbs, and fault copy. Off-canvas controls stay UIKit.
@MainActor
enum CentoChrome {
    static let contactURL = VolumeLookup.contactURL

    static func presentSheet(
        _ controller: UIViewController,
        from host: UIViewController,
        prefersLarge: Bool = false
    ) {
        let nav: UINavigationController
        if let existing = controller as? UINavigationController {
            nav = existing
        } else {
            nav = UINavigationController(rootViewController: controller)
        }
        nav.modalPresentationStyle = .pageSheet
        nav.navigationBar.prefersLargeTitles = false
        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
            sheet.prefersScrollingExpandsWhenScrolledToEdge = true
            sheet.preferredCornerRadius = Radius.card
            if prefersLarge {
                sheet.selectedDetentIdentifier = .large
            }
        }
        nav.view.clipsToBounds = true
        host.present(nav, animated: !Motion.reduce)
    }

    static func presentFull(_ controller: UIViewController, from host: UIViewController) {
        controller.modalPresentationStyle = .fullScreen
        host.present(controller, animated: !Motion.reduce)
    }

    static func applyCard(to view: UIView) {
        view.backgroundColor = Palette.uiSurface
        view.layer.cornerRadius = Radius.card
        view.layer.cornerCurve = .continuous
        Elevation.apply(to: view.layer)
    }

    static func applyChip(to view: UIView) {
        view.layer.cornerRadius = Radius.chip
        view.layer.cornerCurve = .continuous
        view.clipsToBounds = true
    }

    static func iconButton(symbol: String, label: String, target: AnyObject, action: Selector) -> UIButton {
        labeledButton(symbol: symbol, title: label, target: target, action: action)
    }

    static func labeledButton(symbol: String, title: String, target: AnyObject, action: Selector) -> UIButton {
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: symbol)
        config.title = title
        config.imagePlacement = .top
        config.imagePadding = Space.unit / 2
        config.baseForegroundColor = Palette.uiInk
        config.contentInsets = NSDirectionalEdgeInsets(
            top: Space.unit / 2,
            leading: Space.unit / 2,
            bottom: Space.unit / 2,
            trailing: Space.unit / 2
        )
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = TypeScale.uiCaption
            return outgoing
        }
        let button = UIButton(configuration: config)
        button.tintColor = Palette.uiInk
        button.accessibilityLabel = title
        button.accessibilityTraits = .button
        button.addTarget(target, action: action, for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setContentHuggingPriority(.required, for: .vertical)
        button.setContentCompressionResistancePriority(.required, for: .vertical)
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(greaterThanOrEqualToConstant: Space.tap),
            button.heightAnchor.constraint(greaterThanOrEqualToConstant: Space.tap),
        ])
        return button
    }
}

extension CentoFault {
    var boardLine: String {
        switch self {
        case .unknownVolume:
            return "That volume is not on the shelf."
        case .unknownCutting:
            return "That cutting is not in the drawer."
        case .emptyQuote:
            return "Write the line before you save it."
        case .pageOutOfRange:
            return "The page needs to sit inside the volume."
        case .missingTitle:
            return "A volume needs a title."
        case .centoSealed:
            return "Today's cento is already sealed."
        case .alreadyGone:
            return "This volume is already marked gone."
        case .spentCutting:
            return "A spent cutting cannot be pasted again."
        case .cancelled:
            return "The lookup was cancelled."
        case .notFound:
            return "The catalogue has no record for that ISBN."
        case .decoding:
            return "The catalogue reply could not be read."
        case .transport:
            return "The lookup could not reach the catalogue."
        }
    }
}

enum CentoDates {
    static func day(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.locale = Locale.current
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    static func daykey(_ key: Daykey, calendar: Calendar) -> String {
        guard let date = key.date(calendar: calendar) else {
            return CentoFigures.count(key.yyyymmdd)
        }
        return day(date)
    }
}

enum CentoPages {
    static func parse(_ raw: String) -> Int? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        guard let value = formatter.number(from: trimmed)?.intValue else { return nil }
        if value < 0 { return nil }
        return value
    }

    static func percent(_ fraction: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: fraction)) ?? "unknown"
    }
}

/// Role: App. Tinted glass primary control. Accent at low opacity over material, never a flat fill.
final class GlassActionButton: UIButton {
    private let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterial))
    private let wash = UIView()
    private let caption = UILabel()
    private let face = PaperFaceView()

    init(title text: String, showsFace: Bool = false) {
        super.init(frame: .zero)
        blur.isUserInteractionEnabled = false
        wash.isUserInteractionEnabled = false
        caption.isUserInteractionEnabled = false
        face.isUserInteractionEnabled = false
        blur.translatesAutoresizingMaskIntoConstraints = false
        wash.translatesAutoresizingMaskIntoConstraints = false
        caption.translatesAutoresizingMaskIntoConstraints = false
        face.translatesAutoresizingMaskIntoConstraints = false
        insertSubview(blur, at: 0)
        insertSubview(wash, at: 1)
        addSubview(face)
        addSubview(caption)
        layer.cornerRadius = Radius.card
        layer.cornerCurve = .continuous
        clipsToBounds = true
        blur.layer.cornerRadius = Radius.card
        blur.layer.cornerCurve = .continuous
        blur.clipsToBounds = true
        wash.layer.cornerRadius = Radius.card
        wash.layer.cornerCurve = .continuous
        wash.clipsToBounds = true
        wash.backgroundColor = Palette.uiAccent.withAlphaComponent(0.18)
        caption.text = text
        caption.font = TypeScale.uiBody
        caption.textColor = Palette.uiInk
        caption.textAlignment = .center
        caption.adjustsFontForContentSizeCategory = true
        face.isHidden = !showsFace
        face.isAccessibilityElement = false
        accessibilityLabel = text
        accessibilityTraits = .button
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            blur.topAnchor.constraint(equalTo: topAnchor),
            blur.leadingAnchor.constraint(equalTo: leadingAnchor),
            blur.trailingAnchor.constraint(equalTo: trailingAnchor),
            blur.bottomAnchor.constraint(equalTo: bottomAnchor),
            wash.topAnchor.constraint(equalTo: topAnchor),
            wash.leadingAnchor.constraint(equalTo: leadingAnchor),
            wash.trailingAnchor.constraint(equalTo: trailingAnchor),
            wash.bottomAnchor.constraint(equalTo: bottomAnchor),
            heightAnchor.constraint(greaterThanOrEqualToConstant: Space.tap),
            face.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Space.n(2)),
            face.centerYAnchor.constraint(equalTo: centerYAnchor),
            face.widthAnchor.constraint(equalToConstant: Space.n(3)),
            face.heightAnchor.constraint(equalToConstant: Space.n(3)),
            caption.leadingAnchor.constraint(equalTo: showsFace ? face.trailingAnchor : leadingAnchor, constant: Space.n(1)),
            caption.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Space.gutter),
            caption.topAnchor.constraint(equalTo: topAnchor, constant: Space.n(1)),
            caption.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Space.n(1)),
        ])
        layer.masksToBounds = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override var isHighlighted: Bool {
        didSet { paint() }
    }

    override var isEnabled: Bool {
        didSet { paint() }
    }

    func setCaption(_ text: String) {
        caption.text = text
        accessibilityLabel = text
    }

    private func paint() {
        let pressed = isHighlighted && isEnabled
        alpha = isEnabled ? (pressed ? 0.72 : 1) : 0.4
        let scale: CGFloat = pressed && !Motion.reduce ? 0.98 : 1
        transform = CGAffineTransform(scaleX: scale, y: scale)
    }
}

/// Role: App. Secondary wide control. Surface plus the shared shadow, never the accent jewel.
final class SurfaceActionButton: UIButton {
    private let caption = UILabel()

    init(title text: String) {
        super.init(frame: .zero)
        caption.isUserInteractionEnabled = false
        caption.translatesAutoresizingMaskIntoConstraints = false
        addSubview(caption)
        backgroundColor = Palette.uiSurface
        layer.cornerRadius = Radius.card
        layer.cornerCurve = .continuous
        caption.text = text
        caption.font = TypeScale.uiBody
        caption.textColor = Palette.uiInk
        caption.textAlignment = .center
        caption.adjustsFontForContentSizeCategory = true
        caption.numberOfLines = 1
        caption.lineBreakMode = .byTruncatingTail
        caption.setContentHuggingPriority(.required, for: .horizontal)
        caption.setContentCompressionResistancePriority(.required, for: .horizontal)
        accessibilityLabel = text
        accessibilityTraits = .button
        translatesAutoresizingMaskIntoConstraints = false
        clipsToBounds = true
        layer.masksToBounds = true
        NSLayoutConstraint.activate([
            heightAnchor.constraint(greaterThanOrEqualToConstant: Space.tap),
            caption.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Space.gutter),
            caption.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Space.gutter),
            caption.topAnchor.constraint(equalTo: topAnchor, constant: Space.n(1)),
            caption.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Space.n(1)),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override var isHighlighted: Bool {
        didSet { paint() }
    }

    override var isEnabled: Bool {
        didSet { paint() }
    }

    func setCaption(_ text: String) {
        caption.text = text
        accessibilityLabel = text
    }

    private func paint() {
        let pressed = isHighlighted && isEnabled
        alpha = isEnabled ? (pressed ? 0.72 : 1) : 0.4
        backgroundColor = isEnabled ? Palette.uiSurface : Palette.uiMuted.withAlphaComponent(0.12)
        let scale: CGFloat = pressed && !Motion.reduce ? 0.98 : 1
        transform = CGAffineTransform(scaleX: scale, y: scale)
    }
}

/// Role: App. Vector scrap on Paste. Ink stroke, not a raster cutout.
final class PaperFaceView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        isOpaque = false
        backgroundColor = .clear
        isUserInteractionEnabled = false
        contentMode = .redraw
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override func draw(_ rect: CGRect) {
        let inset = rect.insetBy(dx: 1.5, dy: 1.5)
        let path = UIBezierPath()
        let x = inset.minX
        let y = inset.minY
        let w = inset.width
        let h = inset.height
        path.move(to: CGPoint(x: x + 1, y: y + 2))
        path.addLine(to: CGPoint(x: x + w * 0.38, y: y))
        path.addLine(to: CGPoint(x: x + w * 0.72, y: y + 2.5))
        path.addLine(to: CGPoint(x: x + w, y: y + 1))
        path.addLine(to: CGPoint(x: x + w - 1, y: y + h - 2))
        path.addLine(to: CGPoint(x: x + w * 0.62, y: y + h))
        path.addLine(to: CGPoint(x: x + w * 0.28, y: y + h - 2))
        path.addLine(to: CGPoint(x: x, y: y + h - 1))
        path.close()
        Palette.uiAccent.withAlphaComponent(0.28).setFill()
        path.fill()
        Palette.uiInk.setStroke()
        path.lineWidth = 1.5
        path.lineJoinStyle = .round
        path.stroke()
    }
}
