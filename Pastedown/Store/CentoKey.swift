import Foundation

/// Role: Store. Preference keys. Snapshot is the assigned UserDefaults contract.
enum CentoKey {
    static let snapshot = "cento.store.v1"
    static let backup = "cento.store.v1.backup"
    static let demo = "pdn.demo.v2"
}

/// Role: Store. Recoverable load outcome. Never crash on a corrupt snapshot.
enum StoreWarning: Equatable, Sendable {
    case recoveredFromBackup
    case startedEmpty
}
