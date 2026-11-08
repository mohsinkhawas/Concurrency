import AppKit
import Foundation

final class ThreadDownloadEngine: DownloadEngine {
    private var worker: ImageWorkerThread?

    func start(url: URL, sink: DownloadSink) {
        cancel()
        let worker = ImageWorkerThread(url: url, sink: sink)
        self.worker = worker
        sink.status(.dispatched)
        sink.log("Allocated ImageWorkerThread (NSThread subclass), QoS userInitiated")
        worker.start()
    }

    func cancel() {
        worker?.cancel()
        worker = nil
    }
}

nonisolated final class ImageWorkerThread: Thread, @unchecked Sendable {
    private let url: URL
    private let sink: DownloadSink
    private let session: URLSession
    private let token = CancelToken()

    init(url: URL, sink: DownloadSink) {
        self.url = url
        self.sink = sink
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: configuration)
        super.init()
        name = "ImageWorkerThread"
        qualityOfService = .userInitiated
    }

    override func main() {
        let origin = ThreadSnapshot.capture()
        sink.status(.downloading, thread: origin)
        sink.log("Thread.main() running — fetching \(url.lastPathComponent)", thread: origin)

        if token.isCancelled || isCancelled {
            sink.cancelled(thread: origin)
            return
        }

        let semaphore = DispatchSemaphore(value: 0)
        var payload: Data?
        var failure: Error?

        let task = session.dataTask(with: url) { data, _, error in
            payload = data
            failure = error
            semaphore.signal()
        }
        token.attach(task)
        task.resume()
        semaphore.wait()

        let afterFetch = ThreadSnapshot.capture()

        if token.isCancelled || isCancelled || (failure as? URLError)?.code == .cancelled {
            sink.log("Thread observed cancellation after URLSession wait", thread: afterFetch)
            sink.cancelled(thread: afterFetch)
            return
        }

        if let failure {
            sink.fail(failure.localizedDescription, thread: afterFetch)
            return
        }

        guard let payload else {
            sink.fail("Empty response", thread: afterFetch)
            return
        }

        sink.status(.processing, thread: afterFetch)
        sink.log("Fetched \(payload.count) bytes — decoding off the main thread", thread: afterFetch)

        guard NSImage(data: payload) != nil else {
            sink.fail("NSImage failed to decode payload", thread: afterFetch)
            return
        }

        if token.isCancelled || isCancelled {
            sink.cancelled(thread: afterFetch)
            return
        }

        sink.log("performSelector(onMainThread:) — hopping to AppKit", thread: afterFetch)
        performSelector(onMainThread: #selector(publishOnMain(_:)), with: payload as NSData, waitUntilDone: false)
    }

    override func cancel() {
        super.cancel()
        token.cancel()
        let snap = ThreadSnapshot.capture()
        sink.log("Thread.cancel() + URLSessionTask.cancel()", thread: snap)
    }

    @objc private func publishOnMain(_ data: NSData) {
        let snap = ThreadSnapshot.capture()
        sink.log("Main-thread selector fired — publishing image bytes", thread: snap)
        sink.complete(data as Data, thread: snap)
    }
}
