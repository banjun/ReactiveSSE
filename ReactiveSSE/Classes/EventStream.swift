import FootlessParser

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
    static let comment: Parser<Character, Comment> = char(":") *> zeroOrMore(anyChar) <* eol
    static let field: Parser<Character, Field> = curry(Field.init) <^> oneOrMore(nameChar) <* char(":") <* optional(space) <*> zeroOrMore(anyChar) <* eol
}
