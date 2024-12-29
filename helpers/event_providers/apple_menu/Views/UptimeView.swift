import SwiftUI

struct UptimeView: View {
    @State private var uptime = ""
    let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    
    var body: some View {
        Text(uptime)
            .font(.custom(
                Settings.getFontSettings(for: "UptimeView").family,
                size: Settings.getFontSettings(for: "UptimeView").size
            ))
            .foregroundColor(.gray)
            .onAppear {
                updateUptime()
            }
            .onReceive(timer) { _ in
                updateUptime()
            }
    }
    
    private func updateUptime() {
        var boottime = timeval()
        var size = MemoryLayout<timeval>.stride
        var mib: [Int32] = [CTL_KERN, KERN_BOOTTIME]
        
        if sysctl(&mib, 2, &boottime, &size, nil, 0) != -1 {
            let now = Date().timeIntervalSince1970
            let uptime = now - Double(boottime.tv_sec)
            
            let hours = Int(uptime) / 3600
            let minutes = Int(uptime) / 60 % 60
            
            if hours > 0 {
                let formattedHours = String(format: "%02d", hours)
                let formattedMinutes = String(format: "%02d", minutes)
                self.uptime = "uptime \(formattedHours):\(formattedMinutes)"
            } else {
                let formattedMinutes = String(format: "%02d", minutes)
                self.uptime = "uptime 00:\(formattedMinutes)"
            }
        } else {
            self.uptime = "uptime unavailable"
        }
    }
}
