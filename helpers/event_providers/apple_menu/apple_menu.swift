import Cocoa
import SwiftUI
import MediaPlayer
import IOKit.ps
import CoreAudio
import Foundation

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

// Add this near the start of the file, after imports
enum PanelType: String {
    case menu = "menu"
    case calendar = "date"
    
    static func from(string: String?) -> PanelType {
        guard let str = string else { 
            print("DEBUG: No string provided, defaulting to menu")
            return .menu 
        }
        let panel = PanelType(rawValue: str) ?? .menu
        print("DEBUG: Parsed panel type: \(str) -> \(panel)")
        return panel
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow?
    var currentPanel: PanelType = .menu
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Debug print arguments
        print("DEBUG: All arguments:", ProcessInfo.processInfo.arguments)
        
        let args = ProcessInfo.processInfo.arguments
        if let panelArg = args.dropFirst().first {
            let cleanArg = panelArg.replacingOccurrences(of: "app=", with: "")
            print("DEBUG: Panel argument after cleaning:", cleanArg)
            currentPanel = PanelType.from(string: cleanArg)
        }
        
        print("DEBUG: Selected panel type:", currentPanel)
        
        // Choose content view based on panel type
        let contentView: AnyView
        switch currentPanel {
        case .menu:
            print("DEBUG: Creating menu panel")
            contentView = AnyView(ContentView())
        case .calendar:
            print("DEBUG: Creating calendar panel")
            contentView = AnyView(CalendarPanelView())
        }
        
        // Rest of your existing window setup code...
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
        sketchyTask.arguments = ["sketchybar", "--query", currentPanel == .menu ? "apple.logo" : "date"]
        
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
            
            // Position at left edge of screen for menu, right edge for calendar
            let windowY = displayHeight - topOffset
            let windowX: CGFloat
            if currentPanel == .menu {
                windowX = displayX + CGFloat(gapSize)
            } else {
                // For calendar panel, position at right edge of screen
                windowX = displayX + displayWidth - windowWidth - CGFloat(gapSize)
            }
            
            window = NSWindow(
                contentRect: NSRect(
                    x: windowX,  // Use calculated windowX
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
            
            // Set initial position based on panel type
            let initialTranslation = currentPanel == .menu ? 
                -window!.frame.width :  // Slide from left for menu
                window!.frame.width     // Slide from right for calendar
            contentView.layer?.transform = CATransform3DMakeTranslation(initialTranslation, 0, 0)
        }
        
        window?.makeKeyAndOrderFront(nil)
        
        // Simple slide animation
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            
            window?.contentView?.layer?.animate(
                keyPath: "transform.translation.x",
                from: currentPanel == .menu ? 
                    -window!.frame.width :  // Slide from left for menu
                    window!.frame.width,    // Slide from right for calendar
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
        
        // Add these window properties
        if let window = window {
            window.isMovableByWindowBackground = false
            window.level = .floating
        }
        
        // Add click handler for detecting clicks outside the window
        NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { event in
            if let window = self.window {
                let screenLocation = event.locationInWindow
                
                // Convert window frame to screen coordinates
                let windowFrame = window.frame
                
                // Check if click is outside the window
                if !windowFrame.contains(screenLocation) {
                    // Send SIGUSR1 to self to close the window
                    kill(getpid(), SIGUSR1)
                }
            }
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
                to: currentPanel == .menu ? 
                    -windowWidth :  // Slide to left for menu
                    windowWidth,    // Slide to right for calendar
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

// Update Card struct to handle EdgeInsets
struct Card: View {
    let content: AnyView
    let backgroundColor: Color
    let padding: EdgeInsets
    let backgroundImage: NSImage?
    let gradientOpacity: Double  // Added parameter for gradient opacity
    
    init(content: AnyView, backgroundColor: Color, padding: EdgeInsets, backgroundImage: NSImage?, gradientOpacity: Double = 0.8) {
        self.content = content
        self.backgroundColor = backgroundColor
        self.padding = padding
        self.backgroundImage = backgroundImage
        self.gradientOpacity = gradientOpacity
    }
    
    var body: some View {
        ZStack {
            if let image = backgroundImage {
                GeometryReader { geometry in
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width * 1.5, height: geometry.size.height)
                        .position(x: geometry.size.width * 0.25, y: geometry.size.height / 2)
                        .clipped()
                        .overlay(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.black.opacity(gradientOpacity),
                                    Color.black.opacity(gradientOpacity * 0.8),
                                    Color.black.opacity(gradientOpacity * 0.6)
                                ]),
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                }
            }
            
            content
                .padding(padding)
                .frame(maxWidth: .infinity)
        }
        .background(backgroundImage == nil ? backgroundColor : Color.clear)
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
    @StateObject private var weatherController = WeatherController()
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
    
    private var mediaPlayerSection: some View {
        Card(
            content: AnyView(
                ZStack {
                    // Blurred background artwork
                    if let artwork = mediaController.artwork {
                        Image(nsImage: artwork)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxWidth: .infinity)
                            .blur(radius: 10)
                            .opacity(0.3)
                    }
                    
                    // Content
                    HStack(spacing: 12) {
                        // Album artwork
                        if let artwork = mediaController.artwork {
                            Image(nsImage: artwork)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 82, height: 82)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        
                        // Title and artist
                        VStack(alignment: .leading, spacing: 4) {
                            Text(mediaController.title)
                                .foregroundColor(.white)
                                .font(.system(size: 14, weight: .medium))
                                .lineLimit(1)
                            
                            Text(mediaController.artist)
                                .foregroundColor(.white.opacity(0.7))
                                .font(.system(size: 12))
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        // Media controls
                        HStack(spacing: 20) {
                            MediaControlButton(systemName: "backward.end.fill") {
                                mediaController.previous()
                            }
                            MediaControlButton(systemName: mediaController.isPlaying ? "pause.fill" : "play.fill") {
                                mediaController.togglePlayPause()
                            }
                            MediaControlButton(systemName: "forward.end.fill") {
                                mediaController.next()
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .frame(height: 110) // Increased height
            ),
            backgroundColor: Color(Colors.cardBackground),
            padding: EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0),
            backgroundImage: nil
        )
        .padding(.horizontal, 30)
    }

    var body: some View {
        ZStack {
            Color(Colors.panelBackground)
            
            VStack(spacing: 16) {
                profileSection
                mediaPlayerSection
                
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: -10),
                    GridItem(.flexible(), spacing: -10),
                    GridItem(.flexible(), spacing: -10),
                    GridItem(.flexible(), spacing: -10)
                ], spacing: -10) {
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
                .padding(.horizontal, 10)
                
                Spacer()
            }
            
            mouseTrackingOverlay
        }
        .cornerRadius(12)
        .onReceive(uptimeTimer) { _ in
            uptime = getUptime()
        }
    }
    
    private var mouseTrackingOverlay: some View {
        MouseTrackingViewRepresentable(
            onMouseEntered: {
                isMouseInside = true
            },
            onMouseExited: {
                isMouseInside = false
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
    @Published private(set) var lastArtwork: NSImage?
    
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
                
                if let elapsed = info["kMRMediaRemoteNowPlayingInfoElapsedTime"] as? Double {
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
                        self.lastArtwork = image // Store the artwork
                    }
                }
                
                // If no current artwork but we have last artwork and title isn't empty
                if self.artwork == nil && !self.title.isEmpty {
                    self.artwork = self.lastArtwork
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

// Add a MediaControl button component
struct MediaControlButton: View {
    let systemName: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 12, weight: .semibold))  // Reduced from 16 to 12
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
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

// Add WeatherController
class WeatherController: ObservableObject {
    @Published var currentTemp: Double = 0
    @Published var feelsLike: Double = 0
    @Published var condition: String = ""
    @Published var humidity: Int = 0
    @Published var weatherIcon: String = "sun.max.fill"
    @Published var forecast: [(day: String, high: Double, low: Double, icon: String)] = []
    
    private var timer: Timer?
    private let weatherIconMap: [Int: String] = [
        1000: "sun.max.fill",        // Clear
        1003: "cloud.sun.fill",      // Partly cloudy
        1006: "cloud.fill",          // Cloudy
        1009: "smoke.fill",          // Overcast
        1030: "cloud.fog.fill",      // Mist
        1063: "cloud.drizzle.fill",  // Rain
        1066: "cloud.snow.fill",     // Snow
        // Add more mappings as needed
    ]
    
    init() {
        updateWeather()
        // Update weather every 30 minutes
        timer = Timer.scheduledTimer(withTimeInterval: 1800, repeats: true) { [weak self] _ in
            self?.updateWeather()
        }
    }
    
    private func updateWeather() {
        // Get the absolute path to the .env file
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
        let envPath = homeDirectory.appendingPathComponent(".config/sketchybar/helpers/event_providers/apple_menu/.env").path
        
        print("Looking for .env file at:", envPath)  // Debug print
        
        guard let envContent = try? String(contentsOfFile: envPath, encoding: .utf8) else {
            print("Error: Could not load .env file from \(envPath)")
            return
        }
        
        // Parse API key and city from .env file
        let lines = envContent.components(separatedBy: .newlines)
        var apiKey = ""
        var city = ""
        
        for line in lines {
            if line.starts(with: "WEATHER_API_KEY=") {
                apiKey = String(line.dropFirst("WEATHER_API_KEY=".count))
            } else if line.starts(with: "WEATHER_CITY=") {
                city = String(line.dropFirst("WEATHER_CITY=".count))
            }
        }
        
        guard !apiKey.isEmpty, !city.isEmpty else {
            print("Error: Missing API key or city in .env file")
            return
        }
        
        // URL encode the city name
        guard let encodedCity = city.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            print("Error: Could not encode city name")
            return
        }
        
        let urlString = "http://api.weatherapi.com/v1/forecast.json?key=\(apiKey)&q=\(encodedCity)&days=5&aqi=no&units=imperial"
        
        guard let url = URL(string: urlString) else {
            print("Error: Could not create URL from string")
            return 
        }
        
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let data = data else { return }
            
            
            do {
                let decoder = JSONDecoder()
                let weatherData = try decoder.decode(WeatherResponse.self, from: data)
                
                DispatchQueue.main.async {
                    // Update the published properties with Fahrenheit values
                    self?.currentTemp = weatherData.current.temp_f
                    self?.feelsLike = weatherData.current.feelslike_f
                    self?.humidity = weatherData.current.humidity
                    self?.condition = weatherData.current.condition.text
                    
                    // Update weather icon based on condition code
                    if let iconCode = self?.weatherIconMap[weatherData.current.condition.code] {
                        self?.weatherIcon = iconCode
                    }
                    
                    self?.forecast = weatherData.forecast.forecastday.map { day in
                        return (
                            day: day.date,
                            high: day.day.maxtemp_f,
                            low: day.day.mintemp_f,
                            icon: self?.weatherIconMap[day.day.condition.code] ?? "sun.max.fill"
                        )
                    }
                }
            } catch {
                print("Error decoding weather data: \(error)")
            }
        }.resume()
    }
}

// Add WeatherView
struct WeatherView: View {
    @ObservedObject var weatherController: WeatherController
    
    var body: some View {
        Card(
            content: AnyView(
                HStack {
                    // Left side - Weather icon
                    Image(systemName: weatherController.weatherIcon)
                        .font(.system(size: 32))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Right side - Temperature and condition
                    VStack(alignment: .trailing, spacing: 4) {
                        // Changed °C to °F
                        Text("\(Int(weatherController.currentTemp))°F")
                            .font(.system(size: 32, weight: .medium))
                            .foregroundColor(.white)
                        
                        // Condition text
                        Text(weatherController.condition)
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            ),
            backgroundColor: Color(Colors.cardBackground),
            padding: EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20),
            backgroundImage: nil
        )
        .padding(.horizontal, 20)
    }
}

// Add these structs to decode the JSON response
struct WeatherResponse: Codable {
    let current: Current
    let forecast: Forecast
}

struct Current: Codable {
    let temp_f: Double
    let feelslike_f: Double
    let humidity: Int
    let condition: Condition
}

struct Condition: Codable {
    let code: Int
    let text: String
}

struct Forecast: Codable {
    let forecastday: [ForecastDay]
}

struct ForecastDay: Codable {
    let date: String
    let day: Day
}

struct Day: Codable {
    let maxtemp_f: Double
    let mintemp_f: Double
    let condition: Condition
}

// Add a helper function to get day name from date string
private func getDayName(from dateString: String) -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"
    
    guard let date = dateFormatter.date(from: dateString) else { return "" }
    
    dateFormatter.dateFormat = "EEE" // "EEE" gives abbreviated day name (Mon, Tue, etc.)
    return dateFormatter.string(from: date)
}

// Move CalendarView out of ContentView and place it at file level
struct CalendarView: View {
    private let weekDays = ["S", "M", "T", "W", "T", "F", "S"]
    private let date: Date
    
    init() {
        // Get date from sketchybar's date item
        let dateTask = Process()
        dateTask.launchPath = "/usr/bin/env"
        dateTask.arguments = ["sketchybar", "--query", "date"]
        
        let datePipe = Pipe()
        dateTask.standardOutput = datePipe
        dateTask.launch()
        
        let dateData = datePipe.fileHandleForReading.readDataToEndOfFile()
        dateTask.waitUntilExit()
        
        if let dateInfo = try? JSONSerialization.jsonObject(with: dateData, options: []) as? [String: Any],
           let dateString = dateInfo["label"] as? String {
            // Parse the date string from sketchybar
            let formatter = DateFormatter()
            formatter.dateFormat = "E MMM d"  // Format matching sketchybar's date format
            if let parsedDate = formatter.date(from: dateString) {
                self.date = parsedDate
            } else {
                self.date = Date()  // Fallback to current date if parsing fails
            }
        } else {
            self.date = Date()  // Fallback to current date if query fails
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            let spacing = (geometry.size.width - 30 - (20 * 7)) / 6 // Calculate dynamic spacing
            
            VStack(spacing: 12) {
                // Month and Year
                Text(date.formatted(.dateTime.month(.wide).year()))
                    .foregroundColor(.white)
                    .font(.system(size: 14, weight: .semibold))
                
                // Week days
                HStack(spacing: spacing) {
                    ForEach(weekDays, id: \.self) { day in
                        Text(day)
                            .font(.system(size: 12))
                            .foregroundColor(day == "S" ? Color(hex: "#ed8796") ?? .red : .white.opacity(0.7))
                            .frame(width: 20)
                    }
                }
                
                // Calendar grid
                let days = generateDaysInMonth()
                VStack(spacing: 8) {
                    ForEach(0..<6) { row in
                        HStack(spacing: spacing) {
                            ForEach(0..<7) { column in
                                let index = row * 7 + column
                                if index < days.count {
                                    let day = days[index]
                                    Text(day.number)
                                        .font(.system(size: 12))
                                        .foregroundColor(day.isCurrentMonth ? 
                                            (day.isToday ? .white : .white.opacity(0.7)) : 
                                            .white.opacity(0.3))
                                        .frame(width: 20)
                                        .fontWeight(day.isToday ? .bold : .regular)
                                } else {
                                    Text("")
                                        .frame(width: 20)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 15)
            .frame(maxWidth: .infinity)
        }
        .frame(height: 220)
    }
    
    private struct DayItem {
        let number: String
        let isCurrentMonth: Bool
        let isToday: Bool
    }
    
    private func generateDaysInMonth() -> [DayItem] {
        var days: [DayItem] = []
        
        // Get the first day of the month
        let firstDayOfMonth = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: date))!
        
        // Get the weekday of the first day (0 = Sunday)
        let firstWeekday = Calendar.current.component(.weekday, from: firstDayOfMonth) - 1
        
        // Add days from previous month
        let previousMonth = Calendar.current.date(byAdding: .month, value: -1, to: firstDayOfMonth)!
        let daysInPreviousMonth = Calendar.current.range(of: .day, in: .month, for: previousMonth)!.count
        for day in (daysInPreviousMonth - firstWeekday + 1)...daysInPreviousMonth {
            days.append(DayItem(number: "\(day)", isCurrentMonth: false, isToday: false))
        }
        
        // Add days from current month
        let daysInMonth = Calendar.current.range(of: .day, in: .month, for: firstDayOfMonth)!.count
        let currentDay = Calendar.current.component(.day, from: date)
        for day in 1...daysInMonth {
            days.append(DayItem(number: "\(day)", isCurrentMonth: true, isToday: day == currentDay))
        }
        
        // Add days from next month
        let remainingDays = 42 - days.count // 6 rows * 7 days = 42
        for day in 1...remainingDays {
            days.append(DayItem(number: "\(day)", isCurrentMonth: false, isToday: false))
        }
        
        return days
    }
}

// Add this new struct for panel titles
struct PanelTitle: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.system(size: 20, weight: .semibold))
            .foregroundColor(Color(hex: "#ed8796") ?? .white)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 30)
            .padding(.top, 25)
            .padding(.bottom, 10)
    }
}

// Add new CalendarPanelView
struct CalendarPanelView: View {
    @StateObject private var statsController = StatsController()
    @StateObject private var weatherController = WeatherController()
    @State private var isMouseInside = false
    
    var body: some View {
        ZStack {
            Color(Colors.panelBackground)
            
            VStack(spacing: 16) {
                // Add title
                PanelTitle(title: "Time And Weather")
                
                // Calendar section
                Card(
                    content: AnyView(CalendarView()),
                    backgroundColor: Color(Colors.cardBackground),
                    padding: EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0),
                    backgroundImage: nil
                )
                .padding(.horizontal, 30)
                
                // Weather section
                WeatherView(weatherController: weatherController)
                .padding(.horizontal, 10)
                
                Spacer()
            }
            
            mouseTrackingOverlay
        }
        .cornerRadius(12)
    }
    
    private var mouseTrackingOverlay: some View {
        MouseTrackingViewRepresentable(
            onMouseEntered: {
                isMouseInside = true
            },
            onMouseExited: {
                isMouseInside = false
            }
        )
        .allowsHitTesting(false)
    }
}

// MARK: - Preview Provider
#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .frame(width: 300, height: 400)
            .preferredColorScheme(.dark)
    }
}

struct WeatherView_Previews: PreviewProvider {
    static var previews: some View {
        WeatherView(weatherController: WeatherController())
            .frame(width: 280)
            .preferredColorScheme(.dark)
    }
}

struct CalendarView_Previews: PreviewProvider {
    static var previews: some View {
        CalendarView()
            .frame(width: 280)
            .preferredColorScheme(.dark)
    }
}
#endif
