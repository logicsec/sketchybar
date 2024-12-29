import SwiftUI
import MediaPlayer
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
        print("Initializing MediaController...")
        
        // Add this at the start of init()
        NSEvent.addLocalMonitorForEvents(matching: .systemDefined) { event in
            if event.subtype.rawValue == 8 { // Remote control event
                print("Got remote control event")
                return nil
            }
            return event
        }
        
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.playCommand.addTarget { event in
            print("Play command received")
            return .success
        }
        commandCenter.pauseCommand.addTarget { event in
            print("Pause command received")
            return .success
        }
        
        print("Registering for notifications...")
        MRMediaRemoteRegisterForNowPlayingNotifications(DispatchQueue.main)

        // Get initial playback state and time
        print("Getting initial playback info...")
        MRMediaRemoteGetNowPlayingInfo(DispatchQueue.main) { [weak self] info in
            print("Initial media info: \(info)")
            DispatchQueue.main.async {
                if let elapsed = info["kMRMediaRemoteNowPlayingInfoElapsedTime"] as? Double {
                    print("Initial elapsed time: \(elapsed)")
                    self?.initialTime = elapsed
                    self?.elapsedTime = elapsed
                    
                    // If we're currently playing, set up the timer with the correct initial time
                    if self?.isPlaying == true {
                        self?.playbackStartTime = Date()
                        self?.startTimer()
                    }
                }
                
                if let total = info["kMRMediaRemoteNowPlayingInfoDuration"] as? Double {
                    print("Initial duration: \(total)")
                    self?.duration = total
                }
            }
        }

        print("Getting initial playing state...")
        MRMediaRemoteGetNowPlayingApplicationIsPlaying(DispatchQueue.main) { [weak self] playing in
            print("Initial playing state: \(playing)")
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
        print("Adding notification observers...")
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

        print("Initial update of now playing...")
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

    @objc private func handleMediaChange() {
        updateNowPlaying()
    }
    
    @objc private func handlePlayingChange() {
        MRMediaRemoteGetNowPlayingApplicationIsPlaying(DispatchQueue.main) { [weak self] playing in
            DispatchQueue.main.async {
                self?.isPlaying = playing
                if playing {
                    self?.playbackStartTime = Date()
                    self?.startTimer()
                } else {
                    self?.stopTimer()
                }
            }
        }
    }
    
    private func updateNowPlaying() {
        print("Updating now playing info...")
        MRMediaRemoteGetNowPlayingInfo(DispatchQueue.main) { [weak self] info in
            print("Got media info: \(info)")
            DispatchQueue.main.async {
                var title = (info[kMRMediaRemoteNowPlayingInfoTitle] as? String) ?? ""
                var artist = (info[kMRMediaRemoteNowPlayingInfoArtist] as? String) ?? ""
                var album = (info[kMRMediaRemoteNowPlayingInfoAlbum] as? String) ?? ""
                
                // For browsers, try to get more info
                if self?.currentApp == "Arc" || self?.currentApp == "Safari" || self?.currentApp == "Google Chrome" {
                    if let bundleID = info["kMRMediaRemoteNowPlayingInfoBundleIdentifier"] as? String {
                        print("Bundle ID: \(bundleID)")
                    }
                    
                    // Try to get tab title for browsers
                    if let contentItem = info["kMRMediaRemoteNowPlayingInfoContentItemIdentifier"] as? String {
                        print("Content item: \(contentItem)")
                        // If we have a content item but no title, this is likely a video
                        if title.isEmpty {
                            title = "Media Playing"
                            artist = self?.currentApp ?? ""
                        }
                    }
                }
                
                self?.title = title
                self?.artist = artist
                self?.album = album
                
                print("Title: \(title)")
                print("Artist: \(artist)")
                print("Album: \(album)")
                
                // Handle artwork
                if let artworkData = info[kMRMediaRemoteNowPlayingInfoArtworkData] as? Data {
                    print("Got artwork data")
                    self?.artwork = NSImage(data: artworkData)
                    if let artwork = self?.artwork {
                        print("Artwork loaded successfully")
                        self?.lastArtwork = artwork
                    }
                } else {
                    print("No artwork data available")
                }
                
                // Update timing information
                if let elapsed = info[kMRMediaRemoteNowPlayingInfoElapsedTime] as? Double {
                    print("Elapsed time: \(elapsed)")
                    self?.initialTime = elapsed
                    self?.elapsedTime = elapsed
                    if self?.isPlaying == true {
                        self?.playbackStartTime = Date()
                        self?.startTimer()
                    }
                }
                
                if let total = info[kMRMediaRemoteNowPlayingInfoDuration] as? Double {
                    print("Total duration: \(total)")
                    self?.duration = total
                }
            }
        }
        
        // Get current app name
        MRMediaRemoteGetNowPlayingApplicationDisplayName(0, DispatchQueue.main) { [weak self] name in
            print("Current app: \(name)")
            DispatchQueue.main.async {
                self?.currentApp = name as String
            }
        }
        
        // Check playing state
        MRMediaRemoteGetNowPlayingApplicationIsPlaying(DispatchQueue.main) { [weak self] playing in
            print("Is playing: \(playing)")
            DispatchQueue.main.async {
                self?.isPlaying = playing
                if playing {
                    self?.startTimer()
                } else {
                    self?.stopTimer()
                }
            }
        }
    }
    
    func next() {
        _ = MRMediaRemoteSendCommand(kMRNextTrack, nil)
    }
    
    func previous() {
        _ = MRMediaRemoteSendCommand(kMRPreviousTrack, nil)
    }
    
    deinit {
        progressTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }

    func resetPlaybackTimer() {
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

struct MediaControllerView: View {
    @StateObject private var controller = MediaController()
    
    var body: some View {
        Card(padding: 0, backgroundColor: Color(NSColor.windowBackgroundColor).opacity(0.95)) {
            HStack(spacing: 0) {
                // Artwork
                Group {
                    if let artwork = controller.artwork {
                        Image(nsImage: artwork)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 80, height: 80)
                            .clipped()
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 80, height: 80)
                            .overlay {
                                Image(systemName: "music.note")
                                    .font(.system(size: 30))
                                    .foregroundColor(.gray)
                            }
                    }
                }
                
                // Title and Artist + Controls
                VStack(alignment: .leading, spacing: 4) {
                    // Title and Artist
                    VStack(alignment: .leading, spacing: 2) {
                        Text(controller.title.isEmpty ? "Not Playing" : controller.title)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        if !controller.artist.isEmpty {
                            Text(controller.artist)
                                .font(.system(size: 13))
                                .foregroundColor(.gray)
                                .lineLimit(1)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    
                    Spacer()
                    
                    // Controls
                    if !controller.title.isEmpty {
                        HStack(spacing: 24) {
                            Button(action: controller.previous) {
                                Image(systemName: "backward.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                            }
                            .buttonStyle(.plain)
                            
                            Button(action: controller.togglePlayPause) {
                                Image(systemName: controller.isPlaying ? "pause.fill" : "play.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white)
                            }
                            .buttonStyle(.plain)
                            
                            Button(action: controller.next) {
                                Image(systemName: "forward.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                            }
                            .buttonStyle(.plain)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 12)
                    }
                }
            }
            .frame(height: 80)
        }
        .cornerRadius(8)
    }
}

#Preview {
    MediaControllerView()
        .frame(width: 300)
        .padding()
        .background(Color.black)
}
