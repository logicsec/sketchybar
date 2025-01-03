import SwiftUI

public struct ProfileCard: View {
    let username: String
    let uptime: String
    
    public init(username: String, uptime: String) {
        self.username = username
        self.uptime = uptime
    }
    
    public var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 8) {
                Text(username)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white)
                Text(uptime)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
        }
    }
} 