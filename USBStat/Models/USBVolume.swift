//Arif Rakhmanov 6/21/26


import Foundation

struct USBVolume: Identifiable {
    var id = UUID()
    let name: String
    let mountPath: String
    let totalBytes: Int64
    let usedBytes: Int64
    let isMounted: Bool
    
    // Вычисляемое свойство — не хранится, считается на лету
    var freeBytes: Int64 { totalBytes - usedBytes }
}
