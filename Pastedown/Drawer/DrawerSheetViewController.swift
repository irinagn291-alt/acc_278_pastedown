import UIKit

/// Role: Drawer. Cuttings sheet. Fresh, then pasted, then spent. Full-page empty state.
@MainActor
final class DrawerSheetViewController: UITableViewController {
    private let session: CentoSession
    private let empty = EmptyStateView()
    private var groups: [(title: String, items: [Cutting])] = []
    private var sources: [(title: String, detail: String)] = []

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
        title = "Cuttings"
        view.backgroundColor = Palette.uiBackground
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cutting")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "source")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = Space.n(10)
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Close",
            style: .plain,
            target: self,
            action: #selector(closeSheet)
        )
        navigationItem.leftBarButtonItem?.accessibilityLabel = "Close cuttings"
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "plus"),
            style: .plain,
            target: self,
            action: #selector(writeCutting)
        )
        navigationItem.rightBarButtonItem?.accessibilityLabel = "Write a cutting"
        empty.translatesAutoresizingMaskIntoConstraints = false
        reload()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reload()
    }

    private func reload() {
        let ordered = DrawerOrdering.ordered(session.root.cuttings)
        groups = [
            ("Fresh", ordered.filter { $0.state == .fresh }),
            ("Pasted", ordered.filter { $0.state == .pasted }),
            ("Spent", ordered.filter { $0.state == .spent }),
        ].filter { !$0.items.isEmpty }
        sources = session.root.volumes.map { volume in
            let owned = session.root.cuttings.filter { $0.volumeID == volume.id }
            let reread = owned.filter(\.reread).count
            let detail = "\(CentoFigures.counted(owned.count, singular: "cutting", plural: "cuttings")). \(CentoFigures.counted(reread, singular: "reread", plural: "rereads"))."
            return (volume.title, detail)
        }
        tableView.backgroundView = nil
        if session.root.cuttings.isEmpty {
            empty.apply(
                art: "pdn_EmptyDrawerMark",
                headline: "The drawer is empty.",
                line: "Write a quote, set its page, and attach it to a volume. It enters as Fresh.",
                action: "Write a cutting"
            ) { [weak self] in
                self?.writeCutting()
            }
            tableView.backgroundView = empty
        }
        tableView.reloadData()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        groups.count + (sources.isEmpty ? 0 : 1)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section < groups.count {
            return groups[section].items.count
        }
        return max(sources.count, 1)
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section < groups.count {
            return groups[section].title
        }
        return "Sources"
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        guard section == groups.count else { return nil }
        let reread = session.root.cuttings.filter(\.reread).count
        return "Reread cuttings stay in the drawer so you can paste a line you already lived with. \(CentoFigures.counted(reread, singular: "cutting is marked reread", plural: "cuttings are marked reread"))."
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section >= groups.count {
            let cell = tableView.dequeueReusableCell(withIdentifier: "source", for: indexPath)
            var content = cell.defaultContentConfiguration()
            if sources.isEmpty {
                content.text = "No volumes yet."
                content.secondaryText = "A cutting needs a volume before it can enter the drawer."
            } else {
                let row = sources[indexPath.row]
                content.text = row.title
                content.secondaryText = row.detail
            }
            content.textProperties.font = TypeScale.uiBody
            content.textProperties.color = Palette.uiInk
            content.secondaryTextProperties.font = TypeScale.uiCaption
            content.secondaryTextProperties.color = Palette.uiMuted
            cell.contentConfiguration = content
            cell.backgroundColor = Palette.uiSurface
            cell.selectionStyle = .none
            cell.accessoryType = .none
            return cell
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "cutting", for: indexPath)
        let cutting = groups[indexPath.section].items[indexPath.row]
        let volume = session.root.volume(cutting.volumeID)
        var content = cell.defaultContentConfiguration()
        content.text = cutting.text
        content.textProperties.font = TypeScale.uiBody
        content.textProperties.color = Palette.uiInk
        content.textProperties.numberOfLines = 3
        let page = CentoFigures.page(cutting.page)
        let verdict = cutting.reread ? "Reread" : "Not reread"
        content.secondaryText = "\(volume?.title ?? "Volume"), page \(page). \(verdict)."
        content.secondaryTextProperties.font = TypeScale.uiCaption
        content.secondaryTextProperties.color = Palette.uiMuted
        if cutting.state == .spent {
            content.textProperties.color = Palette.uiMuted
        }
        cell.contentConfiguration = content
        cell.backgroundColor = Palette.uiSurface
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    @objc private func closeSheet() {
        dismiss(animated: !Motion.reduce)
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard indexPath.section < groups.count else { return }
        let cutting = groups[indexPath.section].items[indexPath.row]
        let editor = CuttingEditorViewController(session: session, cutting: cutting)
        navigationController?.pushViewController(editor, animated: !Motion.reduce)
    }

    @objc private func writeCutting() {
        if session.root.volumes.isEmpty {
            let alert = UIAlertController(
                title: "Add a volume first",
                message: "A cutting needs a volume before it can enter the drawer.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Open Volumes", style: .default) { [weak self] _ in
                self?.dismiss(animated: !Motion.reduce)
            })
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            present(alert, animated: !Motion.reduce)
            return
        }
        let editor = CuttingEditorViewController(session: session, cutting: nil)
        navigationController?.pushViewController(editor, animated: !Motion.reduce)
    }
}
