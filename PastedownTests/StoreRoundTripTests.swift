import XCTest
@testable import Pastedown

final class StoreRoundTripTests: XCTestCase {
    private var directory: URL!
    private var suiteName: String!
    private var defaults: UserDefaults!
    private var calendar: Calendar!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent(
            UUID().uuidString,
            isDirectory: true
        )
        suiteName = "pdn.test.\(UUID().uuidString)"
        defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        calendar = Self.utcCalendar()
    }

    override func tearDownWithError() throws {
        if let directory {
            try? FileManager.default.removeItem(at: directory)
        }
        if let suiteName {
            defaults?.removePersistentDomain(forName: suiteName)
        }
        directory = nil
        defaults = nil
        suiteName = nil
    }

    func test_roundTrip_reloadPreservesCentoIDsAndQuoteTextOnce() async throws {
        let store = makeStore()
        let now = Date(timeIntervalSince1970: 1_746_000_000)
        _ = try await store.apply(.addVolume(DemoSeed.root(now: now, calendar: calendar).volumes[0]))
        _ = try await store.apply(
            .addCutting(
                Cutting(
                    id: DemoSeed.boardCuttingID,
                    volumeID: DemoSeed.paperHoursID,
                    text: "The line outlives the binding that first held it.",
                    page: 42
                )
            )
        )
        _ = try await store.apply(.paste(DemoSeed.boardCuttingID, at: now), flushImmediately: true)

        let relaunched = makeStore()
        let loaded = await relaunched.load()
        XCTAssertNil(loaded.warning)
        XCTAssertEqual(loaded.root.volumes.first?.id, DemoSeed.paperHoursID)
        XCTAssertEqual(loaded.root.cuttings.first?.text, "The line outlives the binding that first held it.")
        XCTAssertEqual(
            loaded.root.cento(on: Daykey.of(now, calendar: calendar))?.cuttingIDs,
            [DemoSeed.boardCuttingID]
        )
        XCTAssertNotNil(defaults.data(forKey: CentoKey.snapshot))
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: directory.appendingPathComponent("cento.json").path)
        )
    }

    func test_corruptSnapshotFallsBackToBackup() async throws {
        let store = makeStore()
        let now = Date(timeIntervalSince1970: 1_746_000_000)
        let seed = DemoSeed.root(now: now, calendar: calendar)
        _ = try await store.apply(.addVolume(seed.volumes[0]), flushImmediately: true)
        if let good = defaults.data(forKey: CentoKey.snapshot) {
            defaults.set(good, forKey: CentoKey.backup)
        }
        let file = directory.appendingPathComponent("cento.json")
        let backup = directory.appendingPathComponent("cento.json.backup")
        if FileManager.default.fileExists(atPath: file.path) {
            try? FileManager.default.removeItem(at: backup)
            try FileManager.default.copyItem(at: file, to: backup)
        }
        defaults.set(Data("{not-json".utf8), forKey: CentoKey.snapshot)
        try Data("{not-json".utf8).write(to: file)

        let loaded = await makeStore().load()
        XCTAssertEqual(loaded.warning, .recoveredFromBackup)
        XCTAssertEqual(loaded.root.volumes.first?.id, DemoSeed.paperHoursID)
    }

    func test_corruptSnapshotWithoutBackupStartsEmpty() async throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defaults.set(Data("nope".utf8), forKey: CentoKey.snapshot)
        try Data("nope".utf8).write(to: directory.appendingPathComponent("cento.json"))
        let loaded = await makeStore().load()
        XCTAssertEqual(loaded.warning, .startedEmpty)
        XCTAssertTrue(loaded.root.volumes.isEmpty)
    }

    func test_codecSwitchesOnSchemaVersion() throws {
        let now = Date(timeIntervalSince1970: 1_746_000_000)
        let data = try StoreCodec.encode(DemoSeed.root(now: now, calendar: calendar))
        let decoded = try StoreCodec.decode(data)
        XCTAssertEqual(decoded.schemaVersion, 1)
        XCTAssertEqual(decoded.volumes.count, 4)
        XCTAssertEqual(decoded.cuttings.count, 8)
        XCTAssertTrue(decoded.onboardingComplete)
        XCTAssertEqual(decoded.centos.first?.cuttingIDs, [
            DemoSeed.boardCuttingID,
            DemoSeed.drawerLentID,
            DemoSeed.drawerCulledID,
        ])
        XCTAssertEqual(decoded.centos.filter { $0.seal == .sealed }.count, 1)
        XCTAssertEqual(decoded.clashMarks.count, 1)

        let future = Data("{\"schemaVersion\":99}".utf8)
        XCTAssertThrowsError(try StoreCodec.decode(future)) { error in
            XCTAssertEqual(error as? StoreCodec.Failure, .unsupportedSchema(99))
        }
        XCTAssertThrowsError(try StoreCodec.decode(Data("[]".utf8))) { error in
            XCTAssertEqual(error as? StoreCodec.Failure, .corrupt)
        }
    }

    func test_resetAllDataClearsSnapshotAndFiles() async throws {
        let store = makeStore()
        let now = Date(timeIntervalSince1970: 1_746_000_000)
        _ = try await store.apply(
            .addVolume(DemoSeed.root(now: now, calendar: calendar).volumes[0]),
            flushImmediately: true
        )
        try await store.resetAllData()
        let loaded = await store.load()
        XCTAssertTrue(loaded.root.volumes.isEmpty)
        XCTAssertNil(defaults.data(forKey: CentoKey.snapshot))
        XCTAssertNil(defaults.data(forKey: CentoKey.backup))
        let leftovers = (try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil
        )) ?? []
        XCTAssertTrue(leftovers.filter { $0.pathExtension == "json" }.isEmpty)
    }

    #if targetEnvironment(simulator)
    func test_simulatorSeedWritesOnce() async throws {
        let store = makeStore()
        let now = Date(timeIntervalSince1970: 1_746_000_000)
        let first = try await store.seedDemoIfNeeded(now: now, calendar: calendar)
        let second = try await store.seedDemoIfNeeded(now: now, calendar: calendar)
        XCTAssertNil(second)
        XCTAssertEqual(first?.volumes.count, 4)
        XCTAssertEqual(first?.cuttings.count, 8)
        XCTAssertTrue(first?.onboardingComplete ?? false)
        XCTAssertEqual(first?.centos.first?.cuttingIDs.count, 3)
        let foot = first?.centos.first?.footID.flatMap { first?.cutting($0) }
        let candidate = first?.cutting(DemoSeed.drawerSoldID)
        XCTAssertTrue(CentoEngine.canFollow(foot: foot, next: try XCTUnwrap(candidate)))
        XCTAssertTrue(defaults.bool(forKey: CentoKey.demo))
        XCTAssertNotNil(defaults.data(forKey: CentoKey.snapshot))
    }
    #endif

    private func makeStore() -> CentoStore {
        CentoStore(
            directory: directory,
            suiteName: suiteName,
            calendar: calendar,
            writeDelayNanoseconds: 0
        )
    }

    private static func utcCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        calendar.locale = Locale(identifier: "en_US_POSIX")
        return calendar
    }
}
