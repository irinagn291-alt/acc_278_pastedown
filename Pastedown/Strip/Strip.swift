import Foundation

/// Role: Strip. Render projection of a Cutting plus its seat. Not persisted. Poem is a reduce.
struct Strip: Equatable, Sendable, Identifiable {
    var cuttingID: CuttingID
    var seat: Int
    var text: String
    var page: Int
    var volumeID: VolumeID
    var volumeTitle: String
    var maker: String
    var isGone: Bool

    var id: CuttingID { cuttingID }

    /// Reduce the cento ID array through the two side tables. Text is read once from cuttings.
    static func poem(from cento: Cento, root: StoreRoot) -> [Strip] {
        cento.cuttingIDs.enumerated().compactMap { index, id in
            guard let cutting = root.cutting(id) else { return nil }
            let volume = root.volume(cutting.volumeID)
            return Strip(
                cuttingID: id,
                seat: index,
                text: cutting.text,
                page: cutting.page,
                volumeID: cutting.volumeID,
                volumeTitle: volume?.title ?? "",
                maker: volume?.maker ?? "",
                isGone: volume?.isGone ?? false
            )
        }
    }
}
