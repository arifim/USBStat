//Arif Rakhmanov 6/21/26

import SwiftUI

struct ContentView: View {
    
    @EnvironmentObject var viewModel: USBViewModel
    @ObservedObject var settings = SettingsView.shared
    
    var body: some View {
        
        VStack(spacing: 0) {
            header
                .padding(.vertical, 12)
            
            Divider()
            
            if !viewModel.devices.isEmpty {
                ScrollView(.vertical, showsIndicators: false) {
                    ForEach(viewModel.devices) { device in
                        ItemRowView(usbDevice: device)
                            .padding(12)
                        Divider()
                    }
                }
            } else {
                Spacer()
                VStack {
                    CustomContentUnavailableView(
                        image: "mainLogo",
                        title: "No USB Devices",
                        description: "Connect a USB device to see its details here."
                    )
                }
                Spacer()
            }
            Spacer()
            Divider()
            footer
                .padding(.vertical, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        
    }
    
    var header: some View {
        HStack {
            Image("mainLogo")
                .resizable()
                .frame(width: 16, height: 16)
                .foregroundStyle(.secondary)
            Text("USB devices")
            Spacer()
            BadgeView(text: "\(viewModel.devices.count) connected")
        }
        .padding(.horizontal)
    }
    
    var footer: some View {
        
        HStack {
            Text("Launch at Login")
                Spacer()
                Rectangle()
                    .fill(settings.launchAtLogin ? Color.blue : Color.gray)
                    .frame(width: 44, height: 24)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay {
                        Circle()
                            .fill(.white)
                            .frame(width: 20, height: 20)
                            .offset(x: settings.launchAtLogin ? 10 : -10)
                    }
                    .onTapGesture {
                        withAnimation {
                            settings.launchAtLogin.toggle()
                        }
                    }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
    }
}

#Preview {
    ContentView()
        .environmentObject(USBViewModel())
}
