import SwiftUI

public struct SystemControlsCard: View {
    public init() {}
    
    public var body: some View {
        Card {
            HStack(spacing: 16) {
                // Power
                Button(action: {}) {
                    Image(systemName: "power")
                        .foregroundColor(.white)
                        .font(.system(size: 12))
                }
                .buttonStyle(PlainButtonStyle())
                
                // Moon
                Button(action: {}) {
                    Image(systemName: "moon.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 12))
                }
                .buttonStyle(PlainButtonStyle())
                
                // WiFi
                Button(action: {}) {
                    Image(systemName: "wifi")
                        .foregroundColor(.white)
                        .font(.system(size: 12))
                }
                .buttonStyle(PlainButtonStyle())
                
                // Bluetooth
                Button(action: {}) {
                    Image(systemName: "bluetooth")
                        .foregroundColor(.white)
                        .font(.system(size: 12))
                }
                .buttonStyle(PlainButtonStyle())
                
                // Desktop
                Button(action: {}) {
                    Image(systemName: "display")
                        .foregroundColor(.white)
                        .font(.system(size: 12))
                }
                .buttonStyle(PlainButtonStyle())
                
                // Layers
                Button(action: {}) {
                    Image(systemName: "square.3.stack.3d")
                        .foregroundColor(.white)
                        .font(.system(size: 12))
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(12)
        }
    }
} 