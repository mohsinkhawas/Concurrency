# Concurrency Demo App

Concurrency Demo App is a macOS SwiftUI app for exploring how different Apple-platform concurrency APIs handle the same image-download workflow. Select an approach, start or cancel a download, and inspect its execution status, thread information, telemetry, and event log. The app also includes an overview and code documentation for each approach.

## Concurrency approaches

- **Thread** — manually managed `NSThread` worker
- **Grand Central Dispatch** — `DispatchQueue` and `DispatchWorkItem`
- **OperationQueue** — dependent fetch and decode operations
- **Combine** — a cancellable `URLSession` publisher pipeline
- **Swift Concurrency** — `async`/`await`, tasks, and an actor

Each approach downloads an image, decodes it off the main thread, and publishes it to the UI on the main thread. You can use a built-in sample image or provide a custom HTTPS image URL.

## Requirements

- macOS 14 or later
- Xcode

## Run

1. Clone this repository.
2. Open `Concurrency.xcodeproj` in Xcode.
3. Select the **Concurrency** scheme and a Mac destination.
4. Build and run the app.

## Project structure

- `Concurrency/Engines/` — implementations for each concurrency approach
- `Concurrency/Models/` — technology descriptions and demo models
- `Concurrency/Session/` — download state, event handling, and telemetry
- `Concurrency/Views/` — SwiftUI interface components
