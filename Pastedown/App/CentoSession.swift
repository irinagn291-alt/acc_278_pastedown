import Foundation
import UIKit

/// Role: App. Main-actor seam. Views send intents. The engine mutates StoreRoot. Storage stays here.
@MainActor
final class CentoSession: NSObject {
    let store: CentoStore
    let lookup: VolumeLookup
    let calendar: Calendar

    private(set) var root: StoreRoot = .empty
    private(set) var warning: StoreWarning?
    private(set) var persistError: String?
    var selectedCuttingID: CuttingID?
    var onChange: (() -> Void)?

    private var didReadReviewHook = false
    private var observers: [NSObjectProtocol] = []

    init(
        store: CentoStore = .applicationSupportStore(),
        lookup: VolumeLookup = VolumeLookup(),
        calendar: Calendar = .current
    ) {
        self.store = store
        self.lookup = lookup
        self.calendar = calendar
        super.init()
        observeLifecycle()
    }

    func bootstrap() async {
        let loaded = await store.load()
        root = loaded.root
        warning = loaded.warning
        do {
            if let seeded = try await store.seedDemoIfNeeded(now: Date(), calendar: calendar) {
                root = seeded
            }
        } catch {
            persistError = error.localizedDescription
        }
        await resolveMidnight()
        adoptDefaultSelection()
        onChange?()
    }

    @discardableResult
    func commit(_ intent: CentoIntent, flushImmediately: Bool = false) async throws -> CentoOutcome {
        let outcome = try await store.apply(intent, flushImmediately: flushImmediately)
        root = outcome.root
        persistError = await store.writeIssue()
        adoptDefaultSelection()
        onChange?()
        return outcome
    }

    func finishOnboarding() async {
        do {
            try await store.markOnboardingComplete()
            root = await store.root()
            persistError = nil
        } catch {
            root.onboardingComplete = true
            persistError = error.localizedDescription
        }
        onChange?()
    }

    func resetStore() async throws {
        try await store.resetAllData()
        root = await store.root()
        warning = nil
        persistError = nil
        selectedCuttingID = nil
        onChange?()
    }

    func flush() async {
        do {
            try await store.flush()
            persistError = nil
        } catch {
            persistError = error.localizedDescription
            onChange?()
        }
    }

    func resolveMidnight() async {
        do {
            _ = try await commit(.resolveMidnight(at: Date()))
        } catch {
            persistError = error.localizedDescription
            onChange?()
        }
    }

    var today: Daykey {
        Daykey.of(Date(), calendar: calendar)
    }

    var todayCento: Cento {
        root.cento(on: today) ?? Cento(daykey: today)
    }

    var todayStrips: [Strip] {
        Strip.poem(from: todayCento, root: root)
    }

    var footCutting: Cutting? {
        todayCento.footID.flatMap { root.cutting($0) }
    }

    func canPaste(_ cutting: Cutting) -> Bool {
        CentoEngine.canFollow(foot: footCutting, next: cutting)
    }

    var pasteIsEnabled: Bool {
        todayCento.seal == .open && root.cuttings.contains { canPaste($0) }
    }

    var peelIsEnabled: Bool {
        todayCento.seal == .open && !todayCento.isBlank
    }

    func pasteTargetID() -> CuttingID? {
        if let id = selectedCuttingID, root.cutting(id) != nil {
            return id
        }
        return DrawerOrdering.ordered(root.cuttings).first { canPaste($0) }?.id
    }

    func adoptDefaultSelection() {
        if let id = selectedCuttingID, let cutting = root.cutting(id), cutting.state != .spent {
            return
        }
        selectedCuttingID = DrawerOrdering.ordered(root.cuttings).first { canPaste($0) }?.id
    }

    func consumeReviewDestination() -> ReviewScreenHook.Destination? {
        guard !didReadReviewHook else { return nil }
        guard root.onboardingComplete else { return nil }
        didReadReviewHook = true
        return ReviewScreenHook.destinationFromProcessInfo()
    }

    private func observeLifecycle() {
        let center = NotificationCenter.default
        observers.append(center.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in
                await self?.flush()
            }
        })
        observers.append(center.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in
                await self?.flush()
            }
        })
        observers.append(center.addObserver(forName: UIApplication.significantTimeChangeNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in
                await self?.resolveMidnight()
            }
        })
        observers.append(center.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in
                await self?.resolveMidnight()
            }
        })
    }
}
