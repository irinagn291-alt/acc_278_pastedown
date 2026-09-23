import UIKit

/// Role: Gathering. Sealed cento reader with per-line volume attributions and Copy.
@MainActor
final class SealedCentoReaderViewController: UITableViewController {
    private let session: CentoSession
    private let cento: Cento
    private var strips: [Strip] = []

    init(session: CentoSession, cento: Cento) {
        self.session = session
        self.cento = cento
        super.init(style: .insetGrouped)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = CentoDates.daykey(cento.daykey, calendar: session.calendar)
        view.backgroundColor = Palette.uiBackground
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "line")
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Copy",
            style: .plain,
            target: self,
            action: #selector(copyPlain)
        )
        navigationItem.rightBarButtonItem?.accessibilityLabel = "Copy"
        strips = Strip.poem(from: cento, root: session.root)
        tableView.reloadData()
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        max(strips.count, 1)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "line", for: indexPath)
        var content = cell.defaultContentConfiguration()
        if strips.isEmpty {
            content.text = "This cento has no strips."
            content.secondaryText = "A scrap day does not hang here."
        } else {
            let strip = strips[indexPath.row]
            content.text = strip.text
            let page = CentoFigures.page(strip.page)
            let gone = strip.isGone ? " Title punched from the paper." : ""
            content.secondaryText = "\(strip.volumeTitle), page \(page).\(gone)"
        }
        content.textProperties.font = TypeScale.uiBody
        content.textProperties.color = Palette.uiInk
        content.secondaryTextProperties.font = TypeScale.uiCaption
        content.secondaryTextProperties.color = Palette.uiMuted
        cell.contentConfiguration = content
        cell.backgroundColor = Palette.uiSurface
        cell.selectionStyle = .none
        return cell
    }

    @objc private func copyPlain() {
        UIPasteboard.general.string = CentoPlainText.render(cento: cento, root: session.root)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}
