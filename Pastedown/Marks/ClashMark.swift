import Foundation

/// Role: ClashMark. Written when canFollow refuses a same-volume paste. The foot keeps its line.
struct ClashMark: Equatable, Codable, Sendable, Identifiable {
    var id: UUID
    var daykey: Daykey
    var refusedID: CuttingID
    var footID: CuttingID?
}

/// Role: Cento. Engine side effect. Views read this; they never write records themselves.
enum Mark: Equatable, Sendable {
    case clash(ClashMark)
    case seal(SealMark)
    case scrap(Scrap)
}
