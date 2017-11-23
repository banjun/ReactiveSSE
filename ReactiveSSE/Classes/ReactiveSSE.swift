import ReactiveSwift

extension Signal where Value == Data {
    public func serverSentEvents(maxBuffer: Int = 10_000_000) -> Signal<SSEvent, Error> {
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
