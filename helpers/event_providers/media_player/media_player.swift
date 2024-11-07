import Cocoa
import SwiftUI
import MediaPlayer

// Private API declarations
private let MRMediaRemoteGetNowPlayingInfoPointer = dlsym(UnsafeMutableRawPointer(bitPattern: -2), "MRMediaRemoteGetNowPlayingInfo")
private let MRMediaRemoteGetNowPlayingApplicationIsPlayingPointer = dlsym(UnsafeMutableRawPointer(bitPattern: -2), "MRMediaRemoteGetNowPlayingApplicationIsPlaying")
private let MRMediaRemoteGetNowPlayingApplicationDisplayNamePointer = dlsym(UnsafeMutableRawPointer(bitPattern: -2), "MRMediaRemoteGetNowPlayingApplicationDisplayName")
private let MRMediaRemoteRegisterForNowPlayingNotificationsPointer = dlsym(UnsafeMutableRawPointer(bitPattern: -2), "MRMediaRemoteRegisterForNowPlayingNotifications")
private let MRMediaRemoteSendCommandPointer = dlsym(UnsafeMutableRawPointer(bitPattern: -2), "MRMediaRemoteSendCommand")
private let MRMediaRemoteSeekToPlaybackPositionPointer = dlsym(UnsafeMutableRawPointer(bitPattern: -2), "MRMediaRemoteSeekToPlaybackPosition")

typealias MRMediaRemoteGetNowPlayingInfoFunction = @convention(c) (DispatchQueue, @escaping ([String: Any]) -> Void) -> Void
typealias MRMediaRemoteGetNowPlayingApplicationIsPlayingFunction = @convention(c) (DispatchQueue, @escaping (Bool) -> Void) -> Void
typealias MRMediaRemoteGetNowPlayingApplicationDisplayNameFunction = @convention(c) (Int, DispatchQueue, @escaping (CFString) -> Void) -> Void
typealias MRMediaRemoteRegisterForNowPlayingNotificationsFunction = @convention(c) (DispatchQueue) -> Void
typealias MRMediaRemoteSendCommandFunction = @convention(c) (UInt32, UnsafeMutableRawPointer?) -> Bool
typealias MRMediaRemoteSeekToPlaybackPositionFunction = @convention(c) (Double) -> Void

let MRMediaRemoteGetNowPlayingInfo = unsafeBitCast(MRMediaRemoteGetNowPlayingInfoPointer, to: MRMediaRemoteGetNowPlayingInfoFunction.self)
let MRMediaRemoteGetNowPlayingApplicationIsPlaying = unsafeBitCast(MRMediaRemoteGetNowPlayingApplicationIsPlayingPointer, to: MRMediaRemoteGetNowPlayingApplicationIsPlayingFunction.self)
let MRMediaRemoteGetNowPlayingApplicationDisplayName = unsafeBitCast(MRMediaRemoteGetNowPlayingApplicationDisplayNamePointer, to: MRMediaRemoteGetNowPlayingApplicationDisplayNameFunction.self)
let MRMediaRemoteRegisterForNowPlayingNotifications = unsafeBitCast(MRMediaRemoteRegisterForNowPlayingNotificationsPointer, to: MRMediaRemoteRegisterForNowPlayingNotificationsFunction.self)
let MRMediaRemoteSendCommand = unsafeBitCast(MRMediaRemoteSendCommandPointer, to: MRMediaRemoteSendCommandFunction.self)
let MRMediaRemoteSeekToPlaybackPosition = unsafeBitCast(MRMediaRemoteSeekToPlaybackPositionPointer, to: MRMediaRemoteSeekToPlaybackPositionFunction.self)

// Notification names
let kMRMediaRemoteNowPlayingInfoDidChangeNotification = NSNotification.Name("kMRMediaRemoteNowPlayingInfoDidChangeNotification")
let kMRMediaRemoteNowPlayingApplicationIsPlayingDidChangeNotification = NSNotification.Name("kMRMediaRemoteNowPlayingApplicationIsPlayingDidChangeNotification")
let kMRMediaRemoteNowPlayingApplicationDidChangeNotification = NSNotification.Name("kMRMediaRemoteNowPlayingApplicationDidChangeNotification")

// Info dictionary keys
let kMRMediaRemoteNowPlayingInfoAlbum = "kMRMediaRemoteNowPlayingInfoAlbum"
let kMRMediaRemoteNowPlayingInfoArtist = "kMRMediaRemoteNowPlayingInfoArtist"
let kMRMediaRemoteNowPlayingInfoTitle = "kMRMediaRemoteNowPlayingInfoTitle"
let kMRMediaRemoteNowPlayingInfoArtworkData = "kMRMediaRemoteNowPlayingInfoArtworkData"
let kMRMediaRemoteNowPlayingInfoArtworkMIMEType = "kMRMediaRemoteNowPlayingInfoArtworkMIMEType"

// Command constants from album_art.m
let kMRPlay: UInt32 = 0
let kMRPause: UInt32 = 1
let kMRTogglePlayPause: UInt32 = 2
let kMRStop: UInt32 = 3
let kMRNextTrack: UInt32 = 4
let kMRPreviousTrack: UInt32 = 5
let kMRToggleShuffle: UInt32 = 6
let kMRToggleRepeat: UInt32 = 7

// Add this additional info keys
let kMRMediaRemoteNowPlayingInfoElapsedTime = "kMRMediaRemoteNowPlayingInfoElapsedTime"
let kMRMediaRemoteNowPlayingInfoDuration = "kMRMediaRemoteNowPlayingInfoDuration"
let kMRMediaRemoteNowPlayingInfoIsMusicApp = "kMRMediaRemoteNowPlayingInfoIsMusicApp"
let kMRMediaRemoteNowPlayingInfoSupportsRewind = "kMRMediaRemoteNowPlayingInfoSupportsRewind"
let kMRMediaRemoteNowPlayingInfoSupportsNextTrack = "kMRMediaRemoteNowPlayingInfoSupportsNextTrack"
let kMRMediaRemoteNowPlayingInfoSupportsPreviousTrack = "kMRMediaRemoteNowPlayingInfoSupportsPreviousTrack"

// Add this command constant near the other command constants
let kMRChangePlaybackPosition: UInt32 = 8
let kMRSeekToPlaybackPosition: UInt32 = 46  // This is the correct command for seeking

// Add these keys
let MPNowPlayingInfoPropertyElapsedPlaybackTime = "MPNowPlayingInfoPropertyElapsedPlaybackTime"
let MPNowPlayingInfoPropertyPlaybackRate = "MPNowPlayingInfoPropertyPlaybackRate"
let MPNowPlayingInfoPropertyDefaultPlaybackRate = "MPNowPlayingInfoPropertyDefaultPlaybackRate"
let MPNowPlayingInfoPropertyPlaybackDuration = "MPNowPlayingInfoPropertyPlaybackDuration"

class MediaController: ObservableObject {
    @Published var title: String = ""
    @Published var artist: String = ""
    @Published var album: String = ""
    @Published var isPlaying: Bool = false
    @Published var artwork: NSImage?
    @Published var currentApp: String = ""
    @Published var progress: Double = 0
    
    private var progressTimer: Timer?
    
    init() {
        MRMediaRemoteRegisterForNowPlayingNotifications(DispatchQueue.main)
        
        // Get initial state
        MRMediaRemoteGetNowPlayingInfo(DispatchQueue.main) { [weak self] info in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                let elapsed = info[kMRMediaRemoteNowPlayingInfoElapsedTime] as? Double ?? 0
                let duration = info[kMRMediaRemoteNowPlayingInfoDuration] as? Double ?? 0
                self.progress = duration > 0 ? elapsed / duration : 0
            }
        }
        
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
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMediaChange),
            name: kMRMediaRemoteNowPlayingApplicationDidChangeNotification,
            object: nil
        )
        
        // Start progress update timer
        progressTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            if self?.isPlaying == true {
                self?.updateProgress()
            }
        }
        
        updateNowPlaying()
    }
    
    @objc func handlePlayingChange(_ notification: Notification) {
        MRMediaRemoteGetNowPlayingApplicationIsPlaying(DispatchQueue.main) { [weak self] playing in
            DispatchQueue.main.async {
                self?.isPlaying = playing
            }
            self?.handleMediaChange(notification)
        }
    }
    
    @objc func handleMediaChange(_ notification: Notification) {
        MRMediaRemoteGetNowPlayingApplicationDisplayName(0, DispatchQueue.main) { [weak self] name in
            guard let name = name as String? else { return }
            
            // Skip if it's Apple Music
            if name == "Music" {
                // Clear current media info if Apple Music was playing
                DispatchQueue.main.async {
                    self?.title = ""
                    self?.artist = ""
                    self?.album = ""
                    self?.artwork = nil
                    self?.isPlaying = false
                    self?.progress = 0
                }
                return
            }
            
            MRMediaRemoteGetNowPlayingInfo(DispatchQueue.main) { [weak self] info in
                guard let self = self else { return }
                
                MRMediaRemoteGetNowPlayingApplicationIsPlaying(DispatchQueue.main) { playing in
                    DispatchQueue.main.async {
                        self.isPlaying = playing
                        self.title = info[kMRMediaRemoteNowPlayingInfoTitle] as? String ?? ""
                        self.artist = info[kMRMediaRemoteNowPlayingInfoArtist] as? String ?? ""
                        self.album = info[kMRMediaRemoteNowPlayingInfoAlbum] as? String ?? ""
                        self.currentApp = name
                        
                        let elapsed = info[kMRMediaRemoteNowPlayingInfoElapsedTime] as? Double ?? 0
                        let duration = info[kMRMediaRemoteNowPlayingInfoDuration] as? Double ?? 0
                        self.progress = duration > 0 ? elapsed / duration : 0
                        
                        if let artworkData = info[kMRMediaRemoteNowPlayingInfoArtworkData] as? Data {
                            if let image = NSImage(data: artworkData) {
                                self.artwork = image
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func updateProgress() {
        MRMediaRemoteGetNowPlayingInfo(DispatchQueue.main) { [weak self] info in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                let elapsed = info[kMRMediaRemoteNowPlayingInfoElapsedTime] as? Double ?? 0
                let duration = info[kMRMediaRemoteNowPlayingInfoDuration] as? Double ?? 0
                self.progress = duration > 0 ? elapsed / duration : 0
            }
        }
    }
    
    func updateNowPlaying() {
        handleMediaChange(Notification(name: kMRMediaRemoteNowPlayingInfoDidChangeNotification))
    }
    
    func togglePlayPause() {
        // Skip if current app is Music
        if currentApp == "Music" {
            return
        }
        
        if isPlaying {
            if MRMediaRemoteSendCommand(kMRPause, nil) {
                isPlaying = false
                updateNowPlaying()
            }
        } else {
            if MRMediaRemoteSendCommand(kMRPlay, nil) {
                isPlaying = true
                updateNowPlaying()
            }
        }
    }
    
    func next() {
        if currentApp != "Music" {
            if MRMediaRemoteSendCommand(kMRNextTrack, nil) {
                updateNowPlaying()
            }
        }
    }
    
    func previous() {
        if currentApp != "Music" {
            if MRMediaRemoteSendCommand(kMRPreviousTrack, nil) {
                updateNowPlaying()
            }
        }
    }
    
    func seekToPosition(_ progress: Double) {
        MRMediaRemoteGetNowPlayingInfo(DispatchQueue.main) { [weak self] info in
            guard let self = self,
                  let duration = info[kMRMediaRemoteNowPlayingInfoDuration] as? Double else {
                return
            }
            
            let seekTime = progress * duration
            
            // Create a dictionary with the seek time
            let options: [String: Any] = ["kMRMediaRemoteOptionPlaybackPosition": seekTime]
            
            // Convert to CFDictionary
            let cfOptions = options as CFDictionary
            let optionsPointer = Unmanaged.passUnretained(cfOptions).toOpaque()
            
            // Send seek command with options
            if MRMediaRemoteSendCommand(kMRChangePlaybackPosition, optionsPointer) {
                // Update UI immediately for smooth feedback
                DispatchQueue.main.async {
                    self.progress = progress
                }
                
                // Update actual position after a small delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.updateNowPlaying()
                }
            }
        }
    }
}

struct DraggableProgressBar: View {
    @ObservedObject var mediaController: MediaController
    let geometry: GeometryProxy
    @GestureState private var isDragging = false
    @State private var dragProgress: Double?
    
    var body: some View {
        ZStack(alignment: .leading) {
            // Background track
            Rectangle()
                .fill(.white.opacity(0.2))
                .frame(height: 2)
            
            // Progress bar
            Rectangle()
                .fill(.white)
                .frame(width: geometry.size.width * CGFloat(dragProgress ?? mediaController.progress), height: 2)
            
            // Progress dot indicator
            Circle()
                .fill(.white)
                .frame(width: 8, height: 8)
                .offset(x: (geometry.size.width * CGFloat(dragProgress ?? mediaController.progress)) - 4)
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .updating($isDragging) { value, state, _ in
                    state = true
                }
                .onChanged { value in
                    let progress = min(max(value.location.x / geometry.size.width, 0), 1)
                    dragProgress = Double(progress)
                }
                .onEnded { value in
                    let progress = min(max(value.location.x / geometry.size.width, 0), 1)
                    dragProgress = nil
                    mediaController.seekToPosition(progress)
                }
        )
    }
}

struct ContentView: View {
    @StateObject private var mediaController = MediaController()
    
    var body: some View {
        ZStack {
            // Album artwork background
            if let artwork = mediaController.artwork {
                GeometryReader { geometry in
                    Image(nsImage: artwork)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                        .blur(radius: 2)
                        .overlay {
                            LinearGradient(
                                colors: [
                                    .black.opacity(0.4),
                                    .black.opacity(0.2)
                                ],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        }
                }
            }
            
            VStack(alignment: .leading, spacing: 16) {
                // Top row with waveform icon
                HStack {
                    Image(systemName: "waveform")
                        .foregroundColor(.white)
                        .font(.system(size: 12))
                        .symbolEffect(.bounce, options: .repeating, value: mediaController.isPlaying)
                        .opacity(mediaController.isPlaying ? 1.0 : 0.5)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 16)
                
                // Media info and play/pause on the right
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(mediaController.title)
                            .foregroundColor(.white)
                            .font(.system(size: 10, weight: .semibold))
                            .lineLimit(1)
                        
                        Text(mediaController.artist)
                            .foregroundColor(.white.opacity(0.7))
                            .font(.system(size: 10))
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    Button(action: { mediaController.togglePlayPause() }) {
                        Image(systemName: mediaController.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 24))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal)
                
                // Previous/Next controls at the bottom
                HStack {
                    Button(action: { mediaController.previous() }) {
                        Image(systemName: "backward.end")
                            .foregroundColor(.white)
                            .font(.system(size: 11))
                    }
                    .buttonStyle(.plain)
                    
                    // Progress bar with adjusted padding
                    GeometryReader { geometry in
                        DraggableProgressBar(mediaController: mediaController, geometry: geometry)
                    }
                    .frame(height: 8)
                    .padding(.horizontal, 0)  // Removed horizontal padding
                    
                    Button(action: { mediaController.next() }) {
                        Image(systemName: "forward.end")
                            .foregroundColor(.white)
                            .font(.system(size: 11))
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal)  // Match the title section padding
                .padding(.bottom, 12)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .cornerRadius(12)
    }
}

// Add this extension to help with bundle identifier lookup
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

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
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
        sketchyTask.arguments = ["sketchybar", "--query", "item_35"]
        
        let sketchyPipe = Pipe()
        sketchyTask.standardOutput = sketchyPipe
        sketchyTask.launch()
        
        let sketchyData = sketchyPipe.fileHandleForReading.readDataToEndOfFile()
        sketchyTask.waitUntilExit()
        
        // Parse responses and position window
        if let yabaiInfo = try? JSONSerialization.jsonObject(with: yabaiData, options: []) as? [String: Any],
           let displayIndex = yabaiInfo["index"] as? Int,
           let frame = yabaiInfo["frame"] as? [String: Double],
           let itemInfo = try? JSONSerialization.jsonObject(with: sketchyData, options: []) as? [String: Any],
           let boundingRects = itemInfo["bounding_rects"] as? [String: Any],
           let displayRect = boundingRects["display-\(displayIndex)"] as? [String: Any],
           let origin = displayRect["origin"] as? [Double] {
            
            let x = origin[0]
            let displayWidth = frame["w"] ?? 0
            let displayX = frame["x"] ?? 0
            let windowWidth: CGFloat = 320
            
            var windowX = x - (windowWidth / 8)
            
            let rightEdge = displayX + displayWidth
            let leftEdge = displayX
            
            if windowX + windowWidth > rightEdge {
                windowX = rightEdge - windowWidth - 10
            } else if windowX < leftEdge {
                windowX = leftEdge + 10
            }
            
            window = NSWindow(
                contentRect: NSRect(
                    x: windowX,
                    y: 1305,
                    width: windowWidth,
                    height: 80
                ),
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )
        }
        
        // Configure window
        window?.contentView = NSHostingView(rootView: contentView)
        window?.backgroundColor = .clear
        window?.isMovableByWindowBackground = false  // Disable window movement
        window?.level = .floating
        window?.hasShadow = false
        
        // Add corner radius to window
        if let contentView = window?.contentView {
            contentView.wantsLayer = true
            contentView.layer?.cornerRadius = 16
            contentView.layer?.masksToBounds = true
            
            // Also set the background color on the layer for proper transparency
            contentView.layer?.backgroundColor = NSColor.clear.cgColor
        }
        
        window?.makeKeyAndOrderFront(nil)
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()