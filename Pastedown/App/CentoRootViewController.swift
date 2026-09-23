import UIKit

/// Role: App. Loads the store, seeds the simulator, then hosts the board. ReviewScreen is read after onboarding.
@MainActor
final class CentoRootViewController: UIViewController {
    let session = CentoSession()
    private let spinner = UIActivityIndicatorView(style: .medium)
    private var board: CentoBoardViewController?
    private var didReveal = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Palette.uiBackground
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.color = Palette.uiMuted
        view.addSubview(spinner)
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
        Task { await boot() }
    }

    private func boot() async {
        let delay = Task {
            try? await Task.sleep(nanoseconds: 150_000_000)
            if !didReveal {
                spinner.startAnimating()
            }
        }
        await session.bootstrap()
        didReveal = true
        delay.cancel()
        spinner.stopAnimating()
        let board = CentoBoardViewController(session: session)
        addChild(board)
        board.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(board.view)
        board.didMove(toParent: self)
        NSLayoutConstraint.activate([
            board.view.topAnchor.constraint(equalTo: view.topAnchor),
            board.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            board.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            board.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        self.board = board
        if session.root.onboardingComplete {
            board.applyReviewHookIfNeeded()
        } else {
            let onboarding = OnboardingViewController(session: session)
            onboarding.onFinished = { [weak board] in
                board?.applyReviewHookIfNeeded()
            }
            CentoChrome.presentFull(onboarding, from: self)
        }
    }
}
