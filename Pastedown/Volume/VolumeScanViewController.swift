import AVFoundation
import UIKit

/// Role: Volume. Spine-shaped capture window inside the Volumes sheet. Continue never says Allow.
@MainActor
final class VolumeScanViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var onLatch: ((VolumeLatch) -> Void)?
    private let session: CentoSession
    private let capture = AVCaptureSession()
    private let preview = AVCaptureVideoPreviewLayer()
    private let shutter = UIImageView()
    private let window = SpineWindowView()
    private let status = UILabel()
    private let lookupSpinner = UIActivityIndicatorView(style: .medium)
    private let isbnField = UITextField()
    private let continueButton = GlassActionButton(title: "Continue")
    private let settingsButton = SurfaceActionButton(title: "Open Settings")
    private let retry = SurfaceActionButton(title: "Try again")
    private let chipStack = UIStackView()
    private var lookupTask: Task<Void, Never>?
    private var lookupSpinnerTask: Task<Void, Never>?
    private var lookupToken = 0
    private var lastCode: String?

    init(session: CentoSession) {
        self.session = session
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Scan"
        view.backgroundColor = Palette.uiBackground
        preview.videoGravity = .resizeAspectFill
        preview.cornerRadius = Radius.card
        view.layer.addSublayer(preview)
        window.isUserInteractionEnabled = false
        window.translatesAutoresizingMaskIntoConstraints = false
        shutter.image = UIImage(named: "pdn_ShutterLeaf")
        shutter.contentMode = .scaleAspectFit
        shutter.isAccessibilityElement = false
        shutter.translatesAutoresizingMaskIntoConstraints = false
        status.font = TypeScale.uiBody
        status.textColor = Palette.uiMuted
        status.numberOfLines = 0
        status.adjustsFontForContentSizeCategory = true
        status.text = idleStatusLine()
        lookupSpinner.hidesWhenStopped = true
        lookupSpinner.color = Palette.uiMuted
        isbnField.placeholder = "ISBN"
        isbnField.borderStyle = .roundedRect
        isbnField.font = TypeScale.uiBody
        isbnField.keyboardType = .asciiCapable
        isbnField.autocapitalizationType = .allCharacters
        isbnField.addTarget(self, action: #selector(manualChanged), for: .editingChanged)
        isbnField.heightAnchor.constraint(greaterThanOrEqualToConstant: Space.tap).isActive = true
        continueButton.addTarget(self, action: #selector(continueCapture), for: .touchUpInside)
        settingsButton.addTarget(self, action: #selector(openSystemSettings), for: .touchUpInside)
        retry.addTarget(self, action: #selector(retryLookup), for: .touchUpInside)
        retry.isHidden = true
        settingsButton.isHidden = true
        chipStack.axis = .horizontal
        chipStack.spacing = Space.unit
        chipStack.distribution = .fillEqually
        for sample in Self.simulatorChips {
            var config = UIButton.Configuration.plain()
            config.title = sample.title
            config.baseForegroundColor = Palette.uiInk
            config.contentInsets = NSDirectionalEdgeInsets(
                top: Space.unit,
                leading: Space.n(1),
                bottom: Space.unit,
                trailing: Space.n(1)
            )
            let chip = UIButton(configuration: config)
            chip.backgroundColor = Palette.uiSurface
            chip.layer.cornerRadius = Radius.chip
            chip.heightAnchor.constraint(greaterThanOrEqualToConstant: Space.tap).isActive = true
            chip.accessibilityLabel = "Use sample ISBN \(sample.isbn)"
            chip.addAction(UIAction { [weak self] _ in
                self?.isbnField.text = sample.isbn
                self?.lookup(sample.isbn)
            }, for: .touchUpInside)
            Elevation.apply(to: chip.layer)
            chipStack.addArrangedSubview(chip)
        }
        #if !targetEnvironment(simulator)
        chipStack.isHidden = true
        #endif
        let statusRow = UIStackView(arrangedSubviews: [lookupSpinner, status])
        statusRow.axis = .horizontal
        statusRow.spacing = Space.unit
        statusRow.alignment = .top
        lookupSpinner.setContentHuggingPriority(.required, for: .horizontal)
        status.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        let stack = UIStackView(arrangedSubviews: [statusRow, isbnField, chipStack, continueButton, settingsButton, retry])
        stack.axis = .vertical
        stack.spacing = Space.n(2)
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(window)
        view.addSubview(shutter)
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            window.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: Space.n(2)),
            window.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            window.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.42),
            window.heightAnchor.constraint(equalTo: window.widthAnchor, multiplier: 2.2),
            shutter.centerXAnchor.constraint(equalTo: window.centerXAnchor),
            shutter.centerYAnchor.constraint(equalTo: window.centerYAnchor),
            shutter.widthAnchor.constraint(equalTo: window.widthAnchor),
            shutter.heightAnchor.constraint(equalTo: window.heightAnchor),
            stack.topAnchor.constraint(equalTo: window.bottomAnchor, constant: Space.n(2)),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Space.gutter),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Space.gutter),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -Space.n(2)),
        ])
        paintGate()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(stopCapture),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        preview.frame = window.frame
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopCapture()
        lookupTask?.cancel()
        lookupSpinnerTask?.cancel()
    }

    private static let simulatorChips: [(title: String, isbn: String)] = [
        ("Paper Hours", "9780306406157"),
        ("Sample two", "9780141439518"),
        ("Sample three", "9780679783268"),
    ]

    private func paintGate() {
        #if targetEnvironment(simulator)
        status.text = "Simulator has no camera. Use a sample ISBN or type one."
        continueButton.isHidden = true
        settingsButton.isHidden = true
        #else
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            continueButton.isHidden = true
            settingsButton.isHidden = true
            installCamera()
        case .notDetermined:
            status.text = "Hold the back of the book so the ISBN can fill the title."
            continueButton.isHidden = false
            settingsButton.isHidden = true
        case .denied, .restricted:
            showDenied()
        @unknown default:
            showDenied()
        }
        #endif
    }

    @objc private func continueCapture() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            Task { @MainActor in
                if granted {
                    self?.continueButton.isHidden = true
                    self?.installCamera()
                } else {
                    self?.showDenied()
                }
            }
        }
    }

    private func showDenied() {
        stopCapture()
        status.text = "The scanner cannot see the barcode because camera access is off. Open Settings to turn it on."
        continueButton.isHidden = true
        settingsButton.isHidden = false
    }

    @objc private func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    private func installCamera() {
        guard let device = AVCaptureDevice.default(for: .video) else {
            status.text = "This device has no camera. Type the ISBN instead."
            return
        }
        do {
            let input = try AVCaptureDeviceInput(device: device)
            if capture.canAddInput(input) {
                capture.addInput(input)
            }
            let output = AVCaptureMetadataOutput()
            if capture.canAddOutput(output) {
                capture.addOutput(output)
                output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                var types: [AVMetadataObject.ObjectType] = [.ean13, .ean8, .qr]
                if output.availableMetadataObjectTypes.contains(.interleaved2of5) {
                    types.append(.interleaved2of5)
                }
                output.metadataObjectTypes = types.filter { output.availableMetadataObjectTypes.contains($0) }
            }
            preview.session = capture
            if !capture.isRunning {
                capture.startRunning()
            }
            status.text = "Hold the back of the book until the ISBN latches."
        } catch {
            status.text = "The camera could not start. Type the ISBN instead."
        }
    }

    @objc private func stopCapture() {
        if capture.isRunning {
            capture.stopRunning()
        }
    }

    nonisolated func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        let payload = metadataObjects
            .compactMap { $0 as? AVMetadataMachineReadableCodeObject }
            .compactMap(\.stringValue)
            .first
        guard let payload else { return }
        Task { @MainActor in
            self.absorb(payload)
        }
    }

    private func absorb(_ raw: String) {
        guard let isbn = ISBN.extract(from: raw) ?? ISBN.parse(raw) else { return }
        guard lastCode != isbn.canonical else { return }
        lastCode = isbn.canonical
        isbnField.text = isbn.canonical
        lookup(isbn.canonical)
    }

    @objc private func manualChanged() {
        lookupTask?.cancel()
        let raw = isbnField.text ?? ""
        guard ISBN.parse(raw) != nil || ISBN.extract(from: raw) != nil else {
            status.text = idleStatusLine()
            finishLookup(token: lookupToken)
            retry.isHidden = true
            return
        }
        lookup(raw)
    }

    @objc private func retryLookup() {
        lookup(isbnField.text ?? "")
    }

    private func lookup(_ raw: String) {
        lookupTask?.cancel()
        retry.isHidden = true
        let token = beginLookup()
        lookupTask = Task {
            do {
                let latch = try await session.lookup.lookupDebounced(raw: raw)
                finishLookup(token: token)
                _ = try? await session.commit(.cacheLatch(latch))
                status.text = "\(latch.title) is ready to add."
                onLatch?(latch)
                navigationController?.popViewController(animated: !Motion.reduce)
            } catch let fault as CentoFault where fault == .cancelled {
                finishLookup(token: token)
                return
            } catch let fault as CentoFault {
                finishLookup(token: token)
                status.text = fault.boardLine + " Type the title on the previous screen."
                retry.isHidden = false
            } catch {
                finishLookup(token: token)
                status.text = "The lookup failed. Type the title on the previous screen."
                retry.isHidden = false
            }
        }
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

    private func idleStatusLine() -> String {
        #if targetEnvironment(simulator)
        return "Simulator has no camera. Use a sample ISBN or type one."
        #else
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .denied, .restricted:
            return "The scanner cannot see the barcode because camera access is off. Open Settings to turn it on."
        default:
            return "Hold the back of the book so the ISBN can fill the title."
        }
        #endif
    }
}

/// Role: Volume. Spine-shaped reticle built from stock view styling, not custom drawing.
@MainActor
final class SpineWindowView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = Palette.uiInk.withAlphaComponent(0.08)
        layer.cornerRadius = Radius.card
        layer.cornerCurve = .continuous
        layer.borderColor = Palette.uiAccent.withAlphaComponent(0.8).cgColor
        layer.borderWidth = 2
        isOpaque = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }
}
