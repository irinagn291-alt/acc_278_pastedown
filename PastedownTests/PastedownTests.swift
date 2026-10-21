import XCTest
@testable import Pastedown

/// Placeholder. Replace with the cases required by SPEC.md section 17.
@MainActor
final class PastedownTests: XCTestCase {
    func test_appModuleImports() {
        XCTAssertEqual(String(describing: PastedownApp.self), "PastedownApp")
    }

    func test_artSideStaysInsidePhoneAndPadCanvases() {
        let view = EmptyStateView(frame: .zero)
        view.apply(
            art: "pdn_EmptyDrawerMark",
            headline: "The drawer is empty.",
            line: "Write a quote, set its page, and attach it to a volume. It enters as Fresh.",
            action: "Write a cutting",
            onAction: nil
        )
        let canvases = [
            CGSize(width: 320, height: 568),
            CGSize(width: 390, height: 844),
            CGSize(width: 834, height: 1194),
            CGSize(width: 1024, height: 1366),
            CGSize(width: 1366, height: 1024),
        ]
        for size in canvases {
            let side = view.fittedArtSide(in: size)
            XCTAssertGreaterThanOrEqual(side, 0, "\(size)")
            XCTAssertLessThanOrEqual(side, size.width * 0.46 + 0.5, "\(size)")
            XCTAssertLessThanOrEqual(side, size.height * 0.42 + 0.5, "\(size)")
            let textWidth = max(size.width - Space.gutter * 2, 1)
            let headline = UILabel()
            headline.font = TypeScale.uiTitle
            headline.numberOfLines = 0
            headline.text = "The drawer is empty."
            let line = UILabel()
            line.font = TypeScale.uiBody
            line.numberOfLines = 0
            line.text = "Write a quote, set its page, and attach it to a volume. It enters as Fresh."
            let chrome = Space.n(3) + Space.n(2)
                + headline.sizeThatFits(CGSize(width: textWidth, height: size.height)).height
                + Space.n(1)
                + line.sizeThatFits(CGSize(width: textWidth, height: size.height)).height
                + Space.n(2) + Space.tap + Space.n(2)
            XCTAssertLessThanOrEqual(side + chrome, size.height + 1, "copy stays on screen \(size)")
        }
    }

    func test_laidOutEmptyStateStaysInsidePadBounds() {
        let size = CGSize(width: 834, height: 1194)
        let host = UIWindow(frame: CGRect(origin: .zero, size: size))
        let view = EmptyStateView(frame: host.bounds)
        view.apply(
            art: "pdn_EmptyDrawerMark",
            headline: "The drawer is empty.",
            line: "Write a quote, set its page, and attach it to a volume. It enters as Fresh.",
            action: "Write a cutting",
            onAction: nil
        )
        host.addSubview(view)
        host.makeKeyAndVisible()
        view.setNeedsLayout()
        view.layoutIfNeeded()
        let limits = view.bounds.insetBy(dx: -1, dy: -1)
        for subview in view.subviews {
            XCTAssertTrue(limits.contains(subview.frame), "\(subview.frame) outside \(view.bounds)")
        }
        let art = view.subviews[0]
        XCTAssertEqual(art.frame.midX, view.bounds.midX, accuracy: 1)
        XCTAssertLessThanOrEqual(art.frame.width, size.width * 0.46 + 1)
    }

    func test_cuttingsSheetFitsIPad() {
        let size = CGSize(width: 1032, height: 1376)
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let session = CentoSession(store: CentoStore(directory: directory))
        let sheet = DrawerSheetViewController(session: session)
        let nav = UINavigationController(rootViewController: sheet)
        let window = UIWindow(frame: CGRect(origin: .zero, size: size))
        window.rootViewController = nav
        window.makeKeyAndVisible()
        nav.view.setNeedsLayout()
        nav.view.layoutIfNeeded()
        sheet.view.setNeedsLayout()
        sheet.view.layoutIfNeeded()

        let table = sheet.tableView!
        let empty = table.backgroundView
        XCTAssertNotNil(empty)
        XCTAssertEqual(empty?.frame, table.bounds)
        XCTAssertLessThanOrEqual(empty?.bounds.width ?? 0, size.width + 1)

        let headline = findLabel(in: sheet.view, text: "The drawer is empty.")
        XCTAssertNotNil(headline)
        if let headline {
            let frame = headline.convert(headline.bounds, to: sheet.view)
            XCTAssertTrue(sheet.view.bounds.insetBy(dx: -1, dy: -1).contains(frame), "\(frame)")
            XCTAssertGreaterThan(frame.minY, 40)
            XCTAssertLessThan(frame.maxY, sheet.view.bounds.height - 20)
        }
        let action = findButton(in: sheet.view, title: "Write a cutting")
        XCTAssertNotNil(action)
        if let action {
            let frame = action.convert(action.bounds, to: sheet.view)
            XCTAssertTrue(sheet.view.bounds.insetBy(dx: -1, dy: -1).contains(frame), "\(frame)")
            XCTAssertGreaterThan(frame.width, size.width * 0.7)
        }
    }

    private func findLabel(in view: UIView, text: String) -> UILabel? {
        if let label = view as? UILabel, label.text == text { return label }
        for child in view.subviews {
            if let found = findLabel(in: child, text: text) { return found }
        }
        return nil
    }

    private func findButton(in view: UIView, title: String) -> UIButton? {
        if let button = view as? UIButton, button.accessibilityLabel == title { return button }
        for child in view.subviews {
            if let found = findButton(in: child, title: title) { return found }
        }
        return nil
    }
}
