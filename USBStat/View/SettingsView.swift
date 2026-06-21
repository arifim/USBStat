//Arif Rakhmanov 6/21/26


import SwiftUI
import Combine
import ServiceManagement


final class SettingsView: ObservableObject {
    static let shared = SettingsView()
    
    @Published var launchAtLogin: Bool {
        didSet {
            UserDefaults.standard.set(launchAtLogin, forKey: "launchAtLogin")
            do {
                if launchAtLogin {
                    try SMAppService.mainApp.register()
                    print("App will start with login")
                } else {
                    try SMAppService.mainApp.unregister()
                    print("App will no longer start with login")
                }
            } catch {
                print(error)
            }
        }
    }
    
    init() {
        self.launchAtLogin = UserDefaults.standard.bool(forKey: "launchAtLogin")
    }
}