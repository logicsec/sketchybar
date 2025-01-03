import SwiftUI

public struct Card<Content: View>: View {
    let content: Content
    var backgroundColor: Color = Color(red: 23/255.0, green: 23/255.0, blue: 33/255.0)
    var padding: EdgeInsets = EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
    var cornerRadius: CGFloat = 16
    var borderWidth: CGFloat = 1
    var borderColor: Color = Color(red: 28/255.0, green: 28/255.0, blue: 38/255.0)
    
    public init(
        backgroundColor: Color = Color(red: 23/255.0, green: 23/255.0, blue: 33/255.0),
        padding: EdgeInsets = EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16),
        cornerRadius: CGFloat = 16,
        borderWidth: CGFloat = 1,
        borderColor: Color = Color(red: 28/255.0, green: 28/255.0, blue: 38/255.0),
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.backgroundColor = backgroundColor
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.borderWidth = borderWidth
        self.borderColor = borderColor
    }
    
    public var body: some View {
        ZStack {
            // Base background
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(backgroundColor)
            
            // Gradient overlay
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.1),
                            Color.white.opacity(0.05),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            
            // Border
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(borderColor, lineWidth: borderWidth)
            
            // Content
            content
                .padding(padding)
        }
    }
} 