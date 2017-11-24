import ReactiveSwift

private let defaultMaxBuffer = 10_000_000

public enum SSError: Error {
    case notSSE(statusCode: Int, mimeType: String?)
    case nonUTF8(Data)
    case session(NSError?)
}

public struct ReactiveSSE {
    public let producer: SignalProducer<SSEvent, SSError>

    public init(urlRequest req: URLRequest, maxBuffer: Int? = nil) {
        producer = .init { observer, lifetime in
            var req = req
            req.cachePolicy = .reloadIgnoringCacheData
            req.timeoutInterval = 365 * 24 * 60 * 60

            let configuration = URLSessionConfiguration.default
            configuration.timeoutIntervalForRequest = 60
            configuration.timeoutIntervalForResource = 60 * 60
            if #available(iOS 11.0, OSX 10.13, *) {
                configuration.waitsForConnectivity = true
            }

            let queue = OperationQueue()
            queue.underlyingQueue = DispatchQueue(label: "ReactiveSSE", qos: .utility)

            // use session delegate to process data stream
            let delegate = SessionDataPipe()
            lifetime += delegate.pipe.output
                .serverSentEvents()
                .observe(observer.send)

            let session = URLSession(configuration: URLSessionConfiguration.default, delegate: delegate, delegateQueue: queue)

            let task = session.dataTask(with: req)
            lifetime.observeEnded(task.cancel)
            task.resume()
        }
    }
}

final class SessionDataPipe: NSObject, URLSessionDataDelegate {
    let pipe = Signal<String, SSError>.pipe()

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        guard let response = response as? HTTPURLResponse else { return completionHandler(.cancel) }
        guard response.statusCode == 200,
            response.mimeType == "text/event-stream" else {
                pipe.input.send(error: .notSSE(statusCode: response.statusCode, mimeType: response.mimeType))
                return completionHandler(.cancel)
        }
        completionHandler(.allow)
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard let s = String(data: data, encoding: .utf8) else {
            pipe.input.send(error: .nonUTF8(data))
            return
        }
        pipe.input.send(value: s)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        pipe.input.send(error: .session(error as NSError?))
    }
}

extension Signal where Value == String {
    public func serverSentEvents(maxBuffer: Int? = nil) -> Signal<SSEvent, Error> {
        let maxBuffer = maxBuffer ?? defaultMaxBuffer
        var buffer: String = ""
        return .init { observer, lifetime in
            lifetime += self.observe { event in
                switch event {
                case .value(let s):
                    guard buffer.count + s.count <= maxBuffer else {
                        NSLog("%@", "\(#function): buffer size is about to be maxBuffer. automatically resetting buffers.")
                        buffer.removeAll()
                        return
                    }
                    buffer += s

                    // try parsing or wait for next data (incomplete buffer)
                    guard let parsed = try? EventStream.event.parse(AnyCollection(buffer)) else { return }

                    observer.send(value: SSEvent(parsed.output))

                    buffer = String(parsed.remainder)
                case .failed(let e):
                    observer.send(error: e)
                case .completed:
                    observer.send(.completed)
                case .interrupted:
                    observer.send(.interrupted)
                }
            }
        }
    }
}
