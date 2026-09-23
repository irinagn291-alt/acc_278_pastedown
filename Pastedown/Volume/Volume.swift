import Foundation

/// Role: Volume. Flat side-table record for a book. Cuttings live in StoreRoot, not nested here,
/// so one quote-store exists per volumeID. Progress is currentPage / totalPages, never a star.
struct Volume: Equatable, Codable, Sendable, Identifiable {
    var id: VolumeID
    var title: String
    var maker: String
    var isbn: String?
    var currentPage: Int
    var totalPages: Int
    var gone: GoneMark?

    init(
        id: VolumeID = VolumeID(),
        title: String,
        maker: String,
        isbn: String? = nil,
        currentPage: Int,
        totalPages: Int,
        gone: GoneMark? = nil
    ) {
        self.id = id
        self.title = title
        self.maker = maker
        self.isbn = isbn
        self.currentPage = currentPage
        self.totalPages = totalPages
        self.gone = gone
    }

    var isGone: Bool { gone != nil }

    /// Family invariant: progressFraction equals currentPage / totalPages.
    var progressFraction: Double {
        guard totalPages > 0 else { return 0 }
        let raw = Double(currentPage) / Double(totalPages)
        if raw < 0 { return 0 }
        if raw > 1 { return 1 }
        return raw
    }
}

/// Role: Volume. Stable identity for the volume side table.
struct VolumeID: Hashable, Codable, Sendable, RawRepresentable {
    var rawValue: UUID

    init(rawValue: UUID) {
        self.rawValue = rawValue
    }

    init(_ rawValue: UUID = UUID()) {
        self.rawValue = rawValue
    }
}
