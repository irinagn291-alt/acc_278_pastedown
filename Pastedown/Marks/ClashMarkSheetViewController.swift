import UIKit

/// Role: ClashMark. Twist screen for the adjacent-volume ban, plus the persisted clash list.
@MainActor
final class ClashMarkSheetViewController: UITableViewController {
    private let session: CentoSession

    init(session: CentoSession) {
        self.session = session
        super.init(style: .insetGrouped)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Adjacent volume ban"
        view.backgroundColor = Palette.uiBackground
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "row")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.tableHeaderView = header()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard let header = tableView.tableHeaderView else { return }
        let size = header.systemLayoutSizeFitting(
            CGSize(width: tableView.bounds.width, height: 0),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        if header.frame.height != size.height {
            header.frame.size = size
            tableView.tableHeaderView = header
        }
    }

    private func header() -> UIView {
        let box = UIView()
        let art = UIImageView(image: UIImage(named: "pdn_TwistHero"))
        art.contentMode = .scaleAspectFit
        art.isAccessibilityElement = false
        let title = UILabel()
        title.text = "A cutting may not sit under its own volume."
        title.font = TypeScale.uiTitle
        title.textColor = Palette.uiInk
        title.numberOfLines = 2
        title.adjustsFontForContentSizeCategory = true
        let body = UILabel()
        body.text = "Paste writes a ClashMark and the foot keeps its line. Another volume is always pastable, so Paste never dies. A cutting sealed into a cento is Spent and cannot be pasted again."
        body.font = TypeScale.uiBody
        body.textColor = Palette.uiMuted
        body.numberOfLines = 0
        body.adjustsFontForContentSizeCategory = true
        let stack = UIStackView(arrangedSubviews: [art, title, body])
        stack.axis = .vertical
        stack.spacing = Space.n(2)
        stack.translatesAutoresizingMaskIntoConstraints = false
        box.addSubview(stack)
        NSLayoutConstraint.activate([
            art.heightAnchor.constraint(equalToConstant: Space.n(16)),
            stack.topAnchor.constraint(equalTo: box.topAnchor, constant: Space.gutter),
            stack.leadingAnchor.constraint(equalTo: box.leadingAnchor, constant: Space.gutter),
            stack.trailingAnchor.constraint(equalTo: box.trailingAnchor, constant: -Space.gutter),
            stack.bottomAnchor.constraint(equalTo: box.bottomAnchor, constant: -Space.gutter),
        ])
        return box
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        max(session.root.clashMarks.count, 1)
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        "Clash marks"
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if session.root.clashMarks.isEmpty {
            return "No refusals yet. The seed leaves Paste able to land from another volume."
        }
        return "Each mark is persisted with the store. The tally on the board is this list counted."
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "row", for: indexPath)
        var content = cell.defaultContentConfiguration()
        let marks = session.root.clashMarks
        if marks.isEmpty {
            content.text = "The list is empty."
            content.secondaryText = "A same-volume paste will write the first mark."
        } else {
            let mark = marks[indexPath.row]
            let refused = session.root.cutting(mark.refusedID)?.text ?? "A cutting"
            content.text = refused
            content.secondaryText = CentoDates.daykey(mark.daykey, calendar: session.calendar)
        }
        content.textProperties.font = TypeScale.uiBody
        content.secondaryTextProperties.font = TypeScale.uiCaption
        content.secondaryTextProperties.color = Palette.uiMuted
        cell.contentConfiguration = content
        cell.backgroundColor = Palette.uiSurface
        cell.selectionStyle = .none
        return cell
    }
}
