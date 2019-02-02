import Foundation
import ReactiveSwift

public struct ReactiveSSE {
    public let producer: SignalProducer<SSEvent, SSError>
    private let underlyingQueue: DispatchQueue

    public init(urlRequest req: URLRequest, maxBuffer: Int? = nil) {
        self.underlyingQueue = DispatchQueue(label: "ReactiveSSE", qos: .utility)
        self.producer = .init { [unowned underlyingQueue] observer, lifetime in
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
            queue.underlyingQueue = underlyingQueue

            // use session delegate to process data stream
            let delegate = SessionDataPipe()
            lifetime += delegate.pipe.output
                .serverSentEvents()
                .observe(observer.send)

            let session = URLSession(configuration: URLSessionConfiguration.default, delegate: delegate, delegateQueue: queue)

            let task = session.dataTask(with: req)
            lifetime.observeEnded(session.invalidateAndCancel)
            task.resume()
        }
    }
}




