import SwiftUI

struct CalendarView: View {
    @State private var selectedDate = Date()
    @State private var currentMonth = Date()
    private let calendar = Calendar.current
    private let daysOfWeek = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    private let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter
    }()
    private let yearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter
    }()
    
    var body: some View {
        Card {
            VStack(spacing: Settings.CalendarConfig.headerSpacing) {
                // Header with month/year navigation
                HStack {
                    HStack(spacing: Settings.CalendarConfig.buttonSpacing) {
                        Button(action: { changeMonth(by: -1) }) {
                            Text("‹")
                                .foregroundColor(.gray)
                        }
                        .buttonStyle(.plain)
                        
                        Text(monthFormatter.string(from: currentMonth))
                            .foregroundColor(Settings.CalendarConfig.headerTextColor)
                        
                        Button(action: { changeMonth(by: 1) }) {
                            Text("›")
                                .foregroundColor(.gray)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: Settings.CalendarConfig.buttonSpacing) {
                        Button(action: { changeYear(by: -1) }) {
                            Text("‹")
                                .foregroundColor(.gray)
                        }
                        .buttonStyle(.plain)
                        
                        Text(yearFormatter.string(from: currentMonth))
                            .foregroundColor(Settings.CalendarConfig.headerTextColor)
                        
                        Button(action: { changeYear(by: 1) }) {
                            Text("›")
                                .foregroundColor(.gray)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .font(.system(size: Settings.CalendarConfig.monthYearSize, weight: .medium))
                
                // Days of week header
                HStack(spacing: 0) {
                    ForEach(daysOfWeek, id: \.self) { day in
                        Text(day)
                            .font(.system(size: Settings.CalendarConfig.weekdayHeaderSize, weight: .medium))
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity)
                    }
                }
                
                // Calendar grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: Settings.CalendarConfig.gridSpacing) {
                    ForEach(days, id: \.self) { date in
                        if let date = date {
                            let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
                            let isToday = calendar.isDateInToday(date)
                            
                            Text("\(calendar.component(.day, from: date))")
                                .font(.system(size: Settings.CalendarConfig.dayNumberSize))
                                .frame(height: Settings.CalendarConfig.dayHeight)
                                .foregroundColor(textColor(for: date, isSelected: isSelected, isToday: isToday))
                                .background(
                                    Circle()
                                        .fill(isSelected ? Settings.CalendarConfig.selectedBackgroundColor : Color.clear)
                                        .frame(width: Settings.CalendarConfig.dayHeight, height: Settings.CalendarConfig.dayHeight)
                                )
                                .onTapGesture {
                                    selectedDate = date
                                }
                        } else {
                            Text("")
                                .frame(height: Settings.CalendarConfig.dayHeight)
                        }
                    }
                }
            }
        }
        .onAppear {
            selectedDate = Date()
            currentMonth = Date()
        }
    }
    
    private var days: [Date?] {
        let start = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth))!
        let range = calendar.range(of: .day, in: .month, for: start)!
        
        let firstWeekday = calendar.component(.weekday, from: start)
        let previousMonthDays = (0..<(firstWeekday - 1)).map { day in
            calendar.date(byAdding: .day, value: -((firstWeekday - 1) - day), to: start)
        }
        
        let currentMonthDays = (0..<range.count).map { day in
            calendar.date(byAdding: .day, value: day, to: start)!
        }
        
        let remainingDays = 42 - (previousMonthDays.count + currentMonthDays.count)
        let nextMonthDays = (0..<remainingDays).map { day in
            calendar.date(byAdding: .day, value: day, to: calendar.date(byAdding: .month, value: 1, to: start)!)!
        }
        
        return previousMonthDays + currentMonthDays + nextMonthDays
    }
    
    private func textColor(for date: Date, isSelected: Bool, isToday: Bool) -> Color {
        if isSelected {
            return Settings.CalendarConfig.selectedTextColor
        }
        
        if isToday {
            return Settings.CalendarConfig.todayColor
        }
        
        if calendar.isDate(date, equalTo: currentMonth, toGranularity: .month) {
            return Settings.CalendarConfig.defaultTextColor
        }
        
        return Settings.CalendarConfig.dimmedTextColor
    }
    
    private func changeMonth(by value: Int) {
        if let newDate = calendar.date(byAdding: .month, value: value, to: currentMonth) {
            currentMonth = newDate
        }
    }
    
    private func changeYear(by value: Int) {
        if let newDate = calendar.date(byAdding: .year, value: value, to: currentMonth) {
            currentMonth = newDate
        }
    }
}

#Preview {
    CalendarView()
        .frame(width: 300)
        .padding()
        .background(Color.black)
}
