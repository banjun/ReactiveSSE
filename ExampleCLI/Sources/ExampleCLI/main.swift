import Foundation
import ReactiveSSE
import ReactiveSwift

guard CommandLine.arguments.count > 2,
    let url = URL(string: CommandLine.arguments[1]) else {
        print("usage: \(CommandLine.arguments.first ?? "ExampleCLI") stream_url access_token")
        exit(1)
}

let token = CommandLine.arguments[2]
var req = URLRequest(url: url)
req.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

let sse = ReactiveSSE(urlRequest: req)
sse.producer
    .on(started: {print("connecting to \(url)...")})
    .on(value: { v in
        print(v)
    })
    .on(failed: {print($0)})
    .retry(upTo: 2, interval: 2, on: QueueScheduler.main)
    .on(terminated: {exit(0)})
    .start()

dispatchMain()
