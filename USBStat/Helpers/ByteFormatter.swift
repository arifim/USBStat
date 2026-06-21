//Arif Rakhmanov 6/21/26


import Foundation

struct ByteFormatter {
    
    static func formatBytes(_ bytes: Int64) -> String {
        let gb = Double(bytes) / 1_000_000_000
        let mb = Double(bytes) / 1_000_000
        
        if gb >= 1 {
            return String(format: "%.1f GB", gb)
        } else {
            return String(format: "%.1f MB", mb)
        }
    }
}
