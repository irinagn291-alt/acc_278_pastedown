import XCTest
@testable import Pastedown

final class ReviewScreenHookTests: XCTestCase {
    func test_todayLogGoalsAreDistinct() {
        let today = ReviewScreenHook.destination(from: ["-ReviewScreen", "today"])
        let log = ReviewScreenHook.destination(from: ["-ReviewScreen", "log"])
        let goals = ReviewScreenHook.destination(from: ["-ReviewScreen", "goals"])
        XCTAssertEqual(today, .today)
        XCTAssertEqual(log, .log)
        XCTAssertEqual(goals, .goals)
        XCTAssertNotEqual(today, log)
        XCTAssertNotEqual(log, goals)
        XCTAssertNotEqual(today, goals)
    }

    func test_extraSlugsOpenOtherSheets() {
        XCTAssertEqual(
            ReviewScreenHook.destination(from: ["-Apple", "-ReviewScreen", "volumes"]),
            .volumes
        )
        XCTAssertEqual(
            ReviewScreenHook.destination(from: ["-ReviewScreen", "settings"]),
            .settings
        )
    }

    func test_unknownSlugFallsThrough() {
        XCTAssertNil(ReviewScreenHook.destination(from: ["-ReviewScreen", "kiln"]))
        XCTAssertNil(ReviewScreenHook.destination(from: ["today"]))
        XCTAssertNil(ReviewScreenHook.destination(from: ["-ReviewScreen"]))
    }
}
