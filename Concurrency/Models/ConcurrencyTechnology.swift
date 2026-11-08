import SwiftUI

enum ConcurrencyTechnology: String, CaseIterable, Identifiable, Hashable {
    case thread
    case gcd
    case operationQueue
    case combine
    case swiftConcurrency

    var id: String { rawValue }

    var title: String {
        switch self {
        case .thread: return "Thread"
        case .gcd: return "Grand Central Dispatch"
        case .operationQueue: return "OperationQueue"
        case .combine: return "Combine"
        case .swiftConcurrency: return "Swift Concurrency"
        }
    }

    var shortTitle: String {
        switch self {
        case .thread: return "NSThread / POSIX"
        case .gcd: return "DispatchQueue"
        case .operationQueue: return "Operation"
        case .combine: return "Combine"
        case .swiftConcurrency: return "async/await"
        }
    }

    var subtitle: String {
        switch self {
        case .thread:
            return "Manual thread allocation and explicit UI hop-back."
        case .gcd:
            return "System-managed queues with QoS-based scheduling."
        case .operationQueue:
            return "Object-based units of work with cancellation and dependencies."
        case .combine:
            return "Reactive publishers, operators, and cancellable subscriptions."
        case .swiftConcurrency:
            return "Structured tasks, cooperative cancellation, and actors."
        }
    }

    var executionStyle: String {
        switch self {
        case .thread: return "Manual"
        case .gcd: return "Queue"
        case .operationQueue: return "Queue"
        case .combine: return "Reactive"
        case .swiftConcurrency: return "Structured"
        }
    }

    var symbolName: String {
        switch self {
        case .thread: return "gearshape.2"
        case .gcd: return "square.stack.3d.up"
        case .operationQueue: return "list.bullet.rectangle"
        case .combine: return "point.3.connected.trianglepath.dotted"
        case .swiftConcurrency: return "arrow.triangle.branch"
        }
    }

    var tint: Color {
        switch self {
        case .thread: return .orange
        case .gcd: return .blue
        case .operationQueue: return .purple
        case .combine: return .pink
        case .swiftConcurrency: return .teal
        }
    }

    var architecturalOverview: String {
        switch self {
        case .thread:
            return "NSThread (and POSIX pthreads underneath) is the lowest-level concurrency primitive on Apple platforms. You allocate a thread, set its name and QoS, start it, and you are responsible for its lifetime, cancellation flag, and every hop back to the main thread for UI work."
        case .gcd:
            return "Grand Central Dispatch exposes a pool of system threads through DispatchQueue. You submit closures to global or custom queues; the kernel decides which worker runs them. UI updates must be explicitly dispatched to DispatchQueue.main."
        case .operationQueue:
            return "OperationQueue sits on top of GCD and models work as Operation objects. Each operation tracks isExecuting / isFinished, can be cancelled, and can declare dependencies so a decode step never starts until a fetch step finishes."
        case .combine:
            return "Combine is a reactive pipeline. URLSession.dataTaskPublisher emits a (Data, URLResponse) value, operators transform it, receive(on:) hops threads, and AnyCancellable owns the subscription. Cancel the cancellable and the upstream data task is torn down."
        case .swiftConcurrency:
            return "Swift Concurrency uses structured Task trees, async/await, and actor isolation. URLSession.data(from:) is a first-class async API. Cancellation is cooperative via Task.checkCancellation(). @MainActor isolates UI state; a dedicated actor can protect download metrics."
        }
    }

    var memoryModel: String {
        switch self {
        case .thread:
            return "Each Thread owns a dedicated stack (typically ~512 KB). There is no automatic data isolation — shared objects need locks, serial queues, or confinement. Thread objects are reference types; the run loop is optional."
        case .gcd:
            return "Queues do not own stacks; they borrow worker threads from a process-wide pool. Closures capture strongly unless you use [weak self]. There is no compiler-enforced isolation between queues."
        case .operationQueue:
            return "Operations are reference-counted objects living on the heap. Dependencies form a DAG of retain relationships. Shared mutable state between operations must still be synchronized manually."
        case .combine:
            return "Publishers are value types; subscriptions are heap-allocated. Operators allocate downstream subscribers. Memory is released when the AnyCancellable is cancelled or deallocated."
        case .swiftConcurrency:
            return "Tasks are heap-allocated job records scheduled onto cooperative thread pools. Actors isolate mutable state behind a serial executor. Sendable checking (with default MainActor isolation in this target) is the memory-safety model."
        }
    }

    var safetyGuarantees: String {
        switch self {
        case .thread:
            return "None beyond what you write. Data races are undefined behavior. UIKit/AppKit are not thread-safe — UI must hop to the main thread via performSelector(onMainThread:) or DispatchQueue.main."
        case .gcd:
            return "FIFO per serial queue. Concurrent queues offer no mutual exclusion. The main queue is bound to the main thread, which is the only AppKit-safe context."
        case .operationQueue:
            return "maxConcurrentOperationCount = 1 gives serial behavior. Cancellation is cooperative (isCancelled). KVO on isFinished is the completion signal. Still no compile-time data-race checking."
        case .combine:
            return "receive(on:) is the thread-hop primitive. Operators do not make values Sendable. Subscriber callbacks run on the scheduler you selected. Cancellation is deterministic for the subscription graph."
        case .swiftConcurrency:
            return "The compiler enforces actor isolation. @MainActor protects UI. Task cancellation is cooperative but checked at await points. Actors prevent concurrent mutation of isolated state."
        }
    }

    var benefits: [String] {
        switch self {
        case .thread:
            return [
                "Full control over thread name, stack, and lifetime",
                "Maps 1:1 onto POSIX primitives for teaching",
                "No framework scheduler between you and the CPU"
            ]
        case .gcd:
            return [
                "Cheap to submit; excellent throughput",
                "QoS integration with App Nap and thermal state",
                "Industry-standard pattern for fire-and-forget work"
            ]
        case .operationQueue:
            return [
                "First-class cancellation and readiness",
                "Dependencies for pipelines (fetch → decode)",
                "Observable execution state (isExecuting / isFinished)"
            ]
        case .combine:
            return [
                "Declarative operator graphs",
                "Built-in URLSession publisher",
                "AnyCancellable makes teardown explicit"
            ]
        case .swiftConcurrency:
            return [
                "Readable linear async code",
                "Compiler-checked isolation",
                "Structured cancellation through the task tree"
            ]
        }
    }

    var drawbacks: [String] {
        switch self {
        case .thread:
            return [
                "Easy to over-create threads and exhaust stacks",
                "Cancellation is a homemade flag (no preemption)",
                "You must remember every main-thread hop"
            ]
        case .gcd:
            return [
                "Work items already running ignore cancel()",
                "No dependencies or completion objects",
                "Easy to deadlock with sync() on the current queue"
            ]
        case .operationQueue:
            return [
                "Concurrent Operation subclasses are error-prone (KVO)",
                "Heavier than a GCD closure",
                "Still cooperative cancellation"
            ]
        case .combine:
            return [
                "Debugging operator chains is harder than linear code",
                "Easy to leak subscriptions if cancellables are dropped",
                "Back-pressure and thread hops must be designed explicitly"
            ]
        case .swiftConcurrency:
            return [
                "Requires macOS 12+ APIs and Swift 5.5+",
                "Cancellation is cooperative — you must check it",
                "Actor reentrancy can surprise imperative mental models"
            ]
        }
    }

    var cancellationNotes: String {
        switch self {
        case .thread:
            return "Thread has no true interrupt. This demo sets a cancelled flag and calls URLSessionTask.cancel(). The worker checks the flag between steps."
        case .gcd:
            return "DispatchWorkItem.cancel() skips work that has not started. An in-flight URLSessionTask is cancelled separately."
        case .operationQueue:
            return "Operation.cancel() flips isCancelled and cancels the session task. Dependent decode operations are cancelled with the queue."
        case .combine:
            return "AnyCancellable.cancel() propagates cancellation to dataTaskPublisher, which cancels the underlying URLSession task."
        case .swiftConcurrency:
            return "Task.cancel() makes Task.isCancelled true and fails the next await with CancellationError. The actor never publishes a completed image."
        }
    }

    var codePreview: String {
        switch self {
        case .thread:
            return ThreadCodeSample.text
        case .gcd:
            return GCDCodeSample.text
        case .operationQueue:
            return OperationCodeSample.text
        case .combine:
            return CombineCodeSample.text
        case .swiftConcurrency:
            return SwiftConcurrencyCodeSample.text
        }
    }
}

private enum ThreadCodeSample {
    static let text = """
import AppKit

final class ImageWorkerThread: Thread {
    let url: URL
    private let session: URLSession
    private var task: URLSessionDataTask?

    init(url: URL) {
        self.url = url
        self.session = URLSession(configuration: .ephemeral)
        super.init()
        name = "ImageWorkerThread"
        qualityOfService = .userInitiated
    }

    override func main() {
        let semaphore = DispatchSemaphore(value: 0)
        var payload: Data?
        var failure: Error?

        let task = session.dataTask(with: url) { data, _, error in
            payload = data
            failure = error
            semaphore.signal()
        }
        self.task = task
        task.resume()
        semaphore.wait()

        guard !isCancelled, failure == nil, let payload else { return }
        performSelector(
            onMainThread: #selector(publish(_:)),
            with: payload,
            waitUntilDone: false
        )
    }

    override func cancel() {
        super.cancel()
        task?.cancel()
    }

    @objc private func publish(_ data: Data) {
        let image = NSImage(data: data)
        // Update SwiftUI / AppKit on the main thread.
        _ = image
    }
}

let worker = ImageWorkerThread(url: imageURL)
worker.start()
"""
}

private enum GCDCodeSample {
    static let text = """
import AppKit

let workItem = DispatchWorkItem {
    let task = URLSession.shared.dataTask(with: imageURL) { data, _, error in
        guard !workItem.isCancelled, error == nil, let data else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            guard NSImage(data: data) != nil else { return }
            DispatchQueue.main.async {
                // Render NSImage on the main queue.
            }
        }
    }
    task.resume()
}

DispatchQueue.global(qos: .userInitiated).async(execute: workItem)

// Cancellation: skips queued work and we also cancel the URLSessionTask.
workItem.cancel()
"""
}

private enum OperationCodeSample {
    static let text = """
import AppKit

final class FetchOperation: Operation, @unchecked Sendable {
    let url: URL
    private(set) var data: Data?
    private var task: URLSessionDataTask?

    override func main() {
        guard !isCancelled else { return }
        let semaphore = DispatchSemaphore(value: 0)
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            self?.data = data
            semaphore.signal()
        }
        self.task = task
        task.resume()
        semaphore.wait()
    }

    override func cancel() {
        super.cancel()
        task?.cancel()
    }
}

final class DecodeOperation: Operation, @unchecked Sendable {
    let fetch: FetchOperation
    private(set) var image: NSImage?

    override func main() {
        guard !isCancelled, let data = fetch.data else { return }
        image = NSImage(data: data)
        DispatchQueue.main.async { /* render image */ }
    }
}

let queue = OperationQueue()
queue.name = "ImagePipeline"
let fetch = FetchOperation(url: imageURL)
let decode = DecodeOperation(fetch: fetch)
decode.addDependency(fetch)
queue.addOperations([fetch, decode], waitUntilFinished: false)
"""
}

private enum CombineCodeSample {
    static let text = """
import Combine
import AppKit

var cancellables = Set<AnyCancellable>()

URLSession.shared.dataTaskPublisher(for: imageURL)
    .map(\\.data)
    .handleEvents(receiveCancel: {
        // Subscription teardown cancels the URLSession task.
    })
    .receive(on: DispatchQueue.global(qos: .userInitiated))
    .tryMap { data -> Data in
        guard NSImage(data: data) != nil else {
            throw URLError(.cannotDecodeContentData)
        }
        return data
    }
    .receive(on: DispatchQueue.main)
    .eraseToAnyPublisher()
    .sink(
        receiveCompletion: { completion in
            if case .failure(let error) = completion { print(error) }
        },
        receiveValue: { data in
            let image = NSImage(data: data)
            _ = image
        }
    )
    .store(in: &cancellables)

cancellables.forEach { $0.cancel() }
"""
}

private enum SwiftConcurrencyCodeSample {
    static let text = """
import AppKit

actor TransferRecord {
    private(set) var byteCount = 0
    func note(_ data: Data) { byteCount = data.count }
}

@MainActor
final class ImageLoader {
    private var task: Task<Void, Never>?
    private let record = TransferRecord()

    func download(_ url: URL) {
        task?.cancel()
        task = Task { [record] in
            do {
                try Task.checkCancellation()
                let (data, _) = try await URLSession.shared.data(from: url)
                try Task.checkCancellation()
                await record.note(data)
                let image = NSImage(data: data)
                // Isolated on @MainActor — safe to publish to SwiftUI.
                _ = image
            } catch is CancellationError {
                // Cooperative cancel.
            } catch {
                print(error)
            }
        }
    }

    func cancel() { task?.cancel() }
}
"""
}
