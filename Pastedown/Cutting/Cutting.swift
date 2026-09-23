import Foundation

/// Role: Cutting. Flat quote record. Text lives once here; a Strip is only a projection.
/// Verdict is reread / not. There is no star or rating field.
struct Cutting: Equatable, Codable, Sendable, Identifiable {
    var id: CuttingID
    var volumeID: VolumeID
    var text: String
    var page: Int
    var state: CuttingState
    var reread: Bool

    init(
        id: CuttingID = CuttingID(),
        volumeID: VolumeID,
        text: String,
        page: Int,
        state: CuttingState = .fresh,
        reread: Bool = false
    ) {
        self.id = id
        self.volumeID = volumeID
        self.text = text
        self.page = page
        self.state = state
        self.reread = reread
    }
}

/// Role: Cutting. Stable identity referenced by a Cento array.
struct CuttingID: Hashable, Codable, Sendable, RawRepresentable {
    var rawValue: UUID

    init(rawValue: UUID) {
        self.rawValue = rawValue
    }

    init(_ rawValue: UUID = UUID()) {
        self.rawValue = rawValue
    }
}
