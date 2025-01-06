import SwiftUI

public enum CardStyle {
    case primary    // Card 1 - darker background (1B2128)
    case secondary  // Card 2 - matches window background (17/255.0, 17/255.0, 27/255.0)
}

public struct Card<Content: View>: View {
    let content: Content
    let style: CardStyle
    var padding: EdgeInsets = EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
    var cornerRadius: CGFloat = 16
    var borderWidth: CGFloat = 1
    
    public init(
        style: CardStyle = .primary,
        padding: EdgeInsets = EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16),
        cornerRadius: CGFloat = 16,
        borderWidth: CGFloat = 1,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.style = style
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.borderWidth = borderWidth
    }
    
    private var backgroundColor: Color {
        switch style {
        case .primary:
            return Color(red: 27/255.0, green: 33/255.0, blue: 40/255.0)  // #1B2128
        case .secondary:
            return Color(red: 17/255.0, green: 17/255.0, blue: 27/255.0)  // Matches window background
        }
    }
    
    private var borderColor: Color {
        switch style {
        case .primary:
            return Color(red: 32/255.0, green: 38/255.0, blue: 45/255.0)
        case .secondary:
            return Color(red: 28/255.0, green: 28/255.0, blue: 38/255.0)
        }
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