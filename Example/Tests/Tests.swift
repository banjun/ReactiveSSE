import Quick
import Nimble
import ReactiveSSE
import ReactiveSwift

class ReactiveSSESpec: QuickSpec {
    override func spec() {
        describe("parse SSE data stream body") {
            it("lf") {
                let pipe = Signal<String, Never>.pipe()
                let payload = "event: update\ndata: {}\n\n"

                var result: Result<SSEvent, Never>?
                pipe.output.serverSentEvents().observeResult {result = $0}
                pipe.input.send(value: payload)
                expect(try? result?.get().type) == "update"
                expect(try? result?.get().data) == "{}"
            }
            it("cr") {
                let pipe = Signal<String, Never>.pipe()
                let payload = "event: update\rdata: {}\r\r"

                var result: Result<SSEvent, Never>?
                pipe.output.serverSentEvents().observeResult {result = $0}
                pipe.input.send(value: payload)
                expect(try? result?.get().type) == "update"
                expect(try? result?.get().data) == "{}"
            }
            it("crlf") {
                let pipe = Signal<String, Never>.pipe()
                let payload = "event: update\r\ndata: {}\r\n\r\n"

                var result: Result<SSEvent, Never>?
                pipe.output.serverSentEvents().observeResult {result = $0}
                pipe.input.send(value: payload)
                expect(try? result?.get().type) == "update"
                expect(try? result?.get().data) == "{}"
            }
            it("separated buffers") {
                let pipe = Signal<String, Never>.pipe()
                let payload1 = "event: update\n"
                let payload2 = "data: {}\n"
                let payload3 = "\n"

                var result: Result<SSEvent, Never>?
                pipe.output.serverSentEvents().observeResult {result = $0}
                pipe.input.send(value: payload1)
                pipe.input.send(value: payload2)
                pipe.input.send(value: payload3)
                expect(try? result?.get().type) == "update"
                expect(try? result?.get().data) == "{}"
            }
            it("comments") {
                let pipe = Signal<String, Never>.pipe()
                let payload = ":comment\nevent: update\n:comment2\ndata: {}\n:comment3\n\n\n"

                var result: Result<SSEvent, Never>?
                pipe.output.serverSentEvents().observeResult {result = $0}
                pipe.input.send(value: payload)
                expect(try? result?.get().type) == "update"
                expect(try? result?.get().data) == "{}"
            }
            it("multiple events") {
                let pipe = Signal<String, Never>.pipe()
                let payload1 = "event: update1\ndata: {1}\n\n"
                let payload2 = "event: update2\ndata: {2}\n\n"

                var results: [Result<SSEvent, Never>] = []
                pipe.output.serverSentEvents().observeResult {results.append($0)}
                pipe.input.send(value: payload1)
                pipe.input.send(value: payload2)
                expect(results.count) == 2
                expect(try? results.first?.get().type) == "update1"
                expect(try? results.first?.get().data) == "{1}"
                expect(try? results.last?.get().type) == "update2"
                expect(try? results.last?.get().data) == "{2}"
            }
        }
    }
}
