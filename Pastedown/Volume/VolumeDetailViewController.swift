import UIKit

/// Role: Volume. Push inside Volumes. Title, maker, cuttings, Mark Gone with reason and date.
@MainActor
final class VolumeDetailViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let session: CentoSession
    private let volumeID: VolumeID
    private let table = UITableView(frame: .zero, style: .insetGrouped)
    private let reasonControl = UISegmentedControl(items: GoneReason.allCases.map(\.title))
    private let datePicker = UIDatePicker()
    private let totalPagesField = UITextField()
    private let savePages = SurfaceActionButton(title: "Save total pages")
    private let gone = SurfaceActionButton(title: "Mark gone")
    private let error = UILabel()
    private var cuttings: [Cutting] = []

    init(session: CentoSession, volumeID: VolumeID) {
        self.session = session
        self.volumeID = volumeID
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Palette.uiBackground
        table.dataSource = self
        table.delegate = self
        table.register(UITableViewCell.self, forCellReuseIdentifier: "line")
        table.translatesAutoresizingMaskIntoConstraints = false
        reasonControl.selectedSegmentIndex = 0
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .compact
        datePicker.calendar = Calendar.current
        totalPagesField.placeholder = "Total pages"
        totalPagesField.keyboardType = .decimalPad
        totalPagesField.borderStyle = .roundedRect
        totalPagesField.font = TypeScale.uiBody
        totalPagesField.textColor = Palette.uiInk
        totalPagesField.backgroundColor = Palette.uiSurface
        totalPagesField.heightAnchor.constraint(greaterThanOrEqualToConstant: Space.tap).isActive = true
        savePages.addTarget(self, action: #selector(saveTotalPages), for: .touchUpInside)
        gone.addTarget(self, action: #selector(confirmGone), for: .touchUpInside)
        error.font = TypeScale.uiCaption
        error.textColor = Palette.uiMuted
        error.numberOfLines = 0
        let header = UIView()
        let stack = UIStackView(arrangedSubviews: [totalPagesField, savePages, reasonControl, datePicker, gone, error])
        stack.axis = .vertical
        stack.spacing = Space.n(2)
        stack.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: header.topAnchor, constant: Space.gutter),
            stack.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: Space.gutter),
            stack.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -Space.gutter),
            stack.bottomAnchor.constraint(equalTo: header.bottomAnchor, constant: -Space.gutter),
        ])
        header.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: Space.n(22))
        table.tableHeaderView = header
        view.addSubview(table)
        NSLayoutConstraint.activate([
            table.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            table.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            table.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            table.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        reload()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard let header = table.tableHeaderView else { return }
        let size = header.systemLayoutSizeFitting(
            CGSize(width: table.bounds.width, height: 0),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        if header.frame.height != size.height {
            header.frame.size = size
            table.tableHeaderView = header
        }
    }

    private func reload() {
        guard let volume = session.root.volume(volumeID) else { return }
        title = volume.title
        cuttings = session.root.quoteStore(for: volumeID)
        totalPagesField.text = CentoFigures.page(volume.totalPages)
        gone.isEnabled = volume.gone == nil
        gone.alpha = volume.gone == nil ? 1 : 0.4
        if let goneMark = volume.gone {
            error.text = "Marked \(goneMark.reason.title.lowercased()) on \(CentoDates.day(goneMark.date)). Cuttings stay."
        } else {
            error.text = "Marking it gone keeps every cutting. The book's fate is a field, not the home verb."
        }
        table.reloadData()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        max(cuttings.count, 1)
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let volume = session.root.volume(volumeID) else { return nil }
        let progress = CentoPages.percent(volume.progressFraction)
        return "\(volume.maker). Playhead \(progress)."
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "line", for: indexPath)
        var content = cell.defaultContentConfiguration()
        if cuttings.isEmpty {
            content.text = "No cuttings yet."
            content.secondaryText = "Write one in the drawer and attach it here."
            cell.selectionStyle = .none
        } else {
            let cutting = cuttings[indexPath.row]
            content.text = cutting.text
            content.secondaryText = "Page \(CentoFigures.page(cutting.page)). \(cutting.reread ? "Reread" : "Not reread")."
            cell.selectionStyle = .default
        }
        content.textProperties.font = TypeScale.uiBody
        content.textProperties.color = Palette.uiInk
        content.secondaryTextProperties.font = TypeScale.uiCaption
        content.secondaryTextProperties.color = Palette.uiMuted
        cell.contentConfiguration = content
        cell.backgroundColor = Palette.uiSurface
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard cuttings.indices.contains(indexPath.row) else { return }
        let editor = CuttingEditorViewController(session: session, cutting: cuttings[indexPath.row])
        navigationController?.pushViewController(editor, animated: !Motion.reduce)
    }

    @objc private func confirmGone() {
        guard let volume = session.root.volume(volumeID), volume.gone == nil else { return }
        let reason = GoneReason.allCases[reasonControl.selectedSegmentIndex]
        let alert = UIAlertController(
            title: "Mark \(volume.title) as \(reason.title.lowercased())?",
            message: "Its cuttings stay on the board and in the drawer.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Mark gone", style: .destructive) { [weak self] _ in
            self?.markGone(reason)
        })
        present(alert, animated: !Motion.reduce)
    }

    private func markGone(_ reason: GoneReason) {
        Task {
            do {
                _ = try await session.commit(
                    .markGone(volumeID, reason, at: Calendar.current.startOfDay(for: datePicker.date)),
                    flushImmediately: true
                )
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
                reload()
            } catch let fault as CentoFault {
                error.text = fault.boardLine
            } catch {
                self.error.text = "The gone mark could not be stored."
            }
        }
    }

    @objc private func saveTotalPages() {
        guard var volume = session.root.volume(volumeID) else { return }
        guard let total = CentoPages.parse(totalPagesField.text ?? ""), total >= 1 else {
            error.text = "Total pages needs to be a whole number."
            return
        }
        if volume.currentPage > total {
            error.text = "Total pages cannot sit below the current page."
            return
        }
        volume.totalPages = total
        Task {
            do {
                _ = try await session.commit(.addVolume(volume), flushImmediately: true)
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
                reload()
            } catch let fault as CentoFault {
                error.text = fault.boardLine
            } catch {
                self.error.text = "The page count could not be stored."
            }
        }
    }
}

extension GoneReason {
    var title: String {
        switch self {
        case .sold: return "Sold"
        case .lent: return "Lent"
        case .lost: return "Lost"
        case .culled: return "Culled"
        }
    }
}
