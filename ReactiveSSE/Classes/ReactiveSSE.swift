import ReactiveSwift

private let defaultMaxBuffer = 10_000_000

public enum SSError: Error {
    case notSSE(statusCode: Int, mimeType: String?)
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
            if #available(iOS 11.0, *) {
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
    let pipe = Signal<Data, SSError>.pipe()

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
        // non-main queue cause weird deep stack and crash on parse
        DispatchQueue.main.async {
            self.pipe.input.send(value: data)
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        pipe.input.send(error: .session(error as NSError?))
    }
}

extension Signal where Value == Data {
    public func serverSentEvents(maxBuffer: Int? = nil) -> Signal<SSEvent, Error> {
        let maxBuffer = maxBuffer ?? defaultMaxBuffer
        var buffer = Data()
        return .init { observer, lifetime in
            lifetime += self.observe { event in
                switch event {
                case .value(let d):
                    guard buffer.count + d.count <= maxBuffer else {
                        NSLog("%@", "\(#function): buffer size is about to be maxBuffer. automatically resetting buffers.")
                        buffer.removeAll()
                        return
                    }
                    buffer.append(d)

                    // try parsing or wait for next data (incomplete buffer)
                    guard let s = String(data: buffer, encoding: .utf8),
                        let parsed = try? EventStream.event.parse(AnyCollection(s)) else { return }

                    observer.send(value: SSEvent(parsed.output))

                    buffer.removeAll(keepingCapacity: true)
                    guard let remaining = String(parsed.remainder).data(using: .utf8) else {
                        NSLog("%@", "\(#function): cannot restore parse remainders to the buffer. remainders ignored.")
                        return
                    }
                    buffer.append(remaining)
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
