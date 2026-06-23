//Arif Rakhmanov 6/21/26


import SwiftUI

struct CustomContentUnavailableView: View {
    
    let image: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(spacing: 20) {
            Circle()
                .fill(Color.gray.opacity(0.6))
                .frame(width: 56, height: 56)
                .overlay {
                    Image(image)
                        .resizable()
                        .frame(width: 32, height: 32)
                        .foregroundStyle(.gray)
                }
            
            Text(title)
                .font(.title)
                
            Text(description)
                .foregroundStyle(.secondary)
                .font(.caption)
                .multilineTextAlignment(.center)
        }
    }
}

#Preview {
    CustomContentUnavailableView(
        image: "mainLogo",
        title: "No USB Devices",
        description: "Connect a USB device to see it's details here."
    )
}
