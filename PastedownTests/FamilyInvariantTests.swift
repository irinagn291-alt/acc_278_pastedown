import XCTest
@testable import Pastedown

final class FamilyInvariantTests: XCTestCase {
    private var calendar: Calendar!
    private let now = Date(timeIntervalSince1970: 1_746_000_000)

    override func setUp() {
        calendar = Self.utcCalendar()
    }

    func test_familyInvariant_oneQuoteStorePerVolume_rereadNotStars_progressFraction() throws {
        let engine = CentoEngine(calendar: calendar)
        var root = StoreRoot.empty
        let clayID = VolumeID(fixed("aaaaaaaa-0000-0000-0000-000000000001"))
        let riverID = VolumeID(fixed("aaaaaaaa-0000-0000-0000-000000000002"))
        let slipID = CuttingID(fixed("bbbbbbbb-0000-0000-0000-000000000001"))

        root = try engine.apply(
            .addVolume(
                Volume(
                    id: clayID,
                    title: "Clay Hours",
                    maker: "North Binding",
                    currentPage: 1,
                    totalPages: 200
                )
            ),
            to: root
        ).root
        root = try engine.apply(
            .addVolume(
                Volume(
                    id: riverID,
                    title: "River Sheaf",
                    maker: "Harbor Press",
                    currentPage: 1,
                    totalPages: 100
                )
            ),
            to: root
        ).root
        root = try engine.apply(
            .addCutting(
                Cutting(
                    id: slipID,
                    volumeID: clayID,
                    text: "Keep the line, not the loaned copy.",
                    page: 40
                )
            ),
            to: root
        ).root

        XCTAssertEqual(root.quoteStore(for: clayID).count, 1)
        XCTAssertTrue(root.quoteStore(for: riverID).isEmpty)
        XCTAssertEqual(root.quoteStore(for: clayID).first?.id, slipID)
        XCTAssertEqual(root.quoteStore(for: riverID).map(\.id), [])

        let clay = try XCTUnwrap(root.volume(clayID))
        XCTAssertEqual(clay.progressFraction, 40.0 / 200.0, accuracy: 1e-12)
        XCTAssertEqual(clay.currentPage, 40)

        let volumeLabels = Mirror(reflecting: clay).children.compactMap(\.label)
        XCTAssertFalse(volumeLabels.contains { $0.localizedCaseInsensitiveContains("star") })
        XCTAssertFalse(volumeLabels.contains { $0.localizedCaseInsensitiveContains("rating") })
        XCTAssertFalse(volumeLabels.contains { $0.localizedCaseInsensitiveContains("sheaf") })
        XCTAssertFalse(volumeLabels.contains { $0.localizedCaseInsensitiveContains("quotes") })

        let cutting = try XCTUnwrap(root.cutting(slipID))
        XCTAssertFalse(cutting.reread)
        let cuttingLabels = Mirror(reflecting: cutting).children.compactMap(\.label)
        XCTAssertTrue(cuttingLabels.contains("reread"))
        XCTAssertFalse(cuttingLabels.contains { $0.localizedCaseInsensitiveContains("star") })
        XCTAssertFalse(cuttingLabels.contains { $0.localizedCaseInsensitiveContains("rating") })

        root = try engine.apply(.markReread(slipID, true), to: root).root
        XCTAssertEqual(root.cutting(slipID)?.reread, true)
        XCTAssertEqual(root.quoteStore(for: clayID).filter(\.reread).count, 1)
        XCTAssertEqual(root.quoteStore(for: riverID).filter(\.reread).count, 0)
    }

    private static func utcCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        calendar.locale = Locale(identifier: "en_US_POSIX")
        return calendar
    }

    private func fixed(_ string: String) -> UUID {
        UUID(uuidString: string) ?? UUID()
    }
}
