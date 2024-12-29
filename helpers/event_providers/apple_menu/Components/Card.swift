import SwiftUI

struct Card<Content: View>: View {
    let content: Content
    var padding: CGFloat = 16
    var backgroundColor: Color = Color(NSColor.windowBackgroundColor).opacity(0.3)
    
    init(padding: CGFloat = 16, 
         backgroundColor: Color = Color(NSColor.windowBackgroundColor).opacity(0.3),
         @ViewBuilder content: () -> Content) {
        self.content = content()
        self.padding = padding
        self.backgroundColor = backgroundColor
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(backgroundColor)
            .cornerRadius(12)
    }
}

#Preview {
    Card {
        Text("Card Content")
            .foregroundColor(.white)
    }
    .frame(width: 200, height: 100)
    .background(Color.black)
}
