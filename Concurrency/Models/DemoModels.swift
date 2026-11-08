import Foundation
import SwiftUI

nonisolated enum ExecutionStatus: String, Sendable, Equatable {
    case idle
    case dispatched
    case downloading
    case processing
    case completed
    case cancelled
    case failed

    var title: String {
        rawValue.capitalized
    }

    var tint: Color {
        switch self {
        case .idle: return .secondary
        case .dispatched: return .blue
        case .downloading: return .indigo
        case .processing: return .orange
        case .completed: return .green
        case .cancelled: return .yellow
        case .failed: return .red
        }
    }
}

nonisolated struct ThreadSnapshot: Sendable, Equatable {
    let id: UInt64
    let name: String
    let isMain: Bool

    var summary: String {
        let lane = isMain ? "Main" : "Background"
        return "\(lane) · \(name) · id \(id)"
    }

    static func capture() -> ThreadSnapshot {
        var threadID: UInt64 = 0
        pthread_threadid_np(nil, &threadID)
        let rawName = Thread.current.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let name: String
        if !rawName.isEmpty {
            name = rawName
        } else if Thread.isMainThread {
            name = "main"
        } else {
            name = Thread.current.qualityOfService.label
        }
        return ThreadSnapshot(id: threadID, name: name, isMain: Thread.isMainThread)
    }
}

nonisolated extension QualityOfService {
    var label: String {
        switch self {
        case .userInteractive: return "userInteractive"
        case .userInitiated: return "userInitiated"
        case .utility: return "utility"
        case .background: return "background"
        case .default: return "default"
        default: return "unspecified"
        }
    }
}

nonisolated struct ProcessTelemetry: Sendable, Equatable {
    let residentBytes: UInt64
    let threadCount: Int

    var memoryLabel: String {
        ByteCountFormatter.string(fromByteCount: Int64(residentBytes), countStyle: .memory)
    }

    static func capture() -> ProcessTelemetry {
        ProcessTelemetry(residentBytes: machResidentBytes(), threadCount: machThreadCount())
    }
}

nonisolated struct LogEntry: Identifiable, Equatable, Sendable {
    let id: UUID
    let timestamp: Date
    let message: String
    let thread: ThreadSnapshot
    let status: ExecutionStatus?

    init(message: String, thread: ThreadSnapshot, status: ExecutionStatus? = nil) {
        self.id = UUID()
        self.timestamp = Date()
        self.message = message
        self.thread = thread
        self.status = status
    }
}

nonisolated enum DownloadEvent: Sendable {
    case log(String, ThreadSnapshot)
    case status(ExecutionStatus, ThreadSnapshot)
    case completed(Data, ThreadSnapshot)
    case failed(String, ThreadSnapshot)
    case cancelled(ThreadSnapshot)
}

struct SampleImage: Identifiable, Hashable {
    let id: String
    let title: String
    let urlString: String

    static let presets: [SampleImage] = [
        SampleImage(
            id: "alps",
            title: "Alps · Unsplash",
            urlString: "https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=1600"
        ),
        SampleImage(
            id: "forest",
            title: "Forest · Unsplash",
            urlString: "https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=1600"
        ),
        SampleImage(
            id: "city",
            title: "Night City · Unsplash",
            urlString: "https://images.unsplash.com/photo-1480714378408-67cf0d13bc1b?w=1600"
        ),
        SampleImage(
            id: "coast",
            title: "Coast · Unsplash",
            urlString: "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=1600"
        ),
        SampleImage(
            id: "picsum",
            title: "Picsum 1600×1000",
            urlString: "https://picsum.photos/1600/1000"
        )
    ]
}

nonisolated struct DownloadSink: Sendable {
    let emit: @Sendable (DownloadEvent) -> Void

    func log(_ message: String, thread: ThreadSnapshot = .capture()) {
        emit(.log(message, thread))
    }

    func status(_ status: ExecutionStatus, thread: ThreadSnapshot = .capture()) {
        emit(.status(status, thread))
    }

    func complete(_ data: Data, thread: ThreadSnapshot = .capture()) {
        emit(.completed(data, thread))
    }

    func fail(_ message: String, thread: ThreadSnapshot = .capture()) {
        emit(.failed(message, thread))
    }

    func cancelled(thread: ThreadSnapshot = .capture()) {
        emit(.cancelled(thread))
    }
}

nonisolated func machResidentBytes() -> UInt64 {
    var info = mach_task_basic_info()
    var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
    let result = withUnsafeMutablePointer(to: &info) { pointer in
        pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { rebound in
            task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), rebound, &count)
        }
    }
    return result == KERN_SUCCESS ? info.resident_size : 0
}

nonisolated func machThreadCount() -> Int {
    var threadList: thread_act_array_t?
    var count: mach_msg_type_number_t = 0
    let result = task_threads(mach_task_self_, &threadList, &count)
    defer {
        if let threadList {
            let size = vm_size_t(MemoryLayout<thread_t>.stride * Int(count))
            vm_deallocate(mach_task_self_, vm_address_t(UInt(bitPattern: threadList)), size)
        }
    }
    return result == KERN_SUCCESS ? Int(count) : 0
}

nonisolated extension Duration {
    var milliseconds: Double {
        let parts = components
        return Double(parts.seconds) * 1_000 + Double(parts.attoseconds) / 1e15
    }
}
