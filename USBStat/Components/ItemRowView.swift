//Arif Rakhmanov 6/21/26


import SwiftUI

struct ItemRowView: View {
    @EnvironmentObject var viewModel: USBViewModel
    @State private var copied = false
    
    let usbDevice: USBDevice
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 32, height: 32)
                    .overlay {
                        Image(systemName: "mediastick")
                    }
                VStack(alignment: .leading) {
                    Text(usbDevice.name)
                        .font(.title3).fontWeight(.semibold)
                    Text(usbDevice.vendorName)
                        .foregroundStyle(.secondary)
                    
                }
                Spacer()
                
                HStack(spacing: 4) {
                    BadgeView(text: usbDevice.usbVersion)
                    BadgeView(text: usbDevice.speedLabel)
                    
                }
                
            }
            HStack {
                Text(copied ? "Copied" : "S/N: \(usbDevice.serialNumber)")
                    .onTapGesture {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(usbDevice.serialNumber, forType: .string)
                        copied = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            copied = false
                        }
                    }
                    .help("Click to copy")
                if (usbDevice.powerMA > 0) {
                    Text("\(usbDevice.powerMA) mA")
                }
            }
            .padding(.leading, 44)
            .font(Font.custom("Avenir", size: 13))
            .foregroundStyle(.secondary)
            .frame(maxWidth: 356, alignment: .leading)
            
            
            ForEach(usbDevice.volumes) { volume in
                if volume.isMounted {
                    DiskUsageBar(name: usbDevice.name, volume: volume) {
                        viewModel.eject(volume)
                    }
                } else {
                    Text("⚠️ Cannot be mounted")
                        .foregroundStyle(.orange)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
            }
            
        }
        
        .frame(maxWidth: 356)
    }
}

#Preview {
    
    let volume = USBVolume(
        name: "SANDISK",
        mountPath: "/Volumes/SANDISK",
        totalBytes: 10000000,
        usedBytes: 200000,
        isMounted: true
    )
    
    let usbDevice = USBDevice(
        name: "SanDisk Ultra",
        serialNumber: "7G8H9J0K1L2M",
        vendorName: "Western Digital",
        vendorID: 1283,
        productID: 9834,
        bcdUSB: 512,
        usbSpeedIndex: 2000,
        powerMA: 5,
        volumes: [volume]
    )
    ItemRowView(usbDevice: usbDevice)
        .padding()
}
