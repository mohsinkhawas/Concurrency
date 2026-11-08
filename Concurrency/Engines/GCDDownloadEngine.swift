import AppKit
import Foundation

final class GCDDownloadEngine: DownloadEngine {
    private var workItem: DispatchWorkItem?
    private let token = CancelToken()

    func start(url: URL, sink: DownloadSink) {
        cancel()
        token.reset()
        sink.status(.dispatched)
        sink.log("DispatchQueue.global(qos: .userInitiated).async")

        let token = token
        let item = DispatchWorkItem {
            let snap = ThreadSnapshot.capture()
            sink.status(.downloading, thread: snap)
            sink.log("GCD worker picked up the item", thread: snap)

            let task = URLSession.shared.dataTask(with: url) { data, _, error in
                let sessionSnap = ThreadSnapshot.capture()
                if token.isCancelled || (error as? URLError)?.code == .cancelled {
                    sink.log("Work item or URLSession task cancelled", thread: sessionSnap)
                    sink.cancelled(thread: sessionSnap)
                    return
                }
                if let error {
                    sink.fail(error.localizedDescription, thread: sessionSnap)
                    return
                }
                guard let data else {
                    sink.fail("Empty response", thread: sessionSnap)
                    return
                }

                DispatchQueue.global(qos: .userInitiated).async {
                    if token.isCancelled {
                        sink.cancelled(thread: .capture())
                        return
                    }
                    let processSnap = ThreadSnapshot.capture()
                    sink.status(.processing, thread: processSnap)
                    sink.log("Fetched \(data.count) bytes — decoding on a global queue", thread: processSnap)
                    guard NSImage(data: data) != nil else {
                        sink.fail("NSImage failed to decode payload", thread: processSnap)
                        return
                    }
                    sink.log("DispatchQueue.main.async — rendering UI", thread: processSnap)
                    DispatchQueue.main.async {
                        if token.isCancelled {
                            sink.cancelled(thread: .capture())
                            return
                        }
                        let mainSnap = ThreadSnapshot.capture()
                        sink.complete(data, thread: mainSnap)
                    }
                }
            }
            token.attach(task)
            task.resume()
        }

        workItem = item
        DispatchQueue.global(qos: .userInitiated).async(execute: item)
    }

    func cancel() {
        workItem?.cancel()
        token.cancel()
        workItem = nil
    }
}
