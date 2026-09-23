import XCTest
@testable import Pastedown

final class ISBNChecksumTests: XCTestCase {
    func test_isbn13Checksum() {
        let isbn = ISBN.parse("978-0-306-40615-7")
        XCTAssertEqual(isbn?.canonical, "9780306406157")
        XCTAssertNil(ISBN.parse("9780306406158"))
    }

    func test_isbn10ChecksumAndX() {
        XCTAssertEqual(ISBN.parse("0-306-40615-2")?.canonical, "0306406152")
        XCTAssertNotNil(ISBN.parse("080442957X"))
        XCTAssertNil(ISBN.parse("0306406153"))
    }

    func test_upcAPadsToThirteen() {
        XCTAssertEqual(ISBN.parse("000000000000")?.canonical, "0000000000000")
        XCTAssertNil(ISBN.parse("111111111111"))
    }

    func test_extractsDigitRunFromURL() {
        let raw = "https://openlibrary.org/isbn/9780306406157"
        XCTAssertEqual(ISBN.extract(from: raw)?.canonical, "9780306406157")
    }
}
