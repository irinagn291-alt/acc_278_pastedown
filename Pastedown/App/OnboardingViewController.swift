import UIKit

/// Role: App. Three quiet panels. Continue is pinned bottom and full width. Skip writes defaults.
@MainActor
final class OnboardingViewController: UIViewController {
    var onFinished: (() -> Void)?
    private let session: CentoSession
    private let pager = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
    private let continueButton = GlassActionButton(title: "Continue")
    private let skipButton = UIButton(type: .system)
    private let dots = UIPageControl()
    private var pages: [UIViewController] = []
    private var index = 0

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
        view.backgroundColor = Palette.uiBackground
        pages = [
            panel(
                art: "pdn_Onboarding1",
                title: "Keep the line after the book leaves.",
                body: "Pastedown holds quotes from volumes you sell, lend, lose, or cull. The sentence stays on this device."
            ),
            panel(
                art: "pdn_Onboarding2",
                title: "Paste the next line onto today's board.",
                body: "Pick a cutting in the drawer and tap Paste. The quote lands as a strip at the foot of the cento."
            ),
            panel(
                art: "pdn_Onboarding3",
                title: "Two neighbours cannot share a volume.",
                body: "A cutting from the same book as the foot will not land. The clash tally counts each refusal, and another volume is always pastable."
            ),
        ]
        addChild(pager)
        pager.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pager.view)
        pager.didMove(toParent: self)
        pager.dataSource = self
        pager.delegate = self
        pager.setViewControllers([pages[0]], direction: .forward, animated: false)
        dots.numberOfPages = pages.count
        dots.currentPage = 0
        dots.pageIndicatorTintColor = Palette.uiMuted
        dots.currentPageIndicatorTintColor = Palette.uiAccent
        dots.translatesAutoresizingMaskIntoConstraints = false
        skipButton.setTitle("Skip", for: .normal)
        skipButton.setTitleColor(Palette.uiMuted, for: .normal)
        skipButton.titleLabel?.font = TypeScale.uiBody
        skipButton.titleLabel?.adjustsFontForContentSizeCategory = true
        skipButton.addTarget(self, action: #selector(finish), for: .touchUpInside)
        skipButton.translatesAutoresizingMaskIntoConstraints = false
        continueButton.addTarget(self, action: #selector(advance), for: .touchUpInside)
        view.addSubview(dots)
        view.addSubview(skipButton)
        view.addSubview(continueButton)
        NSLayoutConstraint.activate([
            pager.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            pager.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pager.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dots.topAnchor.constraint(equalTo: pager.view.bottomAnchor, constant: Space.n(1)),
            dots.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            skipButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: Space.unit),
            skipButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Space.gutter),
            skipButton.heightAnchor.constraint(greaterThanOrEqualToConstant: Space.tap),
            continueButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Space.gutter),
            continueButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Space.gutter),
            continueButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -Space.n(2)),
            dots.bottomAnchor.constraint(equalTo: continueButton.topAnchor, constant: -Space.n(2)),
        ])
    }

    private func panel(art: String, title: String, body: String) -> UIViewController {
        let page = UIViewController()
        page.view.backgroundColor = Palette.uiBackground
        let image = UIImageView(image: UIImage(named: art))
        image.contentMode = .scaleAspectFit
        image.isAccessibilityElement = false
        let headline = UILabel()
        headline.text = title
        headline.font = TypeScale.uiDisplay
        headline.textColor = Palette.uiInk
        headline.numberOfLines = 3
        headline.adjustsFontForContentSizeCategory = true
        let copy = UILabel()
        copy.text = body
        copy.font = TypeScale.uiBody
        copy.textColor = Palette.uiMuted
        copy.numberOfLines = 0
        copy.adjustsFontForContentSizeCategory = true
        image.translatesAutoresizingMaskIntoConstraints = false
        headline.translatesAutoresizingMaskIntoConstraints = false
        copy.translatesAutoresizingMaskIntoConstraints = false
        page.view.addSubview(image)
        page.view.addSubview(headline)
        page.view.addSubview(copy)
        NSLayoutConstraint.activate([
            image.topAnchor.constraint(equalTo: page.view.safeAreaLayoutGuide.topAnchor, constant: Space.n(6)),
            image.centerXAnchor.constraint(equalTo: page.view.centerXAnchor),
            image.widthAnchor.constraint(equalTo: page.view.widthAnchor, multiplier: 0.55),
            image.heightAnchor.constraint(equalTo: image.widthAnchor),
            headline.topAnchor.constraint(equalTo: image.bottomAnchor, constant: Space.n(3)),
            headline.leadingAnchor.constraint(equalTo: page.view.leadingAnchor, constant: Space.gutter),
            headline.trailingAnchor.constraint(equalTo: page.view.trailingAnchor, constant: -Space.gutter),
            copy.topAnchor.constraint(equalTo: headline.bottomAnchor, constant: Space.n(2)),
            copy.leadingAnchor.constraint(equalTo: headline.leadingAnchor),
            copy.trailingAnchor.constraint(equalTo: headline.trailingAnchor),
        ])
        return page
    }

    @objc private func advance() {
        if index >= pages.count - 1 {
            finish()
            return
        }
        index += 1
        pager.setViewControllers([pages[index]], direction: .forward, animated: !Motion.reduce)
        dots.currentPage = index
        if index == pages.count - 1 {
            continueButton.setCaption("Continue")
        }
    }

    @objc private func finish() {
        Task {
            await session.finishOnboarding()
            dismiss(animated: !Motion.reduce) { [weak self] in
                self?.onFinished?()
            }
        }
    }
}

extension OnboardingViewController: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let current = pages.firstIndex(of: viewController), current > 0 else { return nil }
        return pages[current - 1]
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let current = pages.firstIndex(of: viewController), current < pages.count - 1 else { return nil }
        return pages[current + 1]
    }

    func pageViewController(
        _ pageViewController: UIPageViewController,
        didFinishAnimating finished: Bool,
        previousViewControllers: [UIViewController],
        transitionCompleted completed: Bool
    ) {
        guard completed, let visible = pageViewController.viewControllers?.first,
              let current = pages.firstIndex(of: visible) else { return }
        index = current
        dots.currentPage = current
    }
}
