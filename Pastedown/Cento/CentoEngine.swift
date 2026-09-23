import Foundation

/// Role: Cento. Value-type mutation seam. Takes a StoreRoot and an intent, returns a new
/// StoreRoot plus an optional Mark. Views never edit a record. Legality is canFollow.
struct CentoEngine: Sendable {
    var calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    /// Adjacent-volume ban. False when next is spent or shares the foot strip's volumeID.
    static func canFollow(foot: Cutting?, next: Cutting) -> Bool {
        if next.state == .spent { return false }
        guard let foot else { return true }
        return foot.volumeID != next.volumeID
    }

    func apply(_ intent: CentoIntent, to root: StoreRoot) throws -> CentoOutcome {
        switch intent {
        case .paste(let cuttingID, let date):
            return try paste(cuttingID, at: date, root: root)
        case .peel(let date):
            return try peel(at: date, root: root)
        case .resolveMidnight(let date):
            return resolveMidnight(at: date, root: root)
        case .addVolume(let volume):
            return try addVolume(volume, root: root)
        case .addCutting(let cutting):
            return try addCutting(cutting, root: root)
        case .editCutting(let cutting):
            return try editCutting(cutting, root: root)
        case .markGone(let volumeID, let reason, let date):
            return try markGone(volumeID, reason: reason, at: date, root: root)
        case .markReread(let cuttingID, let reread):
            return try markReread(cuttingID, reread: reread, root: root)
        case .latch(let volumeID, let latch):
            return try adoptLatch(volumeID, latch: latch, root: root)
        case .cacheLatch(let latch):
            return CentoOutcome(root: root.caching(latch), mark: nil)
        }
    }

    private func paste(_ cuttingID: CuttingID, at date: Date, root: StoreRoot) throws -> CentoOutcome {
        let day = Daykey.of(date, calendar: calendar)
        var next = root
        var cento = next.cento(on: day) ?? Cento(daykey: day)
        guard cento.seal == .open else { throw CentoFault.centoSealed }
        guard let cutting = next.cutting(cuttingID) else { throw CentoFault.unknownCutting }
        let foot = cento.footID.flatMap { next.cutting($0) }
        if cutting.state == .spent {
            throw CentoFault.spentCutting
        }
        if !Self.canFollow(foot: foot, next: cutting) {
            let clash = ClashMark(
                id: UUID(),
                daykey: day,
                refusedID: cuttingID,
                footID: foot?.id
            )
            next.clashMarks.append(clash)
            return CentoOutcome(root: next, mark: .clash(clash))
        }
        cento = cento.appending(cuttingID)
        next.upsert(cento)
        next.updateCutting(id: cuttingID) { item in
            var copy = item
            copy.state = .pasted
            return copy
        }
        if var volume = next.volume(cutting.volumeID), volume.gone == nil {
            volume.currentPage = cutting.page
            if volume.isbn == nil, cutting.page > volume.totalPages {
                volume.totalPages = cutting.page
            }
            next.upsert(volume)
        }
        return CentoOutcome(root: next, mark: nil)
    }

    private func peel(at date: Date, root: StoreRoot) throws -> CentoOutcome {
        let day = Daykey.of(date, calendar: calendar)
        var next = root
        guard var cento = next.cento(on: day) else {
            return CentoOutcome(root: next, mark: nil)
        }
        guard cento.seal == .open else { throw CentoFault.centoSealed }
        let lifted: CuttingID?
        (cento, lifted) = cento.droppingTail()
        next.upsert(cento)
        if let lifted {
            next.updateCutting(id: lifted) { item in
                var copy = item
                copy.state = .fresh
                return copy
            }
        }
        return CentoOutcome(root: next, mark: nil)
    }

    private func resolveMidnight(at date: Date, root: StoreRoot) -> CentoOutcome {
        let today = Daykey.of(date, calendar: calendar)
        var next = root
        var lastMark: Mark?
        let stale = next.centos.filter { $0.seal == .open && $0.daykey < today }
        for cento in stale {
            let verdict = MidnightSeal.verdict(stripCount: cento.cuttingIDs.count)
            next.upsert(cento.freezing(as: verdict))
            switch verdict {
            case .sealed:
                for id in cento.cuttingIDs {
                    next.updateCutting(id: id) { item in
                        var copy = item
                        copy.state = .spent
                        return copy
                    }
                }
                let seal = SealMark(daykey: cento.daykey, stripCount: cento.cuttingIDs.count)
                lastMark = .seal(seal)
            case .scrap:
                for id in cento.cuttingIDs {
                    next.updateCutting(id: id) { item in
                        var copy = item
                        copy.state = .fresh
                        return copy
                    }
                }
                lastMark = .scrap(Scrap(daykey: cento.daykey, returnedIDs: cento.cuttingIDs))
            case .open:
                break
            }
        }
        if next.cento(on: today) == nil {
            next.upsert(Cento(daykey: today))
        }
        return CentoOutcome(root: next, mark: lastMark)
    }

    private func addVolume(_ volume: Volume, root: StoreRoot) throws -> CentoOutcome {
        let title = volume.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { throw CentoFault.missingTitle }
        try Self.requirePlayhead(volume.currentPage, totalPages: volume.totalPages)
        var stored = volume
        stored.title = title
        stored.maker = volume.maker.trimmingCharacters(in: .whitespacesAndNewlines)
        var next = root
        next.upsert(stored)
        return CentoOutcome(root: next, mark: nil)
    }

    private func addCutting(_ cutting: Cutting, root: StoreRoot) throws -> CentoOutcome {
        guard root.volume(cutting.volumeID) != nil else { throw CentoFault.unknownVolume }
        let text = cutting.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { throw CentoFault.emptyQuote }
        let volume = try requireVolume(cutting.volumeID, root: root)
        try Self.requireCuttingPage(cutting.page, volume: volume)
        var stored = cutting
        stored.text = text
        stored.state = .fresh
        var next = root
        next.upsert(stored)
        if var live = next.volume(cutting.volumeID), live.gone == nil {
            live.currentPage = cutting.page
            if live.isbn == nil, cutting.page > live.totalPages {
                live.totalPages = cutting.page
            }
            next.upsert(live)
        }
        return CentoOutcome(root: next, mark: nil)
    }

    private func editCutting(_ cutting: Cutting, root: StoreRoot) throws -> CentoOutcome {
        guard root.cutting(cutting.id) != nil else { throw CentoFault.unknownCutting }
        guard root.volume(cutting.volumeID) != nil else { throw CentoFault.unknownVolume }
        let text = cutting.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { throw CentoFault.emptyQuote }
        let volume = try requireVolume(cutting.volumeID, root: root)
        try Self.requireCuttingPage(cutting.page, volume: volume)
        var stored = cutting
        stored.text = text
        var next = root
        next.upsert(stored)
        if var live = next.volume(cutting.volumeID), live.gone == nil {
            if live.isbn == nil, cutting.page > live.totalPages {
                live.totalPages = cutting.page
            }
            if live.currentPage > live.totalPages {
                live.currentPage = live.totalPages
            }
            next.upsert(live)
        }
        return CentoOutcome(root: next, mark: nil)
    }

    private func markGone(
        _ volumeID: VolumeID,
        reason: GoneReason,
        at date: Date,
        root: StoreRoot
    ) throws -> CentoOutcome {
        guard var volume = root.volume(volumeID) else { throw CentoFault.unknownVolume }
        if volume.gone != nil { throw CentoFault.alreadyGone }
        volume.gone = GoneMark(reason: reason, date: date)
        var next = root
        next.upsert(volume)
        return CentoOutcome(root: next, mark: nil)
    }

    private func markReread(_ cuttingID: CuttingID, reread: Bool, root: StoreRoot) throws -> CentoOutcome {
        guard root.cutting(cuttingID) != nil else { throw CentoFault.unknownCutting }
        var next = root
        next.updateCutting(id: cuttingID) { item in
            var copy = item
            copy.reread = reread
            return copy
        }
        return CentoOutcome(root: next, mark: nil)
    }

    private func adoptLatch(_ volumeID: VolumeID, latch: VolumeLatch, root: StoreRoot) throws -> CentoOutcome {
        guard var volume = root.volume(volumeID) else { throw CentoFault.unknownVolume }
        if !latch.title.isEmpty { volume.title = latch.title }
        if !latch.maker.isEmpty { volume.maker = latch.maker }
        volume.isbn = latch.isbn
        if let pages = latch.pageCount, pages >= 1 {
            volume.totalPages = max(volume.totalPages, pages)
            if volume.currentPage > volume.totalPages {
                volume.currentPage = volume.totalPages
            }
        }
        var next = root.caching(latch)
        next.upsert(volume)
        return CentoOutcome(root: next, mark: nil)
    }

    private func requireVolume(_ id: VolumeID, root: StoreRoot) throws -> Volume {
        guard let volume = root.volume(id) else { throw CentoFault.unknownVolume }
        return volume
    }

    static func requirePage(_ page: Int, totalPages: Int) throws {
        guard totalPages >= 1, page >= 1, page <= totalPages else {
            throw CentoFault.pageOutOfRange
        }
    }

    static func requireCuttingPage(_ page: Int, volume: Volume) throws {
        guard page >= 1 else { throw CentoFault.pageOutOfRange }
        if volume.isbn == nil {
            return
        }
        try requirePage(page, totalPages: volume.totalPages)
    }

    static func requirePlayhead(_ page: Int, totalPages: Int) throws {
        guard totalPages >= 1, page >= 0, page <= totalPages else {
            throw CentoFault.pageOutOfRange
        }
    }
}

/// Role: Cento. Intents the engine accepts. Storage applies the returned root.
enum CentoIntent: Equatable, Sendable {
    case paste(CuttingID, at: Date)
    case peel(at: Date)
    case resolveMidnight(at: Date)
    case addVolume(Volume)
    case addCutting(Cutting)
    case editCutting(Cutting)
    case markGone(VolumeID, GoneReason, at: Date)
    case markReread(CuttingID, Bool)
    case latch(VolumeID, VolumeLatch)
    case cacheLatch(VolumeLatch)
}

/// Role: Cento. New root plus optional clash, seal, or scrap.
struct CentoOutcome: Equatable, Sendable {
    var root: StoreRoot
    var mark: Mark?
}
