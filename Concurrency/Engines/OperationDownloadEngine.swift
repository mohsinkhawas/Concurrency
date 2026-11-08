import AppKit
import Foundation

final class OperationDownloadEngine: DownloadEngine {
    private let queue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "ImagePipeline"
        queue.qualityOfService = .userInitiated
        queue.maxConcurrentOperationCount = 2
        return queue
    }()

    func start(url: URL, sink: DownloadSink) {
        cancel()
        sink.status(.dispatched)
        sink.log("OperationQueue '\(queue.name ?? "")' — fetch ≺ decode dependency")

        let fetch = FetchOperation(url: url, sink: sink)
        let decode = DecodeOperation(fetch: fetch, sink: sink)
        decode.addDependency(fetch)
        queue.addOperations([fetch, decode], waitUntilFinished: false)
    }

    func cancel() {
        queue.cancelAllOperations()
    }
}

nonisolated fileprivate class PipelineOperation: Operation, @unchecked Sendable {
    private let stateLock = NSLock()
    private var _executing = false
    private var _finished = false

    override var isAsynchronous: Bool { false }

    override var isExecuting: Bool {
        stateLock.lock()
        defer { stateLock.unlock() }
        return _executing
    }

    override var isFinished: Bool {
        stateLock.lock()
        defer { stateLock.unlock() }
        return _finished
    }

    func markStarted() {
        willChangeValue(forKey: "isExecuting")
        stateLock.lock()
        _executing = true
        stateLock.unlock()
        didChangeValue(forKey: "isExecuting")
    }

    func markFinished() {
        willChangeValue(forKey: "isExecuting")
        willChangeValue(forKey: "isFinished")
        stateLock.lock()
        _executing = false
        _finished = true
        stateLock.unlock()
        didChangeValue(forKey: "isExecuting")
        didChangeValue(forKey: "isFinished")
    }
}

nonisolated fileprivate final class FetchOperation: PipelineOperation, @unchecked Sendable {
    let url: URL
    private(set) var data: Data?
    private let sink: DownloadSink
    private let token = CancelToken()

    init(url: URL, sink: DownloadSink) {
        self.url = url
        self.sink = sink
        super.init()
        name = "FetchOperation"
        qualityOfService = .userInitiated
    }

    override func main() {
        markStarted()
        defer { markFinished() }

        let snap = ThreadSnapshot.capture()
        sink.status(.downloading, thread: snap)
        sink.log("FetchOperation.main() isExecuting=\(isExecuting)", thread: snap)

        if isCancelled {
            sink.cancelled(thread: snap)
            return
        }

        let semaphore = DispatchSemaphore(value: 0)
        var payload: Data?
        var failure: Error?

        let task = URLSession.shared.dataTask(with: url) { data, _, error in
            payload = data
            failure = error
            semaphore.signal()
        }
        token.attach(task)
        task.resume()
        semaphore.wait()

        let after = ThreadSnapshot.capture()
        if isCancelled || (failure as? URLError)?.code == .cancelled {
            sink.log("FetchOperation cancelled (isFinished will become true)", thread: after)
            sink.cancelled(thread: after)
            return
        }
        if let failure {
            sink.fail(failure.localizedDescription, thread: after)
            return
        }
        guard let payload else {
            sink.fail("Empty response", thread: after)
            return
        }
        data = payload
        sink.log("FetchOperation finished — \(payload.count) bytes ready for decode", thread: after)
    }

    override func cancel() {
        super.cancel()
        token.cancel()
    }
}

nonisolated fileprivate final class DecodeOperation: PipelineOperation, @unchecked Sendable {
    let fetch: FetchOperation
    private let sink: DownloadSink

    init(fetch: FetchOperation, sink: DownloadSink) {
        self.fetch = fetch
        self.sink = sink
        super.init()
        name = "DecodeOperation"
        qualityOfService = .userInitiated
    }

    override func main() {
        markStarted()
        defer { markFinished() }

        let snap = ThreadSnapshot.capture()
        if isCancelled {
            sink.log("DecodeOperation skipped — cancelled before start", thread: snap)
            sink.cancelled(thread: snap)
            return
        }

        guard let data = fetch.data else {
            if fetch.isCancelled {
                sink.cancelled(thread: snap)
            }
            return
        }

        sink.status(.processing, thread: snap)
        sink.log("DecodeOperation running after dependency; isExecuting=\(isExecuting)", thread: snap)

        guard NSImage(data: data) != nil else {
            sink.fail("NSImage failed to decode payload", thread: snap)
            return
        }

        sink.log("DispatchQueue.main.async from DecodeOperation", thread: snap)
        DispatchQueue.main.async {
            let mainSnap = ThreadSnapshot.capture()
            self.sink.complete(data, thread: mainSnap)
        }
    }
}
