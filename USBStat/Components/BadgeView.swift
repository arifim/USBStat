//Arif Rakhmanov 6/21/26


import SwiftUI

struct BadgeView: View {
    
    let text: String
    
    var body: some View {
        Text(text)
            .foregroundStyle(Color.secondary)
            .padding(.vertical, 4)
            .padding(.horizontal, 6)
            .background(Color.gray.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}