//Arif Rakhmanov 6/21/26


import Foundation

struct USBDevice: Identifiable {
    var id = UUID()
    let name: String
    let serialNumber: String
    let vendorName: String      // "SanDisk", "Apple"
    let vendorID: UInt16        // 0x0781 — число, не строка
    let productID: UInt16       // 0x5591
    let bcdUSB: Int             // "USB 3.2"
    let usbSpeedIndex: Int      // 5000 — мегабиты, не строка
    let powerMA: Int            // 896 — миллиамперы
    let volumes: [USBVolume]
    
    // Вычисляемые свойства — для отображения в UI
    var usbVersion: String {
        let major = (bcdUSB >> 8)
        let minor = (bcdUSB >> 4) & 0xF
        return "USB \(major).\(minor)"
    }
    
    var speedMbps: Int {
        switch usbSpeedIndex {
        case 0: return 2        // Low Speed
        case 1: return 12       // Full Speed
        case 2: return 480      // High Speed
        case 3: return 5000     // Super Speed
        case 4: return 10000    // Super Speed+
        default: return 0
        }
    }
    
    var speedLabel: String {
        speedMbps >= 1000 ? "\(speedMbps / 1000) Gb/s" : "\(speedMbps) Mb/s"
    }
}