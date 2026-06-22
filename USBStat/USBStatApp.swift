//Arif Rakhmanov 6/21/26

import SwiftUI

@main
struct USBStatApp: App {
    @StateObject private var viewModel = USBViewModel()

    var body: some Scene {
        MenuBarExtra {
            ContentView()
                .environmentObject(viewModel)
                .frame(width: 380, height: 480)
        } label: {
            Image("trayIcon")
                .renderingMode(.template)
        }
        .menuBarExtraStyle(.window)
    }
}
