import UIKit

/// Role: Cutting. Push inside Cuttings. Quote, page, volume, reread verdict. Save through the engine.
@MainActor
final class CuttingEditorViewController: UIViewController, UITextViewDelegate, UIPickerViewDataSource, UIPickerViewDelegate {
    private let session: CentoSession
    private let existing: Cutting?
    private let scroll = UIScrollView()
    private let quote = UITextView()
    private let pageField = UITextField()
    private let picker = UIPickerView()
    private let reread = UISwitch()
    private let error = UILabel()
    private let save = GlassActionButton(title: "Save")
    private var keyboardObservers: [NSObjectProtocol] = []
    private var saving = false

    init(session: CentoSession, cutting: Cutting?) {
        self.session = session
        self.existing = cutting
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = existing == nil ? "Write a cutting" : "Edit cutting"
        view.backgroundColor = Palette.uiBackground
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.keyboardDismissMode = .onDrag
        quote.font = TypeScale.uiBody
        quote.textColor = Palette.uiInk
        quote.backgroundColor = Palette.uiSurface
        quote.layer.cornerRadius = Radius.card
        quote.layer.cornerCurve = .continuous
        quote.textContainerInset = UIEdgeInsets(top: Space.n(2), left: Space.n(1), bottom: Space.n(2), right: Space.n(1))
        quote.adjustsFontForContentSizeCategory = true
        quote.delegate = self
        quote.text = existing?.text ?? ""
        Elevation.apply(to: quote.layer)
        pageField.font = TypeScale.uiBody
        pageField.textColor = Palette.uiInk
        pageField.keyboardType = .numberPad
        pageField.placeholder = "Page"
        pageField.borderStyle = .roundedRect
        pageField.backgroundColor = Palette.uiSurface
        pageField.addTarget(self, action: #selector(pageChanged), for: .editingChanged)
        if let page = existing?.page {
            pageField.text = CentoFigures.page(page)
        }
        picker.dataSource = self
        picker.delegate = self
        if let volumeID = existing?.volumeID, let index = session.root.volumes.firstIndex(where: { $0.id == volumeID }) {
            picker.selectRow(index, inComponent: 0, animated: false)
        }
        reread.isOn = existing?.reread ?? false
        reread.onTintColor = Palette.uiAccent
        error.font = TypeScale.uiCaption
        error.textColor = Palette.uiMuted
        error.numberOfLines = 0
        error.adjustsFontForContentSizeCategory = true
        let pageLabel = caption("Page number")
        let volumeLabel = caption("Volume")
        let rereadLabel = caption("Reread")
        let rereadRow = UIStackView(arrangedSubviews: [rereadLabel, reread])
        rereadRow.axis = .horizontal
        rereadRow.alignment = .center
        let stack = UIStackView(arrangedSubviews: [quote, pageLabel, pageField, volumeLabel, picker, rereadRow, error, save])
        stack.axis = .vertical
        stack.spacing = Space.n(2)
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)
        scroll.addSubview(stack)
        save.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: Space.gutter),
            stack.leadingAnchor.constraint(equalTo: scroll.frameLayoutGuide.leadingAnchor, constant: Space.gutter),
            stack.trailingAnchor.constraint(equalTo: scroll.frameLayoutGuide.trailingAnchor, constant: -Space.gutter),
            stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -Space.gutter),
            quote.heightAnchor.constraint(greaterThanOrEqualToConstant: Space.n(16)),
            pageField.heightAnchor.constraint(greaterThanOrEqualToConstant: Space.tap),
            picker.heightAnchor.constraint(equalToConstant: Space.n(16)),
        ])
        observeKeyboard()
    }

    private func caption(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = TypeScale.uiCaption
        label.textColor = Palette.uiMuted
        label.adjustsFontForContentSizeCategory = true
        return label
    }

    func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        session.root.volumes.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        session.root.volumes[row].title
    }

    func textViewDidChange(_ textView: UITextView) {
        error.text = textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "Write the line before you save it."
            : nil
    }

    @objc private func pageChanged() {
        guard let raw = pageField.text, !raw.isEmpty else { return }
        if CentoPages.parse(raw) == nil {
            error.text = "The page needs to be a whole number."
        } else {
            error.text = nil
        }
    }

    @objc private func saveTapped() {
        guard !saving else { return }
        let text = quote.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            error.text = CentoFault.emptyQuote.boardLine
            return
        }
        guard !session.root.volumes.isEmpty else {
            error.text = CentoFault.unknownVolume.boardLine
            return
        }
        let volume = session.root.volumes[picker.selectedRow(inComponent: 0)]
        guard let page = CentoPages.parse(pageField.text ?? ""), page >= 1 else {
            error.text = CentoFault.pageOutOfRange.boardLine
            return
        }
        saving = true
        save.isEnabled = false
        var cutting = existing ?? Cutting(volumeID: volume.id, text: text, page: page, reread: reread.isOn)
        cutting.volumeID = volume.id
        cutting.text = text
        cutting.page = page
        cutting.reread = reread.isOn
        Task {
            do {
                if existing == nil {
                    _ = try await session.commit(.addCutting(cutting), flushImmediately: true)
                } else {
                    _ = try await session.commit(.editCutting(cutting), flushImmediately: true)
                    _ = try await session.commit(.markReread(cutting.id, reread.isOn))
                }
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
                navigationController?.popViewController(animated: !Motion.reduce)
            } catch let fault as CentoFault {
                error.text = fault.boardLine
                saving = false
                save.isEnabled = true
            } catch {
                self.error.text = "The cutting could not be stored."
                saving = false
                save.isEnabled = true
            }
        }
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    private func observeKeyboard() {
        let center = NotificationCenter.default
        keyboardObservers.append(center.addObserver(forName: UIResponder.keyboardWillChangeFrameNotification, object: nil, queue: .main) { [weak self] note in
            guard let self, let frame = note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
            let overlap = self.view.convert(frame, from: nil).intersection(self.view.bounds).height
            self.scroll.contentInset.bottom = overlap
            self.scroll.verticalScrollIndicatorInsets.bottom = overlap
        })
        keyboardObservers.append(center.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { [weak self] _ in
            self?.scroll.contentInset.bottom = 0
            self?.scroll.verticalScrollIndicatorInsets.bottom = 0
        })
    }
}
