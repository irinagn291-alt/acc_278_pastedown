import UIKit

/// Role: Gathering. Consecutive sealed days as a labeled count plus a seven-day run.
@MainActor
final class SealedStreakView: UIView {
    private let title = UILabel()
    private let value = UILabel()
    private let scroller = UIScrollView()
    private let run = UIStackView()
    private var chipWidths: [NSLayoutConstraint] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        CentoChrome.applyCard(to: self)
        clipsToBounds = true
        title.font = TypeScale.uiCaption
        title.textColor = Palette.uiMuted
        title.text = "Consecutive sealed days"
        title.numberOfLines = 0
        title.adjustsFontForContentSizeCategory = true
        value.font = TypeScale.uiTitle
        value.textColor = Palette.uiInk
        value.numberOfLines = 0
        value.adjustsFontForContentSizeCategory = true
        run.axis = .horizontal
        run.spacing = Space.unit
        run.distribution = .fill
        run.alignment = .fill
        scroller.alwaysBounceHorizontal = false
        scroller.showsHorizontalScrollIndicator = true
        scroller.indicatorStyle = .black
        scroller.clipsToBounds = true
        title.translatesAutoresizingMaskIntoConstraints = false
        value.translatesAutoresizingMaskIntoConstraints = false
        scroller.translatesAutoresizingMaskIntoConstraints = false
        run.translatesAutoresizingMaskIntoConstraints = false
        title.setContentHuggingPriority(.required, for: .vertical)
        value.setContentHuggingPriority(.required, for: .vertical)
        title.setContentCompressionResistancePriority(.required, for: .vertical)
        value.setContentCompressionResistancePriority(.required, for: .vertical)
        addSubview(title)
        addSubview(value)
        addSubview(scroller)
        scroller.addSubview(run)
        NSLayoutConstraint.activate([
            title.topAnchor.constraint(equalTo: topAnchor, constant: Space.n(2)),
            title.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Space.gutter),
            title.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Space.gutter),
            value.topAnchor.constraint(equalTo: title.bottomAnchor, constant: Space.unit),
            value.leadingAnchor.constraint(equalTo: title.leadingAnchor),
            value.trailingAnchor.constraint(equalTo: title.trailingAnchor),
            scroller.topAnchor.constraint(equalTo: value.bottomAnchor, constant: Space.n(2)),
            scroller.leadingAnchor.constraint(equalTo: title.leadingAnchor),
            scroller.trailingAnchor.constraint(equalTo: title.trailingAnchor),
            scroller.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Space.n(2)),
            scroller.heightAnchor.constraint(greaterThanOrEqualToConstant: Space.n(10)),
            run.topAnchor.constraint(equalTo: scroller.contentLayoutGuide.topAnchor),
            run.leadingAnchor.constraint(equalTo: scroller.contentLayoutGuide.leadingAnchor),
            run.trailingAnchor.constraint(equalTo: scroller.contentLayoutGuide.trailingAnchor),
            run.bottomAnchor.constraint(equalTo: scroller.contentLayoutGuide.bottomAnchor),
            run.heightAnchor.constraint(equalTo: scroller.frameLayoutGuide.heightAnchor),
        ])
        setContentHuggingPriority(.required, for: .vertical)
        setContentCompressionResistancePriority(.required, for: .vertical)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    func apply(streak: Int, days: [SealedDayMark]) {
        if streak == 0 {
            value.text = "No consecutive sealed days yet"
        } else {
            value.text = CentoFigures.counted(streak, singular: "day", plural: "days")
        }
        run.arrangedSubviews.forEach { $0.removeFromSuperview() }
        chipWidths.removeAll()
        for day in days {
            let cell = dayCell(day)
            run.addArrangedSubview(cell)
        }
        let runWords = days.map { "\($0.weekday) \($0.dayNumber) \($0.status)" }.joined(separator: ". ")
        accessibilityLabel = "Consecutive sealed days. \(value.text ?? ""). \(runWords)"
        isAccessibilityElement = true
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        seatChips(in: scroller.bounds.width)
    }

    private func seatChips(in available: CGFloat) {
        let chips = run.arrangedSubviews
        guard !chips.isEmpty, available > 1 else { return }
        let spacing = run.spacing
        let minChip = Space.n(9)
        let count = CGFloat(chips.count)
        let visible = max(1, min(count, floor((available + spacing) / (minChip + spacing))))
        let width = floor((available - spacing * (visible - 1)) / visible)
        for constraint in chipWidths {
            constraint.constant = max(width, minChip)
        }
        let overflowing = count > visible
        scroller.isScrollEnabled = overflowing
        scroller.alwaysBounceHorizontal = overflowing
        scroller.showsHorizontalScrollIndicator = overflowing
    }

    private func dayCell(_ day: SealedDayMark) -> UIView {
        let plate = UIView()
        plate.backgroundColor = day.isSealed
            ? Palette.uiAccent.withAlphaComponent(0.16)
            : Palette.uiBackground
        plate.layer.cornerRadius = Radius.chip
        plate.layer.cornerCurve = .continuous
        plate.layer.borderWidth = 1
        plate.layer.borderColor = (day.isSealed ? Palette.uiAccent : Palette.uiMuted.withAlphaComponent(0.35)).cgColor
        let weekday = UILabel()
        weekday.text = day.weekday
        weekday.font = TypeScale.uiCaption
        weekday.textColor = Palette.uiMuted
        weekday.textAlignment = .center
        weekday.adjustsFontForContentSizeCategory = true
        weekday.numberOfLines = 1
        weekday.lineBreakMode = .byClipping
        let number = UILabel()
        number.text = day.dayNumber
        number.font = TypeScale.uiBody
        number.textColor = Palette.uiInk
        number.textAlignment = .center
        number.adjustsFontForContentSizeCategory = true
        number.numberOfLines = 1
        let status = UILabel()
        status.text = day.status
        status.font = TypeScale.uiCaption
        status.textColor = Palette.uiInk
        status.textAlignment = .center
        status.adjustsFontForContentSizeCategory = true
        status.numberOfLines = 1
        status.lineBreakMode = .byClipping
        status.adjustsFontSizeToFitWidth = true
        status.minimumScaleFactor = 0.85
        let stack = UIStackView(arrangedSubviews: [weekday, number, status])
        stack.axis = .vertical
        stack.spacing = Space.unit / 2
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        plate.addSubview(stack)
        let width = plate.widthAnchor.constraint(equalToConstant: Space.n(9))
        chipWidths.append(width)
        NSLayoutConstraint.activate([
            width,
            stack.topAnchor.constraint(equalTo: plate.topAnchor, constant: Space.unit),
            stack.leadingAnchor.constraint(equalTo: plate.leadingAnchor, constant: Space.unit / 2),
            stack.trailingAnchor.constraint(equalTo: plate.trailingAnchor, constant: -Space.unit / 2),
            stack.bottomAnchor.constraint(equalTo: plate.bottomAnchor, constant: -Space.unit),
        ])
        return plate
    }
}
