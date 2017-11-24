import UIKit
import ReactiveSSE
import ReactiveSwift

// change here for test example
private let endpoint = "https://mstdn.jp/api/v1/streaming/public/local"
private let access_token = "12345678"

class ViewController: UITableViewController {
    let sse = ReactiveSSE(urlRequest: {
        var req = URLRequest(url: URL(string: endpoint)!)
        req.addValue("Bearer \(access_token)", forHTTPHeaderField: "Authorization")
        return req
    }())

    var results: [SSEvent] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        sse.producer.observe(on: QueueScheduler.main).startWithResult { [weak self] r in
//            NSLog("%@", "result: \(r)")
            switch r {
            case .success(let v): self?.append(v)
            case .failure(let e): NSLog("%@", "observe error: \(String(describing: e))")
            }
        }
    }

    func append(_ v: SSEvent) {
        results.insert(v, at: 0)
        tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") ?? UITableViewCell(style: .subtitle, reuseIdentifier: "Cell")
        let v = results[indexPath.row]
        cell.textLabel?.text = v.type
        cell.detailTextLabel?.text = v.data
        cell.detailTextLabel?.numberOfLines = 0
        return cell
    }
}
