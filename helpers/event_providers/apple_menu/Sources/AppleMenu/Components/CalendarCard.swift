import SwiftUI

public struct CalendarCard: View {
    let calendar = Calendar.current
    @State private var selectedDate = Date()
    let showHeader: Bool
    
    public init(showHeader: Bool = true) {
        self.showHeader = showHeader
    }
    
    public var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                // Calendar grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                    // Weekday headers
                    ForEach(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { day in
                        Text(day)
                            .foregroundColor(.gray)
                            .font(.system(size: 12))
                    }
                    
                    // Date cells
                    ForEach(getDaysInMonth(), id: \.self) { date in
                        if let date = date {
                            Text("\(calendar.component(.day, from: date))")
                                .foregroundColor(.white)
                                .font(.system(size: 12))
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("")
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            .padding(12)
        }
    }
    
    private func getDaysInMonth() -> [Date?] {
        var days: [Date?] = []
        let range = calendar.range(of: .day, in: .month, for: selectedDate)!
        
        // Add empty cells for days before the first of the month
        let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedDate))!
        let weekday = calendar.component(.weekday, from: firstDayOfMonth)
        for _ in 1..<weekday {
            days.append(nil)
        }
        
        // Add the days of the month
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDayOfMonth) {
                days.append(date)
            }
        }
        
        return days
    }
} 