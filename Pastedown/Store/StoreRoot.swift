import Foundation

/// Role: Store. One Codable root. Three flat arrays: volumes, cuttings, centos.
/// Centos store only CuttingIDs so a quote's text exists once. schemaVersion starts at 1.
struct StoreRoot: Equatable, Codable, Sendable {
    var schemaVersion: Int
    var volumes: [Volume]
    var cuttings: [Cutting]
    var centos: [Cento]
    var clashMarks: [ClashMark]
    var latches: [VolumeLatch]
    var onboardingComplete: Bool

    static let empty = StoreRoot(
        schemaVersion: StoreCodec.currentSchema,
        volumes: [],
        cuttings: [],
        centos: [],
        clashMarks: [],
        latches: [],
        onboardingComplete: false
    )

    func volume(_ id: VolumeID) -> Volume? {
        volumes.first { $0.id == id }
    }

    func cutting(_ id: CuttingID) -> Cutting? {
        cuttings.first { $0.id == id }
    }

    func cento(on day: Daykey) -> Cento? {
        centos.first { $0.daykey == day }
    }

    /// Family invariant: one quote-store per book, the cuttings side table filtered by volumeID.
    func quoteStore(for volumeID: VolumeID) -> [Cutting] {
        cuttings.filter { $0.volumeID == volumeID }
    }

    mutating func upsert(_ volume: Volume) {
        if let index = volumes.firstIndex(where: { $0.id == volume.id }) {
            volumes[index] = volume
        } else {
            volumes.append(volume)
        }
    }

    mutating func upsert(_ cutting: Cutting) {
        if let index = cuttings.firstIndex(where: { $0.id == cutting.id }) {
            cuttings[index] = cutting
        } else {
            cuttings.append(cutting)
        }
    }

    mutating func upsert(_ cento: Cento) {
        if let index = centos.firstIndex(where: { $0.daykey == cento.daykey }) {
            centos[index] = cento
        } else {
            centos.append(cento)
        }
    }

    mutating func updateCutting(id: CuttingID, transform: (Cutting) -> Cutting) {
        guard let index = cuttings.firstIndex(where: { $0.id == id }) else { return }
        cuttings[index] = transform(cuttings[index])
    }

    func caching(_ latch: VolumeLatch) -> StoreRoot {
        var next = self
        if let index = next.latches.firstIndex(where: { $0.isbn == latch.isbn }) {
            next.latches[index] = latch
        } else {
            next.latches.append(latch)
        }
        return next
    }

    func latch(for isbn: String) -> VolumeLatch? {
        latches.first { $0.isbn == isbn }
    }
}

/// Role: Store. Schema switch. Domain types never decode the JSON themselves.
enum StoreCodec {
    static let currentSchema = 1

    enum Failure: Error, Equatable {
        case unsupportedSchema(Int)
        case corrupt
    }

    static func encode(_ root: StoreRoot) throws -> Data {
        var copy = root
        copy.schemaVersion = currentSchema
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        encoder.dateEncodingStrategy = .secondsSince1970
        return try encoder.encode(copy)
    }

    static func decode(_ data: Data) throws -> StoreRoot {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        let probe: SchemaProbe
        do {
            probe = try decoder.decode(SchemaProbe.self, from: data)
        } catch {
            throw Failure.corrupt
        }
        switch probe.schemaVersion {
        case 1:
            do {
                var root = try decoder.decode(StoreRoot.self, from: data)
                root.schemaVersion = currentSchema
                return root
            } catch {
                throw Failure.corrupt
            }
        default:
            throw Failure.unsupportedSchema(probe.schemaVersion)
        }
    }
}

private struct SchemaProbe: Decodable {
    var schemaVersion: Int
}
