import Cocoa
import SwiftUI
import UserNotifications

struct ContentView: View {
    @State private var username = "paulknight"
    @State private var uptime = "up 13 hours"
    
    var body: some View {
        ZStack {
            // Background color - darker theme
            Color(red: 17/255.0, green: 17/255.0, blue: 27/255.0)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 16) {
                // Top row with profile and time
                HStack {
                    // Left side - Profile
                    HStack(spacing: 8) {
                        Image(systemName: "person.circle.fill")
                            .foregroundColor(.gray)
                        Text(username)
                            .foregroundColor(.gray)
                            .font(.system(size: 14))
                        Text("|")
                            .foregroundColor(.gray)
                            .font(.system(size: 14))
                        Text(uptime)
                            .foregroundColor(.gray)
                            .font(.system(size: 14))
                    }
                    
                    Spacer()
                    
                    // Right side - Time
                    TimeDisplay()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                
                // Main content
                HStack(spacing: 12) {
                    // Left section
                    CalendarSection()
                        .frame(maxWidth: .infinity)
                    
                    // Right section
                    AgendaSection()
                        .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 16)
            }
            .padding(.vertical, 16)
        }
        .frame(width: 800, height: 500)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow?
    var eventMonitor: Any?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create the SwiftUI view that provides the window contents
        let contentView = ContentView()
        
        // Get the main screen's frame
        if let screen = NSScreen.main {
            let screenFrame = screen.frame
            let windowWidth: CGFloat = 800
            let windowHeight: CGFloat = 500
            
            // Calculate center position
            let x = (screenFrame.width - windowWidth) / 2
            let y = (screenFrame.height - windowHeight) / 2
            
            // Create the window and set the content view
            window = NSWindow(
                contentRect: NSRect(x: x, y: y, width: windowWidth, height: windowHeight),
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )
            
            window?.isReleasedWhenClosed = false
            window?.level = .floating
            window?.backgroundColor = NSColor(red: 0x0D/255.0, green: 0x11/255.0, blue: 0x16/255.0, alpha: 1.0)
            
            // Add corner radius to the window itself
            window?.hasShadow = false
            if let windowFrame = window?.contentView?.superview {
                windowFrame.wantsLayer = true
                windowFrame.layer?.cornerRadius = 20
                windowFrame.layer?.masksToBounds = true
            }
            
            window?.contentView = NSHostingView(rootView: contentView)
            window?.makeKeyAndOrderFront(nil)
            
            if let contentView = window?.contentView {
                contentView.wantsLayer = true
                contentView.layer?.cornerRadius = 20
                contentView.layer?.masksToBounds = true
            }
            
            // Set up event monitor for clicks outside the window
            eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
                if let window = self?.window {
                    let windowFrame = window.frame
                    let clickLocation = NSPoint(x: event.locationInWindow.x, y: screen.frame.height - event.locationInWindow.y)
                    
                    if !NSPointInRect(clickLocation, windowFrame) {
                        NSApp.terminate(nil)
                    }
                }
            }
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Clean up event monitor
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}

// Initialize and run the application
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()