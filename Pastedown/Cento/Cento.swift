import Foundation

/// Role: Cento. Ordered CuttingIDs under a daykey. Never mutated in place: Paste appends,
/// Peel drops the tail, Seal freezes the array. Quote text is not stored here.
struct Cento: Equatable, Codable, Sendable, Identifiable {
    var daykey: Daykey
    var cuttingIDs: [CuttingID]
    var seal: CentoSeal

    var id: Int { daykey.yyyymmdd }

    var isBlank: Bool { cuttingIDs.isEmpty }

    var footID: CuttingID? { cuttingIDs.last }

    init(daykey: Daykey, cuttingIDs: [CuttingID] = [], seal: CentoSeal = .open) {
        self.daykey = daykey
        self.cuttingIDs = cuttingIDs
        self.seal = seal
    }

    func appending(_ id: CuttingID) -> Cento {
        Cento(daykey: daykey, cuttingIDs: cuttingIDs + [id], seal: seal)
    }

    func droppingTail() -> (cento: Cento, lifted: CuttingID?) {
        guard let lifted = cuttingIDs.last else {
            return (self, nil)
        }
        return (Cento(daykey: daykey, cuttingIDs: Array(cuttingIDs.dropLast()), seal: seal), lifted)
    }

    func freezing(as seal: CentoSeal) -> Cento {
        Cento(daykey: daykey, cuttingIDs: cuttingIDs, seal: seal)
    }
}

/// Role: Cento. Open board, sealed gathering tile, or scrap for a thin day.
enum CentoSeal: String, Codable, Equatable, Sendable {
    case open
    case sealed
    case scrap
}
