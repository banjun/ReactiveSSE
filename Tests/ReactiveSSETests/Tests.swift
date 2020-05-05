import XCTest
import ReactiveSSE
import ReactiveSwift

class ReactiveSSESpec: XCTestCase {
    func testParseSSEDataStreamBody_LF() {
        let pipe = Signal<String, Never>.pipe()
        let payload = "event: update\ndata: {}\n\n"

        var result: Result<SSEvent, Never>?
        pipe.output.serverSentEvents().observeResult {result = $0}
        pipe.input.send(value: payload)
        XCTAssertEqual(try? result?.get().type, "update")
        XCTAssertEqual(try? result?.get().data, "{}")
    }
    func testParseSSEDataStreamBody_CR() {
        let pipe = Signal<String, Never>.pipe()
        let payload = "event: update\rdata: {}\r\r"

        var result: Result<SSEvent, Never>?
        pipe.output.serverSentEvents().observeResult {result = $0}
        pipe.input.send(value: payload)
        XCTAssertEqual(try? result?.get().type, "update")
        XCTAssertEqual(try? result?.get().data, "{}")
    }
    func testParseSSEDataStreamBody_CRLF() {
        let pipe = Signal<String, Never>.pipe()
        let payload = "event: update\r\ndata: {}\r\n\r\n"

        var result: Result<SSEvent, Never>?
        pipe.output.serverSentEvents().observeResult {result = $0}
        pipe.input.send(value: payload)
        XCTAssertEqual(try? result?.get().type, "update")
        XCTAssertEqual(try? result?.get().data, "{}")
    }
    func testParseSSEDataStreamBody_SeparatedBuffers() {
        let pipe = Signal<String, Never>.pipe()
        let payload1 = "event: update\n"
        let payload2 = "data: {}\n"
        let payload3 = "\n"

        var result: Result<SSEvent, Never>?
        pipe.output.serverSentEvents().observeResult {result = $0}
        pipe.input.send(value: payload1)
        pipe.input.send(value: payload2)
        pipe.input.send(value: payload3)
        XCTAssertEqual(try? result?.get().type, "update")
        XCTAssertEqual(try? result?.get().data, "{}")
    }
    func testParseSSEDataStreamBody_SeparatedComments() {
        let pipe = Signal<String, Never>.pipe()
        let payload = ":comment\nevent: update\n:comment2\ndata: {}\n:comment3\n\n\n"

        var result: Result<SSEvent, Never>?
        pipe.output.serverSentEvents().observeResult {result = $0}
        pipe.input.send(value: payload)
        XCTAssertEqual(try? result?.get().type, "update")
        XCTAssertEqual(try? result?.get().data, "{}")
    }
    func testParseSSEDataStreamBody_MultipleEvents() {
        let pipe = Signal<String, Never>.pipe()
        let payload1 = "event: update1\ndata: {1}\n\n"
        let payload2 = "event: update2\ndata: {2}\n\n"

        var results: [Result<SSEvent, Never>] = []
        pipe.output.serverSentEvents().observeResult {results.append($0)}
        pipe.input.send(value: payload1)
        pipe.input.send(value: payload2)
        XCTAssertEqual(results.count, 2)
        XCTAssertEqual(try? results.first?.get().type, "update1")
        XCTAssertEqual(try? results.first?.get().data, "{1}")
        XCTAssertEqual(try? results.last?.get().type, "update2")
        XCTAssertEqual(try? results.last?.get().data, "{2}")
    }
}
