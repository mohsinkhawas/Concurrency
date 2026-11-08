import AppKit
import Foundation

actor TransferRecord {
    private(set) var byteCount = 0

    func note(_ data: Data) {
        byteCount = data.count
    }

    func reset() {
        byteCount = 0
    }
}

final class SwiftConcurrencyEngine: DownloadEngine {
    private var task: Task<Void, Never>?
    private let record = TransferRecord()

    func start(url: URL, sink: DownloadSink) {
        cancel()
        sink.status(.dispatched)
        sink.log("Task { } created — cooperative cancellation is enabled")

        task = Task { [record] in
            let startSnap = ThreadSnapshot.capture()
            sink.status(.downloading, thread: startSnap)
            sink.log("await URLSession.shared.data(from:)", thread: startSnap)

            do {
                try Task.checkCancellation()
                let (data, _) = try await URLSession.shared.data(from: url)
                try Task.checkCancellation()

                let processSnap = ThreadSnapshot.capture()
                sink.status(.processing, thread: processSnap)
                sink.log("Fetched \(data.count) bytes — actor records metrics", thread: processSnap)
                await record.note(data)
                let bytes = await record.byteCount
                sink.log("TransferRecord actor byteCount=\(bytes)", thread: .capture())

                try Task.checkCancellation()
                guard NSImage(data: data) != nil else {
                    sink.fail("NSImage failed to decode payload", thread: processSnap)
                    return
                }

                sink.log("@MainActor hop for SwiftUI state", thread: processSnap)
                await MainActor.run {
                    let mainSnap = ThreadSnapshot.capture()
                    sink.complete(data, thread: mainSnap)
                }
            } catch is CancellationError {
                let snap = ThreadSnapshot.capture()
                sink.log("Task.checkCancellation() / CancellationError", thread: snap)
                sink.cancelled(thread: snap)
            } catch {
                let snap = ThreadSnapshot.capture()
                if Task.isCancelled || (error as? URLError)?.code == .cancelled {
                    sink.cancelled(thread: snap)
                } else {
                    sink.fail(error.localizedDescription, thread: snap)
                }
            }
        }
    }

    func cancel() {
        task?.cancel()
        task = nil
        Task { await record.reset() }
    }
}
