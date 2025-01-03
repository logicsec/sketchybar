import SwiftUI

public struct MediaPlayerCard: View {
    public init() {}
    
    public var body: some View {
        Card {
            HStack(spacing: 12) {
                // Album art
                Image(nsImage: NSImage(named: "albumArt") ?? NSImage())
                    .resizable()
                    .frame(width: 48, height: 48)
                    .cornerRadius(6)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Little Dark Age")
                        .foregroundColor(.white)
                        .font(.system(size: 14, weight: .medium))
                    
                    Text("ISTERIF")
                        .foregroundColor(.gray)
                        .font(.system(size: 12))
                }
                
                Spacer()
                
                // Playback controls
                HStack(spacing: 12) {
                    Button(action: {}) {
                        Image(systemName: "backward.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 12))
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: {}) {
                        Image(systemName: "play.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 12))
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: {}) {
                        Image(systemName: "forward.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 12))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(12)
        }
    }
} 