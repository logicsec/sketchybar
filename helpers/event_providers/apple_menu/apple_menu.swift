import Cocoa
import SwiftUI
import Foundation

struct Colors {
    static func parseHexFromLua(filePath: String, colorName: String, inTable: String? = nil) -> NSColor? {
        do {
            let content = try String(contentsOfFile: filePath, encoding: .utf8)
            // Look for patterns like: colorName = 0xAARRGGBB, or table.colorName = 0xAARRGGBB,
            let pattern = inTable != nil ? 
                "\(inTable)\\.\\s*\(colorName)\\s*=\\s*0x([0-9a-fA-F]+)" :
                "\(colorName)\\s*=\\s*0x([0-9a-fA-F]+)"
            let regex = try NSRegularExpression(pattern: pattern)
            let range = NSRange(content.startIndex..<content.endIndex, in: content)
            
            if let match = regex.firstMatch(in: content, range: range),
               let hexRange = Range(match.range(at: 1), in: content) {
                let hexString = String(content[hexRange])
                return NSColor(hex: hexString)
            }
        } catch {
            print("Error reading Lua file: \(error)")
        }
        return nil
    }
    
    static let configPath = "\(NSHomeDirectory())/.config/sketchybar"
    static var panelBackground = parseHexFromLua(filePath: "\(configPath)/bar.lua", colorName: "bg", inTable: "bar") ?? NSColor(hex: "0D1116")!
    static var accent = parseHexFromLua(filePath: "\(configPath)/colors.lua", colorName: "blue") ?? NSColor(hex: "88C0D0")!
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
        case 8: // ARGB or RGBA
            if int > 0xFFFFFFFF { // RGBA
                (r, g, b, a) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
            } else { // ARGB
                (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
            }
        default:
            return nil
        }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }
}

struct VisualEffectBlur: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .hudWindow
    var blendingMode: NSVisualEffectView.BlendingMode = .behindWindow

    func makeNSView(context: Context) -> NSVisualEffectView {
        let visualEffectView = NSVisualEffectView()
        visualEffectView.material = material
        visualEffectView.blendingMode = blendingMode
        visualEffectView.state = .active
        return visualEffectView
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow?
    var currentPanel: PanelType = .menu
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("Application did finish launching")
        
        // Get aerospace monitor info
        let aerospacePipe = Pipe()
        let aerospaceTask = Process()
        aerospaceTask.launchPath = "/usr/bin/env"
        aerospaceTask.arguments = ["aerospace", "list-monitors", "--format", "{\"id\":%{monitor-id}}"]
        aerospaceTask.standardOutput = aerospacePipe
        
        // Get sketchybar item position
        let sketchyPipe = Pipe()
        let sketchyTask = Process()
        sketchyTask.launchPath = "/usr/bin/env"
        sketchyTask.arguments = ["sketchybar", "--query", "apple.logo"]
        sketchyTask.standardOutput = sketchyPipe
        
        do {
            print("Starting tasks...")
            aerospaceTask.launch()
            sketchyTask.launch()
            
            let aerospaceData = aerospacePipe.fileHandleForReading.readDataToEndOfFile()
            let sketchyData = sketchyPipe.fileHandleForReading.readDataToEndOfFile()
            
            print("Got task data")
            print("Aerospace data: \(String(data: aerospaceData, encoding: .utf8) ?? "nil")")
            print("Sketchy data: \(String(data: sketchyData, encoding: .utf8) ?? "nil")")
            
            // Parse aerospace output to get monitor ID
            let aerospaceStr = String(data: aerospaceData, encoding: .utf8) ?? ""
            let monitorLines = aerospaceStr.components(separatedBy: .newlines).filter { !$0.isEmpty }
            
            guard let firstMonitor = monitorLines.first,
                  let monitorData = firstMonitor.data(using: .utf8),
                  let monitorInfo = try? JSONSerialization.jsonObject(with: monitorData, options: []) as? [String: Any],
                  let monitorId = monitorInfo["id"] as? Int,
                  let itemInfo = try? JSONSerialization.jsonObject(with: sketchyData, options: []) as? [String: Any],
                  let boundingRects = itemInfo["bounding_rects"] as? [String: Any],
                  let displayRect = boundingRects["display-\(monitorId)"] as? [String: Any],
                  let _ = displayRect["origin"] as? [Double] else {
                print("Failed to parse monitor or sketchybar info")
                return
            }
            
            print("Got monitor ID: \(monitorId)")
            
            // Get screen information from NSScreen
            let screens = NSScreen.screens
            guard monitorId - 1 >= 0 && monitorId - 1 < screens.count,
                  let screen = screens[safe: monitorId - 1] else {
                print("Invalid monitor ID or screen not found")
                return
            }
            
            print("Got screen: \(screen)")
            
            let frame = screen.frame
            let displayX = frame.origin.x
            let displayWidth = frame.width
            let displayHeight = frame.height
            let windowWidth: CGFloat = displayWidth * 0.20  // 20% of screen width
            let windowHeight: CGFloat = displayHeight / 1.7
            
            // Position at top edge of screen, accounting for app_offset
            let windowY = displayHeight - windowHeight - Settings.appOffsetY
            let windowX = displayX + Settings.appOffsetX
            
            print("Window dimensions: x=\(windowX), y=\(windowY), width=\(windowWidth), height=\(windowHeight)")
            
            window = NSWindow(
                contentRect: NSRect(
                    x: windowX,
                    y: windowY,
                    width: windowWidth,
                    height: windowHeight
                ),
                styleMask: [],
                backing: .buffered,
                defer: false
            )
            
            // Force the window size
            window?.setContentSize(NSSize(width: windowWidth, height: windowHeight))
            
            // Add size constraint
            if let window = window {
                window.maxSize = NSSize(width: windowWidth, height: windowHeight)
                window.minSize = NSSize(width: windowWidth, height: windowHeight)
            }
            
            window?.backgroundColor = .clear
            window?.isOpaque = false
            window?.hasShadow = false
            window?.level = .floating
            window?.collectionBehavior = [.transient, .ignoresCycle]
            
            if let contentView = window?.contentView {
                contentView.wantsLayer = true
                contentView.layer?.cornerRadius = Settings.cornerRadius
                contentView.layer?.masksToBounds = true
                contentView.layer?.backgroundColor = NSColor.clear.cgColor
                contentView.layer?.opacity = 0.0
                
                // Set initial position for slide animation
                let initialTranslation = -window!.frame.width
                contentView.layer?.transform = CATransform3DMakeTranslation(initialTranslation, 0, 0)
            }
            
            print("Setting up content view...")
            window?.contentView = NSHostingView(rootView: ContentView())
            window?.makeKeyAndOrderFront(nil)
            
            // Slide animation
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.2
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
            
            print("Window setup complete")
            
        } catch {
            print("Error setting up window: \(error)")
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

// Add Array extension for safe subscript
extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

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

struct ContentView: View {
    var body: some View {
        VStack(spacing: 16) {
            TimeView()
            UptimeView()
            CalendarView()
            MediaControllerView()
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(Colors.panelBackground))
    }
}

// Add CALayer extension for animations
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

@main
struct AppleMenuApp {
    static func main() {
        // Load settings when app starts
        Settings.loadSettings()
        
        let app = NSApplication.shared
        app.setActivationPolicy(.accessory)
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }
}