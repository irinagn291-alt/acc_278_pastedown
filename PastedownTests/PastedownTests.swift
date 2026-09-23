import XCTest
@testable import Pastedown

/// Placeholder. Replace with the cases required by SPEC.md section 17.
final class PastedownTests: XCTestCase {
    func test_appModuleImports() {
        XCTAssertEqual(String(describing: PastedownApp.self), "PastedownApp")
    }
}
