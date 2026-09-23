import UIKit

/// Role: Settings. Contact URL, seal time note, replay onboarding, named delete-everything confirm.
@MainActor
final class SettingsViewController: UITableViewController {
    var onReplayOnboarding: (() -> Void)?
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
        title = "Settings"
        view.backgroundColor = Palette.uiBackground
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "row")
        tableView.rowHeight = UITableView.automaticDimension
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }

    override func numberOfSections(in tableView: UITableView) -> Int { 4 }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 1
        case 1: return 1
        case 2: return 2
        default: return 1
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "Store"
        case 1: return "Midnight seal"
        case 2: return "This device"
        default: return "Contact"
        }
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
        case 0:
            if session.root.volumes.isEmpty && session.root.cuttings.isEmpty && session.root.centos.isEmpty {
                return "The store is empty. Write a volume or a cutting when you are ready."
            }
            if let persistError = session.persistError {
                return persistError
            }
            if let warning = session.warning {
                switch warning {
                case .recoveredFromBackup:
                    return "The last save was recovered from a backup copy."
                case .startedEmpty:
                    return "The store could not be read, so it started empty."
                }
            }
            return "Volumes \(CentoFigures.count(session.root.volumes.count)), cuttings \(CentoFigures.count(session.root.cuttings.count))."
        case 1:
            return "At midnight the board seals if it holds two or more strips. A thinner day writes Scrap and returns the lines to the drawer."
        default:
            return nil
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "row", for: indexPath)
        var content = cell.defaultContentConfiguration()
        content.textProperties.font = TypeScale.uiBody
        content.textProperties.color = Palette.uiInk
        content.secondaryTextProperties.font = TypeScale.uiCaption
        content.secondaryTextProperties.color = Palette.uiMuted
        switch (indexPath.section, indexPath.row) {
        case (0, 0):
            content.text = session.root.volumes.isEmpty ? "Nothing stored yet." : "The store has work on it."
            content.secondaryText = session.persistError == nil
                ? "A failed write never leaves the board showing a line that is not saved."
                : "The last write failed. Try again after you paste or peel."
            cell.selectionStyle = .none
        case (1, 0):
            content.text = "Seal time"
            content.secondaryText = "Keyed by the civil day, not by a clock the UI holds."
            cell.selectionStyle = .none
        case (2, 0):
            content.text = "Show the opening pages again"
            cell.accessoryType = .disclosureIndicator
        case (2, 1):
            content.text = "Delete everything"
            content.textProperties.color = Palette.uiInk
            content.secondaryText = "Removes every volume, cutting, cento and clash mark."
            cell.accessoryType = .none
        default:
            content.text = "Contact"
            content.secondaryText = CentoChrome.contactURL.host
            cell.accessoryType = .disclosureIndicator
        }
        cell.contentConfiguration = content
        cell.backgroundColor = Palette.uiSurface
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch (indexPath.section, indexPath.row) {
        case (2, 0):
            dismiss(animated: !Motion.reduce) { [weak self] in
                self?.onReplayOnboarding?()
            }
        case (2, 1):
            confirmReset()
        case (3, 0):
            UIApplication.shared.open(CentoChrome.contactURL)
        default:
            break
        }
    }

    private func confirmReset() {
        let alert = UIAlertController(
            title: "Delete everything?",
            message: "This removes every volume, cutting, cento and clash mark from this device. It cannot be undone.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Keep", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete everything", style: .destructive) { [weak self] _ in
            Task { await self?.reset() }
        })
        present(alert, animated: !Motion.reduce)
    }

    private func reset() async {
        do {
            try await session.resetStore()
            tableView.reloadData()
        } catch {
            let alert = UIAlertController(
                title: "Delete failed",
                message: "The store could not be wiped. Try again.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: !Motion.reduce)
        }
    }
}
