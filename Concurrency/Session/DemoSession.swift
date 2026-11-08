import AppKit
import Foundation
import Observation
import SwiftUI

@Observable
final class DemoSession {
    var technology: ConcurrencyTechnology = .thread {
        didSet {
            if oldValue != technology {
                resetOutput(clearLogs: true)
            }
        }
    }

    var selectedPresetID: String = SampleImage.presets[0].id
    var customURL: String = ""
    var detailTab: DetailTab = .overview

    var status: ExecutionStatus = .idle
    var executionThread: ThreadSnapshot?
    var elapsedMilliseconds: Double = 0
    var telemetry: ProcessTelemetry = .capture()
    var baselineTelemetry: ProcessTelemetry = .capture()
    var image: NSImage?
    var byteCount: Int = 0
    var logs: [LogEntry] = []
    var lastError: String?

    var isRunning: Bool {
        switch status {
        case .dispatched, .downloading, .processing: return true
        default: return false
        }
    }

    var resolvedURL: URL? {
        let trimmed = customURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            return URL(string: trimmed)
        }
        guard let preset = SampleImage.presets.first(where: { $0.id == selectedPresetID }) else {
            return nil
        }
        return URL(string: preset.urlString)
    }

    private var generation: UInt64 = 0
    private var clockStart: ContinuousClock.Instant?
    private var ticker: Task<Void, Never>?
    private let threadEngine = ThreadDownloadEngine()
    private let gcdEngine = GCDDownloadEngine()
    private let operationEngine = OperationDownloadEngine()
    private let combineEngine = CombineDownloadEngine()
    private let swiftEngine = SwiftConcurrencyEngine()

    func download() {
        guard let url = resolvedURL else {
            status = .failed
            lastError = "Enter a valid HTTPS image URL."
            appendLog("Rejected start — URL is invalid", thread: .capture(), status: .failed)
            return
        }

        generation += 1
        let capturedGeneration = generation
        activeEngine.cancel()

        image = nil
        byteCount = 0
        lastError = nil
        elapsedMilliseconds = 0
        baselineTelemetry = .capture()
        telemetry = baselineTelemetry
        executionThread = .capture()
        logs.removeAll()
        clockStart = ContinuousClock.now
        startTicker()

        let sink = DownloadSink { [weak self] event in
            Task { @MainActor in
                self?.handle(event, generation: capturedGeneration)
            }
        }

        appendLog("Download requested for \(url.absoluteString)", thread: .capture(), status: .dispatched)
        activeEngine.start(url: url, sink: sink)
    }

    func cancel() {
        guard isRunning else { return }
        appendLog("Cancel requested from UI — \(technology.cancellationNotes)", thread: .capture())
        activeEngine.cancel()
    }

    func clearLogs() {
        logs.removeAll()
    }

    private var activeEngine: any DownloadEngine {
        switch technology {
        case .thread: return threadEngine
        case .gcd: return gcdEngine
        case .operationQueue: return operationEngine
        case .combine: return combineEngine
        case .swiftConcurrency: return swiftEngine
        }
    }

    private func resetOutput(clearLogs: Bool) {
        generation += 1
        threadEngine.cancel()
        gcdEngine.cancel()
        operationEngine.cancel()
        combineEngine.cancel()
        swiftEngine.cancel()
        ticker?.cancel()
        ticker = nil
        clockStart = nil
        status = .idle
        executionThread = nil
        elapsedMilliseconds = 0
        image = nil
        byteCount = 0
        lastError = nil
        if clearLogs {
            logs.removeAll()
        }
        telemetry = .capture()
    }

    private func handle(_ event: DownloadEvent, generation: UInt64) {
        guard generation == self.generation else { return }
        switch event {
        case .log(let message, let thread):
            appendLog(message, thread: thread)
        case .status(let status, let thread):
            self.status = status
            executionThread = thread
            telemetry = .capture()
            appendLog("Status → \(status.title)", thread: thread, status: status)
        case .completed(let data, let thread):
            byteCount = data.count
            image = NSImage(data: data)
            executionThread = thread
            status = .completed
            telemetry = .capture()
            stopTicker()
            appendLog("Completed on @MainActor / main thread — \(data.count) bytes rendered", thread: thread, status: .completed)
        case .failed(let message, let thread):
            lastError = message
            status = .failed
            executionThread = thread
            telemetry = .capture()
            stopTicker()
            appendLog("Failed: \(message)", thread: thread, status: .failed)
        case .cancelled(let thread):
            status = .cancelled
            executionThread = thread
            telemetry = .capture()
            stopTicker()
            appendLog("Cancelled — no image published", thread: thread, status: .cancelled)
        }
    }

    private func appendLog(_ message: String, thread: ThreadSnapshot, status: ExecutionStatus? = nil) {
        logs.append(LogEntry(message: message, thread: thread, status: status))
        if logs.count > 400 {
            logs.removeFirst(logs.count - 400)
        }
    }

    private func startTicker() {
        ticker?.cancel()
        ticker = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                if let clockStart {
                    elapsedMilliseconds = clockStart.duration(to: .now).milliseconds
                }
                telemetry = .capture()
                try? await Task.sleep(for: .milliseconds(80))
            }
        }
    }

    private func stopTicker() {
        if let clockStart {
            elapsedMilliseconds = clockStart.duration(to: .now).milliseconds
        }
        ticker?.cancel()
        ticker = nil
        telemetry = .capture()
    }
}

enum DetailTab: String, CaseIterable, Identifiable {
    case overview
    case code

    var id: String { rawValue }

    var title: String {
        switch self {
        case .overview: return "Overview"
        case .code: return "Code"
        }
    }
}
