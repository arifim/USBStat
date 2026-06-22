//Arif Rakhmanov 6/21/26


import SwiftUI

struct DiskUsageBar: View {
    
    let name: String
    let volume: USBVolume
        
    private let width: CGFloat = 330
    
    var eject: (() -> Void)?
        
    var body: some View {
        VStack(alignment: .leading) {
            
            HStack {
                Image(systemName: "mediastick")
                    .foregroundStyle(.white)
                VStack(alignment: .leading) {
                    Text(name.uppercased())
                    Text(volume.mountPath)
                        .foregroundStyle(.secondary.opacity(0.5))
                }
                Spacer()
                
                Button{
                    eject?()
                } label: {
                    HStack {
                        Image(systemName: "chevron.up")
                        Text("Eject")
                    }
                }
                Button{
                    openInFinder(path: volume.mountPath)
                } label: {
                    Image(systemName: "folder")
                        .padding(.vertical, 1)
                }
            }
            
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: width, height: 5)
                
                RoundedRectangle(cornerRadius: 8)
                    .fill(barColor)
                    .frame(width: percent * width, height: 5)
            }
            HStack {
                Text("\(ByteFormatter.formatBytes(volume.usedBytes)) used")
                Spacer()
                Text("\(ByteFormatter.formatBytes(volume.freeBytes)) free")
                Spacer()
                Text("\(Int(percent * 100))%")
            }
        }
        .frame(maxWidth: width)
        .padding(.vertical, 12)
        .padding(.horizontal, 12)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.2))
        }
    }
}

#Preview {
    let name = "SanDisk USB5.6"
    let vol = USBVolume(name: "Dashag", mountPath: "/Volumes/SANDISK", totalBytes: 1000000, usedBytes: 333200, isMounted: true)
    DiskUsageBar(name: name, volume: vol)
        .padding()
}

extension DiskUsageBar {
    func openInFinder(path: String) {
        let escaped = path.replacingOccurrences(of: "\\", with: "\\\\")
                          .replacingOccurrences(of: "\"", with: "\\\"")
        let source = """
        tell application "Finder"
            activate
            open POSIX file "\(escaped)"
        end tell
        """
        var error: NSDictionary?
        NSAppleScript(source: source)?.executeAndReturnError(&error)
        if let error = error {
            print("AppleScript error:", error)
        }
    }

    var percent: CGFloat {
        CGFloat(volume.usedBytes) / CGFloat(volume.totalBytes)
    }
    
    var barColor: Color {
        
        switch percent {
        case 0..<0.5:  return .green
        case 0.5..<0.8: return .yellow
        default:        return .red
        }
    }
}
