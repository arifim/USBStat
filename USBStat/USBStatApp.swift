//Arif Rakhmanov 6/21/26

import SwiftUI

@main
struct USBStatApp: App {
    @StateObject private var viewModel = USBViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
        }
    }
}
