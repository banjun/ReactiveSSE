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
                expect(result?.value?.type) == "update"
                expect(result?.value?.data) == "{}"
            }
            it("cr") {
                let pipe = Signal<String, Never>.pipe()
                let payload = "event: update\rdata: {}\r\r"

                var result: Result<SSEvent, Never>?
                pipe.output.serverSentEvents().observeResult {result = $0}
                pipe.input.send(value: payload)
                expect(result?.value?.type) == "update"
                expect(result?.value?.data) == "{}"
            }
            it("crlf") {
                let pipe = Signal<String, Never>.pipe()
                let payload = "event: update\r\ndata: {}\r\n\r\n"

                var result: Result<SSEvent, Never>?
                pipe.output.serverSentEvents().observeResult {result = $0}
                pipe.input.send(value: payload)
                expect(result?.value?.type) == "update"
                expect(result?.value?.data) == "{}"
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
                expect(result?.value?.type) == "update"
                expect(result?.value?.data) == "{}"
            }
            it("comments") {
                let pipe = Signal<String, Never>.pipe()
                let payload = ":comment\nevent: update\n:comment2\ndata: {}\n:comment3\n\n\n"

                var result: Result<SSEvent, Never>?
                pipe.output.serverSentEvents().observeResult {result = $0}
                pipe.input.send(value: payload)
                expect(result?.value?.type) == "update"
                expect(result?.value?.data) == "{}"
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
                expect(results.first?.value?.type) == "update1"
                expect(results.first?.value?.data) == "{1}"
                expect(results.last?.value?.type) == "update2"
                expect(results.last?.value?.data) == "{2}"
            }
        }
    }
}
