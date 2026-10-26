import SwiftUI

@main
struct GeniApp: App {
    #if DEBUG
    init() {
        UITestSupport.resetIfRequested()
    }
    #endif

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
