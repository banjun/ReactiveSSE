import ReactiveSwift
import FootlessParser

public struct SSEvent {
    public var type: String
    public var data: String // Event streams in this format must always be encoded as UTF-8

    init() {
        type = "message" // default
        data = "" // default
    }

    init(_ eses: [EventStream.Event]) {
        self = eses.flatMap { e -> EventStream.Field? in
            switch e {
            case .comment: return nil // ignored
            case .field(let f): return f
            }}
            .reduce(into: SSEvent()) { sse, f in
                switch f.name {
                case "event": sse.type = f.value
                case "data": sse.data = f.value
                case "id": break // TODO
                case "retry": break // TODO
                default: break // ignored
                }
        }
    }
}

// https://html.spec.whatwg.org/multipage/server-sent-events.html
struct EventStream {
    enum Event {
        case comment(Comment)
        case field(Field)
    }

    typealias Comment = String

    struct Field {
        var name: String
        var value: String // Event streams in this format must always be encoded as UTF-8
    }

    static let nameChar: Parser<Character, Character> = noneOf(["\r\n", "\r", "\n", ":"])
    static let anyChar: Parser<Character, Character> = noneOf(["\r\n", "\r", "\n"])
    static let space: Parser<Character, Character> = char(" ")
    static let eol: Parser<Character, Character> = oneOf(["\r\n", "\r", "\n"])
    static let event: Parser<Character, [Event]> = zeroOrMore((Event.comment <^> comment) <|> (Event.field <^> field)) <* eol
    static let comment: Parser<Character, Comment> = string(":") *> zeroOrMore(anyChar) <* eol
    static let field: Parser<Character, Field> = curry(Field.init) <^>
        oneOrMore(nameChar) <* char(":") <* optional(space) <*> zeroOrMore(anyChar) <* eol
}

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
