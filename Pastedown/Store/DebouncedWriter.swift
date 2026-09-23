import Foundation

/// Role: Store. Coalesces a burst of paste, peel, and edit into one encode after half a second.
actor DebouncedWriter {
    private var work: Task<Void, Never>?
    private let nanoseconds: UInt64

    init(nanoseconds: UInt64 = 500_000_000) {
        self.nanoseconds = nanoseconds
    }

    func schedule(_ body: @escaping @Sendable () async -> Void) {
        work?.cancel()
        let wait = nanoseconds
        work = Task {
            if wait > 0 {
                try? await Task.sleep(nanoseconds: wait)
            }
            guard !Task.isCancelled else { return }
            await body()
        }
    }

    func cancelPending() {
        work?.cancel()
        work = nil
    }

    func runNow(_ body: @escaping @Sendable () async throws -> Void) async throws {
        work?.cancel()
        work = nil
        try await body()
    }
}
