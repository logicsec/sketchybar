import SwiftUI

public struct CalendarSection: View {
    @State private var selectedDate = Date()
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE/MMM/dd"
        return formatter
    }()
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 12) {
            // Calendar card with header
            Card {
                VStack(spacing: 12) {
                    // Date header
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.gray)
                        Text(dateFormatter.string(from: selectedDate))
                            .foregroundColor(.gray)
                            .font(.system(size: 14))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Calendar grid
                    CalendarCard(showHeader: false)
                }
                .padding(12)
            }
            
            // Media player as separate card
            MediaPlayerCard()
        }
    }
} 