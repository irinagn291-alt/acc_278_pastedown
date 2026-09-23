import XCTest
@testable import Pastedown

private actor ScriptedCarrier: VolumeCarrying {
    private var results: [Result<(Data, URLResponse), Error>]
    private var requests: [URLRequest] = []

    init(results: [Result<(Data, URLResponse), Error>]) {
        self.results = results
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        requests.append(request)
        guard !results.isEmpty else { throw URLError(.cannotConnectToHost) }
        return try results.removeFirst().get()
    }

    func recordedRequests() -> [URLRequest] {
        requests
    }
}

final class VolumeLookupTests: XCTestCase {
    private let isbn = ISBN.parse("9780306406157")!

    func test_setsUserAgentOnEveryRequest() async throws {
        let body = Data("""
        {"ISBN:9780306406157":{"title":"Paper Hours","authors":[{"name":"North Binding"}],"publishers":[{"name":"Harbor"}],"number_of_pages":216}}
        """.utf8)
        let carrier = ScriptedCarrier(results: [.success((body, http(200)))])
        let client = VolumeLookup(carrier: carrier)
        let latch = try await client.lookup(isbn: isbn)
        XCTAssertEqual(latch.title, "Paper Hours")
        XCTAssertEqual(latch.maker, "North Binding, Harbor")
        XCTAssertEqual(latch.pageCount, 216)
        let request = await carrier.recordedRequests().first
        XCTAssertEqual(request?.value(forHTTPHeaderField: "User-Agent"), VolumeLookup.userAgent)
        XCTAssertEqual(request?.timeoutInterval, 15)
        XCTAssertEqual(VolumeLookup.userAgent, "Pastedown/1.0 (iOS; +https://pastedown-cento.pro)")
        XCTAssertEqual(VolumeLookup.contactURL.absoluteString, "https://pastedown-cento.pro/contact-us")
    }

    func test_acceptsNumericStringPages() async throws {
        let body = Data("""
        {"ISBN:9780306406157":{"title":"Paper Hours","number_of_pages":"96"}}
        """.utf8)
        let carrier = ScriptedCarrier(results: [.success((body, http(200)))])
        let client = VolumeLookup(carrier: carrier)
        let latch = try await client.lookup(isbn: isbn)
        XCTAssertEqual(latch.pageCount, 96)
    }

    func test_retriesTransientTransportOnce() async throws {
        let body = Data("""
        {"ISBN:9780306406157":{"title":"Paper Hours","number_of_pages":4}}
        """.utf8)
        let carrier = ScriptedCarrier(results: [
            .failure(URLError(.timedOut)),
            .success((body, http(200))),
        ])
        let client = VolumeLookup(carrier: carrier)
        let latch = try await client.lookup(isbn: isbn)
        XCTAssertEqual(latch.title, "Paper Hours")
        let count = await carrier.recordedRequests().count
        XCTAssertEqual(count, 2)
    }

    func test_doesNotRetry404() async {
        let carrier = ScriptedCarrier(results: [
            .success((Data(), http(404))),
            .success((Data("{\"ISBN:9780306406157\":{\"title\":\"No\"}}".utf8), http(200))),
        ])
        let client = VolumeLookup(carrier: carrier)
        do {
            _ = try await client.lookup(isbn: isbn)
            XCTFail("expected notFound")
        } catch {
            XCTAssertEqual(error as? CentoFault, .notFound)
        }
        let count = await carrier.recordedRequests().count
        XCTAssertEqual(count, 1)
    }

    func test_emptyBooksObjectFallsThroughToISBNEndpoint() async throws {
        let leaf = Data("""
        {"title":"Leaf Title","publishers":["Deckled House"],"number_of_pages":128}
        """.utf8)
        let carrier = ScriptedCarrier(results: [
            .success((Data("{}".utf8), http(200))),
            .success((leaf, http(200))),
        ])
        let client = VolumeLookup(carrier: carrier)
        let latch = try await client.lookup(isbn: isbn)
        XCTAssertEqual(latch.title, "Leaf Title")
        XCTAssertEqual(latch.maker, "Deckled House")
        let count = await carrier.recordedRequests().count
        XCTAssertEqual(count, 2)
        let urls = await carrier.recordedRequests().compactMap(\.url)
        XCTAssertTrue(urls[0].path.contains("/api/books"))
        XCTAssertTrue(urls[1].path.contains("/isbn/"))
    }

    func test_malformedJSONIsDecodingError() async {
        let carrier = ScriptedCarrier(results: [
            .success((Data("{".utf8), http(200))),
        ])
        let client = VolumeLookup(carrier: carrier)
        do {
            _ = try await client.lookup(isbn: isbn)
            XCTFail("expected decoding")
        } catch {
            XCTAssertEqual(error as? CentoFault, .decoding)
        }
    }

    func test_usesMemoryCacheOnSecondLookup() async throws {
        let body = Data("""
        {"ISBN:9780306406157":{"title":"Paper Hours"}}
        """.utf8)
        let carrier = ScriptedCarrier(results: [.success((body, http(200)))])
        let client = VolumeLookup(carrier: carrier)
        _ = try await client.lookup(isbn: isbn)
        _ = try await client.lookup(isbn: isbn)
        let count = await carrier.recordedRequests().count
        XCTAssertEqual(count, 1)
    }

    private func http(_ code: Int) -> HTTPURLResponse {
        HTTPURLResponse(
            url: URL(string: "https://openlibrary.org/api/books")!,
            statusCode: code,
            httpVersion: nil,
            headerFields: nil
        )!
    }
}
