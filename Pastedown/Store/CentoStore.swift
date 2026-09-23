import Foundation

/// Role: Store. In-memory source of truth. The file and UserDefaults are a projection.
/// UI never touches UserDefaults or StoreRoot encoding.
actor CentoStore {
    private let vault: CentoVault
    private let writer: DebouncedWriter
    private let engine: CentoEngine

    private var latest: StoreRoot = .empty
    private var dirty = false
    private(set) var warning: StoreWarning?
    private(set) var lastWriteError: String?

    init(
        directory: URL,
        suiteName: String? = nil,
        calendar: Calendar = .current,
        writeDelayNanoseconds: UInt64 = 500_000_000
    ) {
        self.vault = CentoVault(directory: directory, suiteName: suiteName)
        self.writer = DebouncedWriter(nanoseconds: writeDelayNanoseconds)
        self.engine = CentoEngine(calendar: calendar)
    }

    static func applicationSupportStore() -> CentoStore {
        let directory: URL
        do {
            directory = try CentoVault.supportDirectory()
        } catch {
            directory = FileManager.default.temporaryDirectory.appendingPathComponent(
                "Pastedown",
                isDirectory: true
            )
        }
        return CentoStore(directory: directory)
    }

    func load() async -> (root: StoreRoot, warning: StoreWarning?) {
        let loaded = vault.load()
        latest = loaded.root
        warning = loaded.warning
        dirty = false
        lastWriteError = nil
        return loaded
    }

    func root() -> StoreRoot {
        latest
    }

    func apply(_ intent: CentoIntent, flushImmediately: Bool = false) async throws -> CentoOutcome {
        let outcome = try engine.apply(intent, to: latest)
        latest = outcome.root
        if flushImmediately {
            try await persistNow()
        } else {
            await schedulePersist()
        }
        return outcome
    }

    func flush() async throws {
        try await writer.runNow { [self] in
            try await self.writeIfDirty()
        }
    }

    func resetAllData() async throws {
        await writer.cancelPending()
        latest = .empty
        dirty = false
        warning = nil
        lastWriteError = nil
        try vault.wipe()
    }

    func markOnboardingComplete() async throws {
        latest.onboardingComplete = true
        try await persistNow()
    }

    func writeIssue() -> String? {
        lastWriteError
    }

    func seedDemoIfNeeded(now: Date, calendar: Calendar) async throws -> StoreRoot? {
        #if targetEnvironment(simulator)
        let reviewLaunch = ReviewScreenHook.destinationFromProcessInfo() != nil
        if vault.demoPlanted(), !reviewLaunch { return nil }
        latest = DemoSeed.root(now: now, calendar: calendar)
        try await persistNow()
        vault.markDemoPlanted()
        return latest
        #else
        return nil
        #endif
    }

    private func schedulePersist() async {
        dirty = true
        await writer.schedule { [self] in
            do {
                try await self.writeIfDirty()
            } catch {
                await self.remember(error)
            }
        }
    }

    private func writeIfDirty() async throws {
        guard dirty else { return }
        try vault.save(latest)
        dirty = false
        lastWriteError = nil
    }

    private func persistNow() async throws {
        dirty = true
        try await writer.runNow { [self] in
            try await self.writeIfDirty()
        }
    }

    private func remember(_ error: Error) {
        lastWriteError = String(describing: error)
    }
}
