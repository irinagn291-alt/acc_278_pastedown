import Foundation

/// Role: Store. Projects StoreRoot to UserDefaults plus an atomic Application Support file.
struct CentoVault: Sendable {
    var directory: URL
    var suiteName: String?

    init(directory: URL, suiteName: String? = nil) {
        self.directory = directory
        self.suiteName = suiteName
    }

    static func supportDirectory() throws -> URL {
        let root = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        return root.appendingPathComponent("Pastedown", isDirectory: true)
    }

    func load() -> (root: StoreRoot, warning: StoreWarning?) {
        if let root = decode(box().data(forKey: CentoKey.snapshot)) {
            return (root, nil)
        }
        if let root = decode(read(fileURL)) {
            return (root, nil)
        }
        if let root = decode(box().data(forKey: CentoKey.backup)) {
            return (root, .recoveredFromBackup)
        }
        if let root = decode(read(backupURL)) {
            return (root, .recoveredFromBackup)
        }
        let hadPayload = box().data(forKey: CentoKey.snapshot) != nil
            || FileManager.default.fileExists(atPath: fileURL.path)
        return (.empty, hadPayload ? .startedEmpty : nil)
    }

    func save(_ root: StoreRoot) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = try StoreCodec.encode(root)
        let defaults = box()
        if let current = defaults.data(forKey: CentoKey.snapshot) {
            defaults.set(current, forKey: CentoKey.backup)
        }
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try? FileManager.default.removeItem(at: backupURL)
            try? FileManager.default.copyItem(at: fileURL, to: backupURL)
        }
        defaults.set(data, forKey: CentoKey.snapshot)
        try data.write(to: fileURL, options: .atomic)
        try writeCache(root)
    }

    func wipe() throws {
        let defaults = box()
        defaults.removeObject(forKey: CentoKey.snapshot)
        defaults.removeObject(forKey: CentoKey.backup)
        defaults.removeObject(forKey: CentoKey.demo)
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try FileManager.default.removeItem(at: fileURL)
        }
        if FileManager.default.fileExists(atPath: backupURL.path) {
            try FileManager.default.removeItem(at: backupURL)
        }
        if FileManager.default.fileExists(atPath: cacheURL.path) {
            try FileManager.default.removeItem(at: cacheURL)
        }
    }

    func demoPlanted() -> Bool {
        box().object(forKey: CentoKey.demo) != nil
    }

    func markDemoPlanted() {
        box().set(true, forKey: CentoKey.demo)
    }

    private func writeCache(_ root: StoreRoot) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(root.latches)
        try data.write(to: cacheURL, options: .atomic)
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        var url = cacheURL
        try? url.setResourceValues(values)
    }

    private func decode(_ data: Data?) -> StoreRoot? {
        guard let data else { return nil }
        return try? StoreCodec.decode(data)
    }

    private func read(_ url: URL) -> Data? {
        try? Data(contentsOf: url)
    }

    var fileURL: URL {
        directory.appendingPathComponent("cento.json", isDirectory: false)
    }

    var backupURL: URL {
        directory.appendingPathComponent("cento.json.backup", isDirectory: false)
    }

    var cacheURL: URL {
        directory.appendingPathComponent("isbn-cache.json", isDirectory: false)
    }

    private func box() -> UserDefaults {
        if let suiteName {
            return UserDefaults(suiteName: suiteName) ?? UserDefaults()
        }
        return .standard
    }
}
