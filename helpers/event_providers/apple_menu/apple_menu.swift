import Cocoa
import SwiftUI
import MediaPlayer
import IOKit.ps
import CoreAudio

// Replace the existing MediaRemote declarations with this approach
let bundle = CFBundleCreate(kCFAllocatorDefault, NSURL(fileURLWithPath: "/System/Library/PrivateFrameworks/MediaRemote.framework"))

// Update the pointer declarations to use CFBundleGetFunctionPointerForName
let MRMediaRemoteGetNowPlayingInfoPointer = CFBundleGetFunctionPointerForName(
    bundle, "MRMediaRemoteGetNowPlayingInfo" as CFString
)
let MRMediaRemoteGetNowPlayingApplicationIsPlayingPointer = CFBundleGetFunctionPointerForName(
    bundle, "MRMediaRemoteGetNowPlayingApplicationIsPlaying" as CFString
)
let MRMediaRemoteGetNowPlayingApplicationDisplayNamePointer = CFBundleGetFunctionPointerForName(
    bundle, "MRMediaRemoteGetNowPlayingApplicationDisplayName" as CFString
)
let MRMediaRemoteRegisterForNowPlayingNotificationsPointer = CFBundleGetFunctionPointerForName(
    bundle, "MRMediaRemoteRegisterForNowPlayingNotifications" as CFString
)
let MRMediaRemoteSendCommandPointer = CFBundleGetFunctionPointerForName(
    bundle, "MRMediaRemoteSendCommand" as CFString
)

// Add MediaRemote types
typealias MRMediaRemoteGetNowPlayingInfoFunction = @convention(c) (DispatchQueue, @escaping ([String: Any]) -> Void) -> Void
typealias MRMediaRemoteGetNowPlayingApplicationIsPlayingFunction = @convention(c) (DispatchQueue, @escaping (Bool) -> Void) -> Void
typealias MRMediaRemoteGetNowPlayingApplicationDisplayNameFunction = @convention(c) (Int, DispatchQueue, @escaping (CFString) -> Void) -> Void
typealias MRMediaRemoteRegisterForNowPlayingNotificationsFunction = @convention(c) (DispatchQueue) -> Void
typealias MRMediaRemoteSendCommandFunction = @convention(c) (UInt32, UnsafeMutableRawPointer?) -> Bool

// Add MediaRemote functions
let MRMediaRemoteGetNowPlayingInfo = unsafeBitCast(MRMediaRemoteGetNowPlayingInfoPointer, to: MRMediaRemoteGetNowPlayingInfoFunction.self)
let MRMediaRemoteGetNowPlayingApplicationIsPlaying = unsafeBitCast(MRMediaRemoteGetNowPlayingApplicationIsPlayingPointer, to: MRMediaRemoteGetNowPlayingApplicationIsPlayingFunction.self)
let MRMediaRemoteGetNowPlayingApplicationDisplayName = unsafeBitCast(MRMediaRemoteGetNowPlayingApplicationDisplayNamePointer, to: MRMediaRemoteGetNowPlayingApplicationDisplayNameFunction.self)
let MRMediaRemoteRegisterForNowPlayingNotifications = unsafeBitCast(MRMediaRemoteRegisterForNowPlayingNotificationsPointer, to: MRMediaRemoteRegisterForNowPlayingNotificationsFunction.self)
let MRMediaRemoteSendCommand = unsafeBitCast(MRMediaRemoteSendCommandPointer, to: MRMediaRemoteSendCommandFunction.self)

// Add MediaRemote constants
let kMRMediaRemoteNowPlayingInfoDidChangeNotification = NSNotification.Name("kMRMediaRemoteNowPlayingInfoDidChangeNotification")
let kMRMediaRemoteNowPlayingApplicationIsPlayingDidChangeNotification = NSNotification.Name("kMRMediaRemoteNowPlayingApplicationIsPlayingDidChangeNotification")
let kMRMediaRemoteNowPlayingApplicationDidChangeNotification = NSNotification.Name("kMRMediaRemoteNowPlayingApplicationDidChangeNotification")

let kMRMediaRemoteNowPlayingInfoTitle = "kMRMediaRemoteNowPlayingInfoTitle"
let kMRMediaRemoteNowPlayingInfoArtist = "kMRMediaRemoteNowPlayingInfoArtist"
let kMRMediaRemoteNowPlayingInfoAlbum = "kMRMediaRemoteNowPlayingInfoAlbum"
let kMRMediaRemoteNowPlayingInfoArtworkData = "kMRMediaRemoteNowPlayingInfoArtworkData"

let kMRPlay: UInt32 = 0
let kMRPause: UInt32 = 1
let kMRTogglePlayPause: UInt32 = 2
let kMRStop: UInt32 = 3
let kMRNextTrack: UInt32 = 4
let kMRPreviousTrack: UInt32 = 5

let kMRMediaRemoteNowPlayingInfoElapsedTime = "kMRMediaRemoteNowPlayingInfoElapsedTime"
let kMRMediaRemoteNowPlayingInfoDuration = "kMRMediaRemoteNowPlayingInfoDuration"
let kMRMediaRemoteNowPlayingInfoPlaybackProgress = "kMRMediaRemoteNowPlayingInfoPlaybackProgress"

// Add this constant at the top with other MediaRemote constants
let MPNowPlayingInfoPropertyElapsedPlaybackTime = "MPNowPlayingInfoPropertyElapsedPlaybackTime"

// Add these constants if not already present
let kMRNowPlayingPlaybackQueueChangedNotification = "kMRNowPlayingPlaybackQueueChangedNotification"
let kMRPlaybackQueueContentItemsChangedNotification = "kMRPlaybackQueueContentItemsChangedNotification"
let kMRMediaRemoteNowPlayingApplicationClientStateDidChange = "kMRMediaRemoteNowPlayingApplicationClientStateDidChange"

// Add this function at the file level (outside any struct/class)
func getUptime() -> String {
    var boottime = timeval()
    var size = MemoryLayout<timeval>.stride
    var mib: [Int32] = [CTL_KERN, KERN_BOOTTIME]
    
    if sysctl(&mib, 2, &boottime, &size, nil, 0) != -1 {
        let now = Date().timeIntervalSince1970
        let uptime = now - Double(boottime.tv_sec)
        
        let hours = Int(uptime) / 3600
        let minutes = Int(uptime) / 60 % 60
        
        if hours > 0 {
            return "up \(hours) \(hours == 1 ? "hour" : "hours"), \(minutes) \(minutes == 1 ? "minute" : "minutes")"
        } else {
            return "up \(minutes) \(minutes == 1 ? "minute" : "minutes")"
        }
    }
    
    return "uptime unavailable"
}

struct Colors {
    static var panelBackground = NSColor(hex: "0D1116")!.withAlphaComponent(0.95)
    static var cardBackground = NSColor(hex: "1B2128")!.withAlphaComponent(0.95)
    static var accent = NSColor(hex: "8fa9e6")!
    static var diskUsage = NSColor(hex: "e6c17d")!
    static var graphBackground = NSColor(hex: "414559")!
    
    static func initialize(panelHex: String, cardHex: String) {
        if let panel = NSColor(hex: panelHex) {
            panelBackground = panel
        }
        if let card = NSColor(hex: cardHex) {
            cardBackground = card
        }
    }
}

extension NSColor {
    convenience init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6: // RGB
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow?
    private var autoCloseTimer: Timer?
    
    func startAutoCloseTimer() {
        autoCloseTimer?.invalidate()
        autoCloseTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { [weak self] _ in
            self?.handleGracefulClose()
        }
    }
    
    func stopAutoCloseTimer() {
        autoCloseTimer?.invalidate()
        autoCloseTimer = nil
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {        
        signal(SIGUSR1, { signal in
            if let delegate = NSApplication.shared.delegate as? AppDelegate {
                DispatchQueue.main.async {
                    delegate.handleGracefulClose()
                }
            }
        })
        
        let contentView = ContentView()
        
        // Get focused display position from yabai
        let yabaiTask = Process()
        yabaiTask.launchPath = "/usr/bin/env"
        yabaiTask.arguments = ["yabai", "-m", "query", "--displays", "--display"]
        
        let yabaiPipe = Pipe()
        yabaiTask.standardOutput = yabaiPipe
        yabaiTask.launch()
        
        let yabaiData = yabaiPipe.fileHandleForReading.readDataToEndOfFile()
        yabaiTask.waitUntilExit()
                
        // Get item position from SketchyBar
        let sketchyTask = Process()
        sketchyTask.launchPath = "/usr/bin/env"
        sketchyTask.arguments = ["sketchybar", "--query", "apple.logo"]
        
        let sketchyPipe = Pipe()
        sketchyTask.standardOutput = sketchyPipe
        sketchyTask.launch()
        
        let sketchyData = sketchyPipe.fileHandleForReading.readDataToEndOfFile()
        sketchyTask.waitUntilExit()
                
        // Get bar height from sketchybar
        let barTask = Process()
        barTask.launchPath = "/usr/bin/env"
        barTask.arguments = ["sketchybar", "--query", "bar"]
        
        let barPipe = Pipe()
        barTask.standardOutput = barPipe
        barTask.launch()
        
        let barData = barPipe.fileHandleForReading.readDataToEndOfFile()
        barTask.waitUntilExit()
        
        // Parse bar height from sketchybar data
        var barHeight: CGFloat = 25  // Default height
        if let barInfo = try? JSONSerialization.jsonObject(with: barData, options: []) as? [String: Any],
           let height = barInfo["height"] as? Double {
            barHeight = CGFloat(height)
        }
                
        // Get yabai window gaps
        let gapsTask = Process()
        gapsTask.launchPath = "/usr/bin/env"
        gapsTask.arguments = ["yabai", "-m", "config", "window_gap"]
        
        let gapsPipe = Pipe()
        gapsTask.standardOutput = gapsPipe
        gapsTask.launch()
        
        let gapsData = gapsPipe.fileHandleForReading.readDataToEndOfFile()
        gapsTask.waitUntilExit()
        
        // Parse the gaps value
        let gapSize = Int(String(data: gapsData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "0") ?? 0
        
        // Calculate total offset (bar height + gap)
        let topOffset = barHeight + CGFloat(gapSize)
        
        // Parse responses and position window
        if let yabaiInfo = try? JSONSerialization.jsonObject(with: yabaiData, options: []) as? [String: Any],
           let displayIndex = yabaiInfo["index"] as? Int,
           let frame = yabaiInfo["frame"] as? [String: Double],
           let itemInfo = try? JSONSerialization.jsonObject(with: sketchyData, options: []) as? [String: Any],
           let boundingRects = itemInfo["bounding_rects"] as? [String: Any],
           let displayRect = boundingRects["display-\(displayIndex)"] as? [String: Any],
           let _ = displayRect["origin"] as? [Double] {
            
            
            let displayX = frame["x"] ?? 0
            let displayWidth = frame["w"] ?? 0
            let displayHeight = frame["h"] ?? 0
            let windowWidth: CGFloat = displayWidth * 0.20  // 20% of screen width
            
            // Position at left edge of screen
            let windowY = displayHeight - topOffset
        
            
            window = NSWindow(
                contentRect: NSRect(
                    x: displayX + CGFloat(gapSize),
                    y: CGFloat(gapSize),
                    width: windowWidth,
                    height: windowY - CGFloat(gapSize)
                ),
                styleMask: [],  // Empty style mask prevents all window controls including resizing
                backing: .buffered,
                defer: false
            )
            
            // Force the window size
            window?.setContentSize(NSSize(width: windowWidth, height: windowY - CGFloat(gapSize)))
            
            // Add size constraint
            if let window = window {
                window.maxSize = NSSize(width: windowWidth, height: windowY - CGFloat(gapSize))
                window.minSize = NSSize(width: windowWidth, height: windowY - CGFloat(gapSize))
            }
            
        }
        
        window?.contentView = NSHostingView(rootView: contentView)
        window?.backgroundColor = .clear
        window?.isMovableByWindowBackground = false
        window?.level = .floating
        window?.hasShadow = false
        
        if let contentView = window?.contentView {
            contentView.wantsLayer = true
            contentView.layer?.cornerRadius = 12
            contentView.layer?.masksToBounds = true
            contentView.layer?.backgroundColor = NSColor.clear.cgColor
            contentView.layer?.opacity = 0.0
            
            // Start from completely collapsed state
            contentView.layer?.transform = CATransform3DMakeTranslation(-window!.frame.width, 0, 0)
        }
        
        window?.makeKeyAndOrderFront(nil)
        
        // Start auto-close timer after window is shown
        startAutoCloseTimer()
        
        // Simple slide animation
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3  // Reduced duration for cleaner slide
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            
            window?.contentView?.layer?.animate(
                keyPath: "transform.translation.x",
                from: -window!.frame.width,
                to: 0,
                duration: context.duration
            )
            
            window?.contentView?.layer?.animate(
                keyPath: "opacity",
                from: 0.0,
                to: 1.0,
                duration: context.duration
            )
        }
    }
    
    func handleGracefulClose() {
        animateWindowClose {
            NSApplication.shared.terminate(nil)
        }
    }
    
    func animateWindowClose(completion: @escaping () -> Void) {
        guard let contentView = window?.contentView,
              let windowWidth = window?.frame.width else {
            completion()
            return
        }
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            
            contentView.layer?.animate(
                keyPath: "transform.translation.x",
                from: 0,
                to: -windowWidth,
                duration: context.duration
            )
            
            contentView.layer?.animate(
                keyPath: "opacity",
                from: 1.0,
                to: 0.0,
                duration: context.duration
            )
        }, completionHandler: completion)
    }
}

// Add MouseTrackingView and MouseTrackingViewRepresentable (same as media player)
class MouseTrackingView: NSView {
    var onMouseEntered: (() -> Void)?
    var onMouseExited: (() -> Void)?
    private var trackingArea: NSTrackingArea?
    
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        
        if let existingTrackingArea = trackingArea {
            removeTrackingArea(existingTrackingArea)
        }
        
        let options: NSTrackingArea.Options = [.mouseEnteredAndExited, .activeAlways]
        trackingArea = NSTrackingArea(rect: bounds, options: options, owner: self, userInfo: nil)
        
        if let trackingArea = trackingArea {
            addTrackingArea(trackingArea)
        }
    }
    
    override func mouseEntered(with event: NSEvent) {
        onMouseEntered?()
    }
    
    override func mouseExited(with event: NSEvent) {
        onMouseExited?()
    }
}

struct MouseTrackingViewRepresentable: NSViewRepresentable {
    let onMouseEntered: () -> Void
    let onMouseExited: () -> Void
    
    func makeNSView(context: Context) -> MouseTrackingView {
        let view = MouseTrackingView()
        view.onMouseEntered = onMouseEntered
        view.onMouseExited = onMouseExited
        return view
    }
    
    func updateNSView(_ nsView: MouseTrackingView, context: Context) {}
}

// Update CircularProgressView
struct CircularProgressView: View {
    let progress: Double
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .trim(from: 0, to: CGFloat(progress))
                    .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 50, height: 50)
                    .rotationEffect(.degrees(-90))
                
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
            }
            .padding(.top, 12)
            
            Text("\(Int(progress * 100))%")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(color)
                .padding(.bottom, 12)
        }
        .frame(width: 90, height: 110)
        .background(Color(Colors.cardBackground))
        .cornerRadius(12)
    }
}

// Update Card struct to accept padding override
struct Card: View {
    let content: AnyView
    let backgroundColor: Color
    let padding: CGFloat
    
    init(content: AnyView, backgroundColor: Color? = nil, padding: CGFloat = 8) {
        self.content = content
        self.backgroundColor = backgroundColor ?? Color(Colors.cardBackground)
        self.padding = padding
    }
    
    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity)
            .background(backgroundColor)
            .cornerRadius(12)
    }
}

// Add Bundle extension for app icon lookup
extension Bundle {
    func bundleIdentifier(forAppNamed appName: String) -> String? {
        switch appName {
        case "Music":
            return "com.apple.Music"
        case "Spotify":
            return "com.spotify.client"
        case "Brave Browser":
            return "com.brave.Browser"
        default:
            return nil
        }
    }
}

// Update ContentView to handle multiple displays
struct ContentView: View {
    @StateObject private var statsController = StatsController()
    @StateObject private var mediaController = MediaController()
    @State private var isMouseInside = false
    @State private var uptime: String = getUptime()
    let username: String = NSFullUserName()
    
    // Add timer to update the uptime
    let uptimeTimer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    
    private var profileSection: some View {
        HStack(spacing: 12) {
            // Profile image and name
            HStack(spacing: 12) {
                Circle()
                    .fill(Color(Colors.accent))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.white)
                    )
                
                Text(username)
                    .foregroundColor(.white)
                    .font(.system(size: 12, weight: .semibold))
            }
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 8) {
                ActionButton(icon: "power", color: Color(NSColor(hex: "ed8796")!)) {
                    powerOff()
                }
                
                ActionButton(icon: "arrow.counterclockwise", color: Color(NSColor(hex: "f5a97f")!)) {
                    restart()
                }
                
                ActionButton(icon: "lock.fill", color: Color(NSColor(hex: "a6da95")!)) {
                    lock()
                }
                
                ActionButton(icon: "rectangle.portrait.and.arrow.right", color: Color(NSColor(hex: "8aadf4")!)) {
                    logout()
                }
            }
        }
        .padding(30)
        .padding(.top, 5)
    }
    
    var body: some View {
        ZStack {
            Color(Colors.panelBackground)
            
            VStack(spacing: 16) {
                profileSection
                
                // Media player card
                Card(content: AnyView(
                    HStack(spacing: 12) {
                        // Album artwork
                        if let artwork = mediaController.artwork {
                            Image(nsImage: artwork)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 60, height: 60)
                                .cornerRadius(8)
                        } else {
                            Rectangle()
                                .fill(Color(Colors.graphBackground))
                                .frame(width: 60, height: 60)
                                .cornerRadius(8)
                                .overlay(
                                    Image(systemName: "music.note")
                                        .foregroundColor(.white.opacity(0.5))
                                )
                        }
                        
                        // Title and artist
                        VStack(alignment: .leading, spacing: 4) {
                            Text(mediaController.title)
                                .foregroundColor(.white)
                                .font(.system(size: 14, weight: .semibold))
                                .lineLimit(1)
                            
                            Text(mediaController.artist)
                                .foregroundColor(.white.opacity(0.7))
                                .font(.system(size: 12))
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        // Media controls
                        HStack(spacing: 16) {
                            Button(action: { mediaController.previous() }) {
                                Image(systemName: "backward.end.fill")
                                    .foregroundColor(.white)
                                    .font(.system(size: 16))
                            }
                            .buttonStyle(.plain)
                            .onHover { inside in
                                if inside {
                                    NSCursor.pointingHand.push()
                                } else {
                                    NSCursor.pop()
                                }
                            }
                            
                            Button(action: { mediaController.togglePlayPause() }) {
                                Image(systemName: mediaController.isPlaying ? "pause.fill" : "play.fill")
                                    .foregroundColor(.white)
                                    .font(.system(size: 16))
                            }
                            .buttonStyle(.plain)
                            .onHover { inside in
                                if inside {
                                    NSCursor.pointingHand.push()
                                } else {
                                    NSCursor.pop()
                                }
                            }
                            
                            Button(action: { mediaController.next() }) {
                                Image(systemName: "forward.end.fill")
                                    .foregroundColor(.white)
                                    .font(.system(size: 16))
                            }
                            .buttonStyle(.plain)
                            .onHover { inside in
                                if inside {
                                    NSCursor.pointingHand.push()
                                } else {
                                    NSCursor.pop()
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 5)
                ), backgroundColor: Color(Colors.cardBackground))
                .padding(.horizontal, 30)
                .padding(.bottom, 10)
                
                // Stats grid
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: -10),  // Reduced spacing between items
                    GridItem(.flexible(), spacing: -10),
                    GridItem(.flexible(), spacing: -10),
                    GridItem(.flexible(), spacing: -10)
                ], spacing: -10) {  // Reduced spacing between rows
                    CircularProgressView(
                        progress: statsController.batteryLevel,
                        icon: statsController.isCharging ? "bolt.fill" : "battery.100.fill",
                        color: Color(hex: "#4CD964") ?? .green
                    )
                    
                    CircularProgressView(
                        progress: statsController.volumeLevel,
                        icon: volumeIcon(level: statsController.volumeLevel, isMuted: statsController.isMuted),
                        color: Color(hex: "#8AADF4") ?? .blue
                    )
                    
                    CircularProgressView(
                        progress: statsController.diskUsage,
                        icon: "internaldrive",
                        color: Color(Colors.diskUsage)
                    )
                    
                    CircularProgressView(
                        progress: statsController.memoryUsage,
                        icon: "memorychip",
                        color: Color(Colors.accent)
                    )
                }
                .padding(.horizontal, 10)  // Added horizontal padding for the whole grid
                
                Spacer()
            }
            
            mouseTrackingOverlay
        }
        .cornerRadius(12)
        .onReceive(uptimeTimer) { _ in
            uptime = getUptime()  // Update the uptime every minute
        }
    }
    
    private var mouseTrackingOverlay: some View {
        MouseTrackingViewRepresentable(
            onMouseEntered: {
                isMouseInside = true
                if let delegate = NSApplication.shared.delegate as? AppDelegate {
                    delegate.stopAutoCloseTimer()
                }
            },
            onMouseExited: {
                isMouseInside = false
                if let delegate = NSApplication.shared.delegate as? AppDelegate {
                    delegate.startAutoCloseTimer()
                }
            }
        )
        .allowsHitTesting(false)
    }
    
    private func volumeIcon(level: Double, isMuted: Bool) -> String {
        if isMuted {
            return "speaker.slash.fill"
        }
        
        let percentage = level * 100
        switch percentage {
        case 0:
            return "speaker.fill"
        case 0.1...33:
            return "speaker.wave.1.fill"
        case 33.1...66:
            return "speaker.wave.2.fill"
        default:
            return "speaker.wave.3.fill"
        }
    }
}

// Add this extension for layer animations
extension CALayer {
    func animate(keyPath: String, from: CGFloat, to: CGFloat, duration: CGFloat) {
        let animation = CABasicAnimation(keyPath: keyPath)
        animation.fromValue = from
        animation.toValue = to
        animation.duration = duration
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        add(animation, forKey: keyPath)
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()

class StatsController: ObservableObject {
    @Published private(set) var memoryUsage: Double = 0.0
    @Published private(set) var diskUsage: Double = 0.0
    @Published private(set) var batteryLevel: Double = 0.0
    @Published private(set) var isCharging: Bool = false
    @Published private(set) var volumeLevel: Double = 0.0
    @Published private(set) var isMuted: Bool = false
    
    private var timer: Timer?
    
    init() {
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.updateStats()
        }
        updateStats()
    }
    
    private func updateStats() {
        updateMemoryUsage()
        updateDiskUsage()
        updateBatteryStatus()
        updateVolumeLevel()
    }
    
    private func updateMemoryUsage() {
        var stats = vm_statistics64()
        var size = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.stride / MemoryLayout<integer_t>.stride)
        let result = withUnsafeMutablePointer(to: &stats) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(size)) { pointer in
                host_statistics64(mach_host_self(), HOST_VM_INFO64, pointer, &size)
            }
        }
        
        if result == KERN_SUCCESS {
            let total = Double(stats.active_count + stats.inactive_count + stats.wire_count + stats.free_count)
            let used = Double(stats.active_count + stats.inactive_count + stats.wire_count)
            let usage = used / total
            
            DispatchQueue.main.async {
                self.memoryUsage = usage
            }
        }
    }
    
    private func updateDiskUsage() {
        let fileURL = URL(fileURLWithPath: "/")
        do {
            let values = try fileURL.resourceValues(forKeys: [.volumeTotalCapacityKey, .volumeAvailableCapacityKey])
            if let total = values.volumeTotalCapacity,
               let available = values.volumeAvailableCapacity {
                let used = Double(total - available)
                let usage = used / Double(total)
                
                DispatchQueue.main.async {
                    self.diskUsage = usage
                }
            }
        } catch {
            print("Error getting disk usage: \(error)")
        }
    }
    
    private func updateBatteryStatus() {
        if let powerSource = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
           let sources = IOPSCopyPowerSourcesList(powerSource)?.takeRetainedValue() as? [CFTypeRef] {
            
            for source in sources {
                if let description = IOPSGetPowerSourceDescription(powerSource, source)?.takeUnretainedValue() as? [String: Any] {
                    DispatchQueue.main.async {
                        self.batteryLevel = (description[kIOPSCurrentCapacityKey] as? Double ?? 0) / 100.0
                        self.isCharging = description[kIOPSPowerSourceStateKey] as? String == kIOPSACPowerValue
                    }
                }
            }
        }
    }
    
    private func updateVolumeLevel() {
        var deviceSize = UInt32(MemoryLayout<AudioDeviceID>.size)
        var defaultOutputDevice = kAudioObjectUnknown
        
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        // Get default output device
        AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &deviceSize,
            &defaultOutputDevice
        )
        
        // Get volume
        propertyAddress.mSelector = kAudioHardwareServiceDeviceProperty_VirtualMainVolume
        propertyAddress.mScope = kAudioDevicePropertyScopeOutput
        
        var volume: Float32 = 0.0
        deviceSize = UInt32(MemoryLayout<Float32>.size)
        
        AudioObjectGetPropertyData(
            defaultOutputDevice,
            &propertyAddress,
            0,
            nil,
            &deviceSize,
            &volume
        )
        
        // Get mute status
        propertyAddress.mSelector = kAudioDevicePropertyMute
        
        var isMuted: UInt32 = 0
        deviceSize = UInt32(MemoryLayout<UInt32>.size)
        
        AudioObjectGetPropertyData(
            defaultOutputDevice,
            &propertyAddress,
            0,
            nil,
            &deviceSize,
            &isMuted
        )
        
        DispatchQueue.main.async {
            self.volumeLevel = Double(volume)
            self.isMuted = isMuted == 1
        }
    }
    
    deinit {
        timer?.invalidate()
    }
}

class MediaController: ObservableObject {
    @Published var title: String = ""
    @Published var artist: String = ""
    @Published var album: String = ""
    @Published var isPlaying: Bool = false
    @Published var artwork: NSImage?
    @Published var currentApp: String = ""
    @Published var elapsedTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    
    private var initialTime: TimeInterval = 0
    private var playbackStartTime: Date?
    private var playbackSpeed: Double = 1.0
    private var progressTimer: Timer?
    
    init() {
        // Add this at the start of init()
        NSEvent.addLocalMonitorForEvents(matching: .systemDefined) { event in
            if event.subtype.rawValue == 8 { // Remote control event
                return nil
            }
            return event
        }
        
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.playCommand.addTarget { event in
            return .success
        }
        commandCenter.pauseCommand.addTarget { event in
            return .success
        }
        
        MRMediaRemoteRegisterForNowPlayingNotifications(DispatchQueue.main)

        // Get initial playback state and time
        MRMediaRemoteGetNowPlayingInfo(DispatchQueue.main) { [weak self] info in
            DispatchQueue.main.async {
                print("\nChecking Now Playing Info:")
                print("MediaRemote Info:", info)
                
                let nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo
                print("MPNowPlayingInfoCenter Info:", nowPlayingInfo ?? "No info available")
                
                if let elapsed = info["kMRMediaRemoteNowPlayingInfoElapsedTime"] as? Double {
                    print("Found elapsed time:", elapsed)
                    self?.initialTime = elapsed
                    self?.elapsedTime = elapsed
                    
                    // If we're currently playing, set up the timer with the correct initial time
                    if self?.isPlaying == true {
                        self?.playbackStartTime = Date()
                        self?.startTimer()
                    }
                }
                
                if let total = info["kMRMediaRemoteNowPlayingInfoDuration"] as? Double {
                    self?.duration = total
                }
            }
        }

        MRMediaRemoteGetNowPlayingApplicationIsPlaying(DispatchQueue.main) { [weak self] playing in
            DispatchQueue.main.async {
                self?.isPlaying = playing
                if playing {
                    // Only start the timer if we have a valid elapsed time
                    if self?.elapsedTime ?? 0 > 0 {
                        self?.playbackStartTime = Date()
                        self?.startTimer()
                    }
                }
            }
        }

        // Add observers for changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMediaChange),
            name: kMRMediaRemoteNowPlayingInfoDidChangeNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePlayingChange),
            name: kMRMediaRemoteNowPlayingApplicationIsPlayingDidChangeNotification,
            object: nil
        )

        updateNowPlaying()
    }
    
    private func startTimer() {
        progressTimer?.invalidate()
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, self.isPlaying else { return }
            
            if let startTime = self.playbackStartTime {
                let timePassed = -startTime.timeIntervalSinceNow * self.playbackSpeed
                let newElapsed = self.initialTime + timePassed
                self.elapsedTime = min(newElapsed, self.duration) // Ensure we don't exceed duration
            }
        }
    }
    
    private func stopTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
        // Store the current time as initial time for next playback
        initialTime = elapsedTime
        playbackStartTime = nil
    }

    func togglePlayPause() {
        if currentApp != "Music" {
            if isPlaying {
                if MRMediaRemoteSendCommand(kMRPause, nil) {
                    isPlaying = false
                    stopTimer()
                }
            } else {
                if MRMediaRemoteSendCommand(kMRPlay, nil) {
                    isPlaying = true
                    startTimer()
                }
            }
        }
    }

    func updateNowPlayingTime() {
        MRMediaRemoteGetNowPlayingInfo(DispatchQueue.main) { [weak self] info in
            guard let self = self else { return }

            DispatchQueue.main.async {
                if let elapsed = info[kMRMediaRemoteNowPlayingInfoElapsedTime] as? TimeInterval {
                    self.elapsedTime = elapsed
                }
                if let total = info[kMRMediaRemoteNowPlayingInfoDuration] as? TimeInterval {
                    self.duration = total
                }
            }
        }
    }

    @objc func handlePlayingChange(_ notification: Notification) {
        MRMediaRemoteGetNowPlayingApplicationIsPlaying(DispatchQueue.main) { [weak self] playing in
            DispatchQueue.main.async {
                self?.isPlaying = playing
                if playing {
                    // Only start the timer if we have a valid elapsed time
                    if self?.elapsedTime ?? 0 > 0 {
                        self?.playbackStartTime = Date()
                        self?.startTimer()
                    }
                } else {
                    self?.stopTimer()
                }
            }
        }
    }

    @objc func handleMediaChange(_ notification: Notification) {
        MRMediaRemoteGetNowPlayingInfo(DispatchQueue.main) { [weak self] info in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                // Get the new title
                let newTitle = info[kMRMediaRemoteNowPlayingInfoTitle] as? String ?? ""
                
                // Check if the song has changed
                if newTitle != self.title {
                    // For song changes, get the new elapsed time
                    if let elapsed = info[MPNowPlayingInfoPropertyElapsedPlaybackTime] as? Double {
                        self.initialTime = elapsed
                        self.elapsedTime = elapsed
                    } else {
                        self.resetPlaybackTimer()
                    }
                }
                
                // Update basic info
                self.title = newTitle
                self.artist = info[kMRMediaRemoteNowPlayingInfoArtist] as? String ?? ""
                self.album = info[kMRMediaRemoteNowPlayingInfoAlbum] as? String ?? ""
                
                // Update artwork if available
                if let artworkData = info[kMRMediaRemoteNowPlayingInfoArtworkData] as? Data {
                    if let image = NSImage(data: artworkData) {
                        self.artwork = image
                    }
                }
                
                // Always update duration and playback speed
                if let total = info[kMRMediaRemoteNowPlayingInfoDuration] as? Double {
                    self.duration = total
                }
                if let speed = info["kMRMediaRemoteNowPlayingInfoPlaybackSpeed"] as? Double {
                    self.playbackSpeed = speed
                }
            }
        }
    }

    func updateNowPlaying() {
        handleMediaChange(Notification(name: kMRMediaRemoteNowPlayingInfoDidChangeNotification))
    }

    func next() {
        if currentApp != "Music" {
            if MRMediaRemoteSendCommand(kMRNextTrack, nil) {
                // Reset timer on track change
                resetPlaybackTimer()
                updateNowPlaying()
            }
        }
    }

    func previous() {
        if currentApp != "Music" {
            if MRMediaRemoteSendCommand(kMRPreviousTrack, nil) {
                // Reset timer on track change
                resetPlaybackTimer()
                updateNowPlaying()
            }
        }
    }

    private func resetPlaybackTimer() {
        stopTimer()
        initialTime = 0
        elapsedTime = 0
        playbackStartTime = Date()
        if isPlaying {
            startTimer()
        }
    }

    var progress: Double {
        guard duration > 0 else { return 0 }
        return min(elapsedTime / duration, 1.0)
    }
}

// Helper function to format time
func formatTime(seconds: Double) -> String {
    let minutes = Int(seconds) / 60
    let seconds = Int(seconds) % 60
    return String(format: "%d:%02d", minutes, seconds)
}

// Add these functions to handle system actions
func powerOff() {
    let source = """
    tell application "System Events"
        shut down
    end tell
    """
    runAppleScript(source)
}

func restart() {
    let source = """
    tell application "System Events"
        restart
    end tell
    """
    runAppleScript(source)
}

func lock() {
    let source = """
    tell application "System Events"
        keystroke "q" using {command down, control down}
    end tell
    """
    runAppleScript(source)
}

func logout() {
    let source = """
    tell application "System Events"
        log out
    end tell
    """
    runAppleScript(source)
}

func runAppleScript(_ source: String) {
    if let script = NSAppleScript(source: source) {
        var error: NSDictionary?
        script.executeAndReturnError(&error)
    }
}

// Add a new ActionButton component
struct ActionButton: View {
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 14))
                .frame(width: 32, height: 32)
                .background(Color(Colors.cardBackground))
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .onHover { inside in
            if inside {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}

// Add Color extension for hex support if not already present
extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else {
            return nil
        }
        
        self.init(
            red: Double((rgb & 0xFF0000) >> 16) / 255.0,
            green: Double((rgb & 0x00FF00) >> 8) / 255.0,
            blue: Double(rgb & 0x0000FF) / 255.0
        )
    }
}
