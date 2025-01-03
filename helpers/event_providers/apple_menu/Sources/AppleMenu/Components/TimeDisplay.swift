import SwiftUI

public struct TimeDisplay: View {
    @State private var currentTime = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
    
    public init() {}
    
    public var body: some View {
        Text(timeFormatter.string(from: currentTime))
            .foregroundColor(.gray)
            .font(.system(size: 14))
            .onReceive(timer) { input in
                currentTime = input
            }
    }
} 