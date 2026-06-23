//Arif Rakhmanov 6/21/26


import SwiftUI
import Combine



@MainActor
class USBViewModel: ObservableObject {

    @Published var devices: [USBDevice] = []

    private let monitor = USBMonitorService()
    private let volumeService = VolumeService()
    private var refreshTimer: Timer?

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
        stopLiveRefresh()
        monitor.stopMonitoring()
    }

    // Периодически пересчитываем занятость диска, пока popover открыт.
    func startLiveRefresh() {
        guard refreshTimer == nil else { return }
        monitor.refresh()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { [weak self] _ in
            self?.monitor.refresh()
        }
    }

    func stopLiveRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    func eject(_ volume: USBVolume) {
        try? volumeService.eject(volume) { _ in }
    }
}
