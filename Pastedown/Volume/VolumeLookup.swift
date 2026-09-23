import Foundation

/// Role: Volume. Injected hop so tests never leave the process.
protocol VolumeCarrying: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

/// Role: Volume. URLSession hop, 15 s timeout, app User-Agent on every request.
struct VolumeSessionCarrier: VolumeCarrying {
    let session: URLSession

    init(session: URLSession) {
        self.session = session
    }

    init() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 15
        configuration.timeoutIntervalForResource = 15
        configuration.httpAdditionalHeaders = ["User-Agent": VolumeLookup.userAgent]
        self.session = URLSession(configuration: configuration)
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await session.data(for: request)
    }
}

/// Role: Volume. One client owns both Open Library ISBN endpoints. DTO in, VolumeLatch out.
actor VolumeLookup {
    static let userAgent = "Pastedown/1.0 (iOS; +https://pastedown-cento.pro)"
    static let contactURL = URL(string: "https://pastedown-cento.pro/contact-us")!

    private let carrier: any VolumeCarrying
    private var memory: [String: VolumeLatch] = [:]
    private var inflight: Task<VolumeLatch, Error>?

    init(carrier: any VolumeCarrying) {
        self.carrier = carrier
    }

    init() {
        self.carrier = VolumeSessionCarrier()
    }

    func cached(_ isbn: ISBN) -> VolumeLatch? {
        memory[isbn.canonical]
    }

    func remember(_ latch: VolumeLatch) {
        memory[latch.isbn] = latch
    }

    func lookup(isbn: ISBN) async throws -> VolumeLatch {
        if let hit = memory[isbn.canonical] { return hit }
        inflight?.cancel()
        let task = Task { try await self.perform(isbn) }
        inflight = task
        do {
            let latch = try await task.value
            memory[isbn.canonical] = latch
            return latch
        } catch is CancellationError {
            throw CentoFault.cancelled
        }
    }

    /// Debounce typed ISBN input by 300 ms and cancel the previous hop.
    func lookupDebounced(raw: String) async throws -> VolumeLatch {
        try await Task.sleep(nanoseconds: 300_000_000)
        try Task.checkCancellation()
        guard let isbn = ISBN.parse(raw) ?? ISBN.extract(from: raw) else {
            throw CentoFault.notFound
        }
        return try await lookup(isbn: isbn)
    }

    private func perform(_ isbn: ISBN) async throws -> VolumeLatch {
        try Task.checkCancellation()
        let books = try await fetch(request(for: Self.booksURL(isbn: isbn)))
        if let latch = try Self.mapBooks(books, isbn: isbn) {
            return latch
        }
        let leaf = try await fetch(request(for: Self.isbnURL(isbn: isbn)))
        if let latch = try Self.mapISBN(leaf, isbn: isbn) {
            return latch
        }
        throw CentoFault.notFound
    }

    private func request(for url: URL) -> URLRequest {
        var request = URLRequest(url: url, timeoutInterval: 15)
        request.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")
        return request
    }

    private func fetch(_ request: URLRequest) async throws -> Data {
        do {
            return try await send(request)
        } catch let fault as CentoFault {
            throw fault
        } catch is CancellationError {
            throw CentoFault.cancelled
        } catch {
            if Self.cancelled(error) { throw CentoFault.cancelled }
            guard Self.transient(error) else { throw CentoFault.transport }
            do {
                return try await send(request)
            } catch let fault as CentoFault {
                throw fault
            } catch is CancellationError {
                throw CentoFault.cancelled
            } catch {
                if Self.cancelled(error) { throw CentoFault.cancelled }
                throw CentoFault.transport
            }
        }
    }

    private func send(_ request: URLRequest) async throws -> Data {
        try Task.checkCancellation()
        let (data, response) = try await carrier.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw CentoFault.transport
        }
        if http.statusCode == 404 {
            throw CentoFault.notFound
        }
        guard (200 ..< 300).contains(http.statusCode) else {
            throw CentoFault.transport
        }
        return data
    }

    private static func mapBooks(_ data: Data, isbn: ISBN) throws -> VolumeLatch? {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        let table: [String: OpenLibraryBookDTO]
        do {
            table = try decoder.decode([String: OpenLibraryBookDTO].self, from: data)
        } catch {
            throw CentoFault.decoding
        }
        guard let dto = table["ISBN:\(isbn.canonical)"] ?? table.values.first else {
            return nil
        }
        return dto.asLatch(isbn: isbn.canonical)
    }

    private static func mapISBN(_ data: Data, isbn: ISBN) throws -> VolumeLatch? {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        do {
            let dto = try decoder.decode(OpenLibraryISBNDTO.self, from: data)
            return dto.asLatch(isbn: isbn.canonical)
        } catch {
            throw CentoFault.decoding
        }
    }

    static func booksURL(isbn: ISBN) -> URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "openlibrary.org"
        components.path = "/api/books"
        components.queryItems = [
            URLQueryItem(name: "bibkeys", value: "ISBN:\(isbn.canonical)"),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "jscmd", value: "data"),
        ]
        // Programmer constant. Host and path are fixed in this type.
        return components.url!
    }

    static func isbnURL(isbn: ISBN) -> URL {
        // Programmer constant. Path uses checksummed digits only.
        URL(string: "https://openlibrary.org/isbn/\(isbn.canonical).json")!
    }

    private static func transient(_ error: Error) -> Bool {
        guard let urlError = error as? URLError else { return false }
        switch urlError.code {
        case .timedOut, .networkConnectionLost, .notConnectedToInternet,
             .cannotConnectToHost, .cannotFindHost, .dnsLookupFailed:
            return true
        default:
            return false
        }
    }

    private static func cancelled(_ error: Error) -> Bool {
        if error is CancellationError { return true }
        if let urlError = error as? URLError, urlError.code == .cancelled { return true }
        return false
    }
}

/// Role: Volume. Wire shape for /api/books. Keys stay as the service sent them.
struct OpenLibraryBookDTO: Decodable, Equatable {
    var title: String?
    var authors: [OpenLibraryNamedDTO]?
    var publishers: [OpenLibraryNamedDTO]?
    var number_of_pages: FlexibleNumber?

    func asLatch(isbn: String) -> VolumeLatch? {
        let title = title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !title.isEmpty else { return nil }
        let author = authors?.compactMap { $0.name?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty } ?? ""
        let press = publishers?.compactMap { $0.name?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty } ?? ""
        let maker = [author, press].filter { !$0.isEmpty }.joined(separator: ", ")
        return VolumeLatch(isbn: isbn, title: title, maker: maker, pageCount: number_of_pages?.intValue)
    }
}

/// Role: Volume. Wire shape for /isbn/{code}.json.
struct OpenLibraryISBNDTO: Decodable, Equatable {
    var title: String?
    var publishers: [String]?
    var number_of_pages: FlexibleNumber?
    var by_statement: String?

    func asLatch(isbn: String) -> VolumeLatch? {
        let title = title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !title.isEmpty else { return nil }
        let press = publishers?.first { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty } ?? ""
        let maker = [by_statement, press]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
        return VolumeLatch(isbn: isbn, title: title, maker: maker, pageCount: number_of_pages?.intValue)
    }
}

struct OpenLibraryNamedDTO: Decodable, Equatable {
    var name: String?
}

/// Role: Volume. Accepts a number or a numeric string. Incomplete catalog data is normal.
struct FlexibleNumber: Decodable, Equatable, Sendable {
    var intValue: Int?

    init(intValue: Int?) {
        self.intValue = intValue
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            intValue = nil
            return
        }
        if let value = try? container.decode(Int.self) {
            intValue = value
            return
        }
        if let value = try? container.decode(Double.self) {
            intValue = Int(value.rounded())
            return
        }
        if let raw = try? container.decode(String.self) {
            let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            intValue = Int(trimmed)
            return
        }
        intValue = nil
    }
}
