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
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                // Откатываем тумблер, если системе не удалось изменить статус автозапуска.
                launchAtLogin = oldValue
            }
        }
    }
    
    init() {
        self.launchAtLogin = UserDefaults.standard.bool(forKey: "launchAtLogin")
    }
}