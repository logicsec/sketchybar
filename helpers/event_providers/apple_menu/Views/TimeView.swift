import SwiftUI

struct TimeView: View {
    @State private var currentTime = Date()
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        Text(timeString)
            .font(.custom(
                Settings.getFontSettings(for: "TimeView").family,
                size: Settings.getFontSettings(for: "TimeView").size
            ))
            .foregroundColor(.white)
            .onReceive(timer) { _ in
                print("Timer fired, updating time")
                self.currentTime = Date()
            }
    }
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let result = formatter.string(from: currentTime)
        print("Current time: \(result)")
        return result
    }
}

#Preview {
    TimeView()
}
