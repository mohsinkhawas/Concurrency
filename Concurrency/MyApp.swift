import SwiftUI

@main
struct ConcurrencyLabApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .defaultSize(width: 1320, height: 860)
        .windowResizability(.contentMinSize)
    }
}
