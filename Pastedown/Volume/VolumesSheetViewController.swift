import UIKit

/// Role: Volume. Shelf sheet. Typed or scanned entry. ISBN field and Scan share one latch.
@MainActor
final class VolumesSheetViewController: UITableViewController, UITextFieldDelegate {
    private let session: CentoSession
    private let empty = EmptyStateView()
    private let isbnField = UITextField()
    private let scan = SurfaceActionButton(title: "Scan")
    private let titleField = UITextField()
    private let makerField = UITextField()
    private let pagesField = UITextField()
    private let save = GlassActionButton(title: "Add volume")
    private let lookupSpinner = UIActivityIndicatorView(style: .medium)
    private let status = UILabel()
    private let header = UIView()
    private var lookupTask: Task<Void, Never>?
    private var lookupSpinnerTask: Task<Void, Never>?
    private var lookupToken = 0
    private var saving = false

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
        title = "Volumes"
        view.backgroundColor = Palette.uiBackground
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "volume")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.keyboardDismissMode = .onDrag
        buildHeader()
        tableView.tableHeaderView = header
        reload()
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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reload()
    }

    private func buildHeader() {
        isbnField.placeholder = "ISBN"
        isbnField.keyboardType = .asciiCapable
        isbnField.autocapitalizationType = .allCharacters
        isbnField.borderStyle = .roundedRect
        isbnField.font = TypeScale.uiBody
        isbnField.delegate = self
        isbnField.addTarget(self, action: #selector(isbnChanged), for: .editingChanged)
        isbnField.heightAnchor.constraint(greaterThanOrEqualToConstant: Space.tap).isActive = true
        titleField.placeholder = "Title"
        titleField.borderStyle = .roundedRect
        titleField.font = TypeScale.uiBody
        titleField.heightAnchor.constraint(greaterThanOrEqualToConstant: Space.tap).isActive = true
        makerField.placeholder = "Maker"
        makerField.borderStyle = .roundedRect
        makerField.font = TypeScale.uiBody
        makerField.heightAnchor.constraint(greaterThanOrEqualToConstant: Space.tap).isActive = true
        pagesField.placeholder = "Total pages"
        pagesField.borderStyle = .roundedRect
        pagesField.font = TypeScale.uiBody
        pagesField.keyboardType = .decimalPad
        pagesField.heightAnchor.constraint(greaterThanOrEqualToConstant: Space.tap).isActive = true
        status.font = TypeScale.uiCaption
        status.textColor = Palette.uiMuted
        status.numberOfLines = 0
        status.adjustsFontForContentSizeCategory = true
        lookupSpinner.hidesWhenStopped = true
        lookupSpinner.color = Palette.uiMuted
        scan.addTarget(self, action: #selector(openScan), for: .touchUpInside)
        save.addTarget(self, action: #selector(addVolume), for: .touchUpInside)
        let isbnRow = UIStackView(arrangedSubviews: [isbnField, scan])
        isbnRow.axis = .horizontal
        isbnRow.spacing = Space.n(1)
        isbnRow.distribution = .fill
        let statusRow = UIStackView(arrangedSubviews: [lookupSpinner, status])
        statusRow.axis = .horizontal
        statusRow.alignment = .top
        statusRow.spacing = Space.unit
        lookupSpinner.setContentHuggingPriority(.required, for: .horizontal)
        status.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        scan.widthAnchor.constraint(equalToConstant: Space.n(12)).isActive = true
        let stack = UIStackView(arrangedSubviews: [isbnRow, titleField, makerField, pagesField, statusRow, save])
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
    }

    private func reload() {
        if session.root.volumes.isEmpty {
            empty.apply(
                art: "pdn_EmptyVolumesMark",
                headline: "The shelf is empty.",
                line: "Type a title or scan an ISBN before the book leaves. Its cuttings stay even after it is gone.",
                action: "Scan an ISBN"
            ) { [weak self] in
                self?.openScan()
            }
            tableView.backgroundView = empty
        } else {
            tableView.backgroundView = nil
        }
        tableView.reloadData()
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        session.root.volumes.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "volume", for: indexPath)
        let volume = session.root.volumes[indexPath.row]
        var content = cell.defaultContentConfiguration()
        content.text = volume.title
        content.textProperties.font = TypeScale.uiBody
        content.textProperties.color = Palette.uiInk
        let progress = CentoPages.percent(volume.progressFraction)
        let fate = volume.gone.map { "Gone, \($0.reason.rawValue.capitalized)." } ?? "Still here."
        content.secondaryText = "\(volume.maker). \(progress). \(fate)"
        content.secondaryTextProperties.font = TypeScale.uiCaption
        content.secondaryTextProperties.color = Palette.uiMuted
        cell.contentConfiguration = content
        cell.backgroundColor = Palette.uiSurface
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let detail = VolumeDetailViewController(session: session, volumeID: session.root.volumes[indexPath.row].id)
        navigationController?.pushViewController(detail, animated: !Motion.reduce)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    @objc private func isbnChanged() {
        lookupTask?.cancel()
        let token = beginLookup()
        let raw = isbnField.text ?? ""
        guard ISBN.parse(raw) != nil || ISBN.extract(from: raw) != nil else {
            finishLookup(token: token)
            status.text = nil
            return
        }
        lookupTask = Task { [weak self] in
            guard let self else { return }
            do {
                let latch = try await session.lookup.lookupDebounced(raw: raw)
                finishLookup(token: token)
                status.text = "Title and maker filled from the catalogue."
                titleField.text = latch.title
                makerField.text = latch.maker
                _ = try? await session.commit(.cacheLatch(latch))
            } catch let fault as CentoFault where fault == .cancelled {
                finishLookup(token: token)
                return
            } catch let fault as CentoFault {
                finishLookup(token: token)
                status.text = fault.boardLine + " Type the title yourself, or try again."
            } catch {
                finishLookup(token: token)
                status.text = "The lookup failed. Type the title yourself, or try again."
            }
        }
    }

    @objc private func addVolume() {
        guard !saving else { return }
        let title = titleField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !title.isEmpty else {
            status.text = CentoFault.missingTitle.boardLine
            return
        }
        let pagesRaw = pagesField.text ?? ""
        let pagesTrimmed = pagesRaw.trimmingCharacters(in: .whitespacesAndNewlines)
        let pagesParsed = CentoPages.parse(pagesTrimmed)
        if !pagesTrimmed.isEmpty, (pagesParsed == nil || (pagesParsed ?? 0) < 1) {
            status.text = "Total pages needs to be a whole number."
            return
        }
        saving = true
        save.isEnabled = false
        let isbn = ISBN.parse(isbnField.text ?? "")?.canonical
        let totalPages = max(pagesParsed ?? 1, 1)
        let volume = Volume(
            title: title,
            maker: makerField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
            isbn: isbn,
            currentPage: 0,
            totalPages: totalPages
        )
        Task {
            do {
                _ = try await session.commit(.addVolume(volume), flushImmediately: true)
                if let isbn, let latch = session.root.latch(for: isbn) {
                    _ = try await session.commit(.latch(volume.id, latch))
                }
                titleField.text = ""
                makerField.text = ""
                isbnField.text = ""
                pagesField.text = ""
                status.text = nil
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
                reload()
            } catch let fault as CentoFault {
                status.text = fault.boardLine
            } catch {
                status.text = "The volume could not be stored."
            }
            saving = false
            save.isEnabled = true
        }
    }

    @objc private func openScan() {
        let scan = VolumeScanViewController(session: session)
        scan.onLatch = { [weak self] latch in
            guard let self else { return }
            self.isbnField.text = latch.isbn
            self.titleField.text = latch.title
            self.makerField.text = latch.maker
            self.status.text = "Title and maker filled from the scan."
        }
        navigationController?.pushViewController(scan, animated: !Motion.reduce)
    }

    private func beginLookup() -> Int {
        lookupToken += 1
        let token = lookupToken
        lookupSpinnerTask?.cancel()
        lookupSpinner.stopAnimating()
        status.text = "Looking up ISBN..."
        lookupSpinnerTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 150_000_000)
            guard let self, self.lookupToken == token else { return }
            self.lookupSpinner.startAnimating()
        }
        return token
    }

    private func finishLookup(token: Int) {
        guard token == lookupToken else { return }
        lookupSpinnerTask?.cancel()
        lookupSpinner.stopAnimating()
    }
}
