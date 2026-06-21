//Arif Rakhmanov 6/21/26


import SwiftUI
import Combine



@MainActor
class USBViewModel: ObservableObject {
    
    @Published var devices: [USBDevice] = []
    @Published var errorMessage = ""
    
    private let monitor = USBMonitorService()
    private let volumeService = VolumeService()
    
    init() {
        start()
    }
    
    func start() {
        monitor.onDevicesChanged = { [weak self] devices in
            DispatchQueue.main.async {
                self?.devices = devices
            }
        }
        monitor.startMonitoring()
    }
    
    func stop() {
        monitor.stopMonitoring()
    }
    
    
    func eject(_ volume: USBVolume) {
        do {
            try volumeService.eject(volume) { success in
                if success {
                    print("успешно извлечено")
                } else {
                    print("ошибка извлечения")
                }
            }
        } catch {
            errorMessage = "Error "
        }
    }
    
    
    
}
