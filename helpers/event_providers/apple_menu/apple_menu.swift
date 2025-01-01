import Cocoa
import SwiftUI

struct Card<Content: View>: View {
    let content: Content
    var backgroundColor: Color = Color(red: 17/255.0, green: 17/255.0, blue: 27/255.0)
    var padding: EdgeInsets = EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
    var cornerRadius: CGFloat = 20
    var borderWidth: CGFloat = 1
    var borderColor: Color = Color(red: 18/255.0, green: 18/255.0, blue: 28/255.0)
    var backgroundImage: NSImage? = nil
    var blurRadius: CGFloat = 10
    var overlayOpacity: Double = 0.5
    var width: CGFloat? = nil
    var height: CGFloat? = nil
    
    init(
        backgroundColor: Color = Color(red: 17/255.0, green: 17/255.0, blue: 27/255.0),
        padding: EdgeInsets = EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16),
        cornerRadius: CGFloat = 20,
        borderWidth: CGFloat = 1,
        borderColor: Color = Color(red: 18/255.0, green: 18/255.0, blue: 28/255.0),
        backgroundImage: NSImage? = nil,
        blurRadius: CGFloat = 10,
        overlayOpacity: Double = 0.5,
        width: CGFloat? = nil,
        height: CGFloat? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.backgroundColor = backgroundColor
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.borderWidth = borderWidth
        self.borderColor = borderColor
        self.backgroundImage = backgroundImage
        self.blurRadius = blurRadius
        self.overlayOpacity = overlayOpacity
        self.width = width
        self.height = height
    }
    
    var body: some View {
        ZStack {
            if let image = backgroundImage {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .blur(radius: blurRadius)
                    .overlay(Color.black.opacity(overlayOpacity))
            } else {
                backgroundColor
            }
            
            content
                .padding(padding)
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(borderColor, lineWidth: borderWidth)
        )
    }
}

struct TimerCard: View {
    @State private var timeRemaining: TimeInterval
    @State private var isRunning: Bool
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    init() {
        let defaults = UserDefaults.standard
        let targetDate = defaults.object(forKey: "timerTargetDate") as? Date
        let isRunning = defaults.bool(forKey: "timerIsRunning")
        
        if let targetDate = targetDate, isRunning {
            // Calculate remaining time from saved target date
            let remaining = targetDate.timeIntervalSinceNow
            _timeRemaining = State(initialValue: remaining > 0 ? remaining : 0)
            _isRunning = State(initialValue: remaining > 0)
        } else {
            // Either timer wasn't running or no target date was saved
            _timeRemaining = State(initialValue: defaults.double(forKey: "timerDuration"))
            if _timeRemaining.wrappedValue == 0 {
                _timeRemaining = State(initialValue: 25 * 60) // Default 25 minutes
            }
            _isRunning = State(initialValue: false)
        }
    }
    
    var body: some View {
        Card {
            VStack(spacing: 24) {
                // Timer Display
                Text(timeString(from: timeRemaining))
                    .font(.system(size: 56, weight: .medium, design: .rounded))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .foregroundColor(.white)
                
                // Controls
                HStack(spacing: 16) {
                    // Minus Button
                    Button(action: {
                        timeRemaining = max(0, timeRemaining - 60)
                        saveTimerState()
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    }
                    .frame(width: 32, height: 32)
                    .buttonStyle(PlainButtonStyle())
                    
                    // Play/Pause Button
                    Button(action: toggleTimer) {
                        Image(systemName: isRunning ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    }
                    .frame(width: 32, height: 32)
                    .buttonStyle(PlainButtonStyle())
                    
                    // Reset Button
                    Button(action: resetTimer) {
                        Image(systemName: "arrow.counterclockwise.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    }
                    .frame(width: 32, height: 32)
                    .buttonStyle(PlainButtonStyle())
                    
                    // Plus Button
                    Button(action: {
                        timeRemaining += 60
                        saveTimerState()
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    }
                    .frame(width: 32, height: 32)
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .onReceive(timer) { _ in
            if isRunning && timeRemaining > 0 {
                timeRemaining -= 1
                saveTimerState()
                
                // Show notification when timer reaches 0
                if timeRemaining == 0 {
                    sendNotification()
                    isRunning = false
                    saveTimerState()
                }
            }
        }
    }
    
    private func timeString(from timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func toggleTimer() {
        isRunning.toggle()
        saveTimerState()
    }
    
    private func resetTimer() {
        isRunning = false
        timeRemaining = 25 * 60
        saveTimerState()
    }
    
    private func saveTimerState() {
        let defaults = UserDefaults.standard
        defaults.set(timeRemaining, forKey: "timerDuration")
        defaults.set(isRunning, forKey: "timerIsRunning")
        
        // Save target end time if timer is running
        if isRunning {
            let targetDate = Date().addingTimeInterval(timeRemaining)
            defaults.set(targetDate, forKey: "timerTargetDate")
        } else {
            defaults.removeObject(forKey: "timerTargetDate")
        }
    }
    
    private func sendNotification() {
        let notification = NSUserNotification()
        notification.title = "Timer Complete"
        notification.informativeText = "Your timer has finished!"
        notification.soundName = NSUserNotificationDefaultSoundName
        
        NSUserNotificationCenter.default.deliver(notification)
    }
}

struct ProfileCard: View {
    let username: String
    let uptime: String
    
    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 8) {
                Text(username)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white)
                Text(uptime)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
        }
    }
}

struct QuoteCard: View {
    let quote: String
    let author: String
    
    var body: some View {
        Card {
            VStack(alignment: .center, spacing: 12) {
                Text(quote)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                    .lineSpacing(4)
                    .multilineTextAlignment(.center)
                
                Text(author)
                    .font(.system(size: 16))
                    .foregroundColor(Color(red: 1, green: 0.7, blue: 1.0)) // Light purple color
            }
            .frame(maxWidth: .infinity)
        }
    }
}

struct Task: Identifiable, Codable {
    let id: UUID
    var title: String
    var isCompleted: Bool
    
    init(id: UUID = UUID(), title: String, isCompleted: Bool = false) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
    }
}

struct TaskCard: View {
    @State private var selectedTab = 0
    @State private var tasks: [Task] = []
    @State private var newTaskTitle = ""
    @State private var isAddingTask = false
    
    init() {
        // Load saved tasks from UserDefaults
        if let savedTasksData = UserDefaults.standard.data(forKey: "savedTasks"),
           let decodedTasks = try? JSONDecoder().decode([Task].self, from: savedTasksData) {
            _tasks = State(initialValue: decodedTasks)
        }
    }
    
    var activeTasks: [Task] {
        tasks.filter { !$0.isCompleted }
    }
    
    var completedTasks: [Task] {
        tasks.filter { $0.isCompleted }
    }
    
    private func saveTasks() {
        if let encodedTasks = try? JSONEncoder().encode(tasks) {
            UserDefaults.standard.set(encodedTasks, forKey: "savedTasks")
        }
    }
    
    private func addNewTask() {
        if !newTaskTitle.isEmpty {
            tasks.append(Task(title: newTaskTitle))
            saveTasks()
            newTaskTitle = ""
            isAddingTask = false
        }
    }
    
    var body: some View {
        Card {
            VStack(spacing: 12) {
                // Title and Add Button
                HStack {
                    Text("To-Dos")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: {
                        isAddingTask.toggle()
                        if !isAddingTask {
                            newTaskTitle = ""
                        }
                    }) {
                        Image(systemName: isAddingTask ? "xmark" : "plus")
                            .foregroundColor(isAddingTask ? .red : .blue)
                            .font(.system(size: 16, weight: .bold))
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: {
                        tasks.removeAll(where: { $0.isCompleted })
                        saveTasks()
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                            .font(.system(size: 16, weight: .bold))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // Tabs
                HStack {
                    ForEach(["Active", "Completed"], id: \.self) { tab in
                        Button(action: {
                            selectedTab = tab == "Active" ? 0 : 1
                            if isAddingTask {
                                isAddingTask = false
                                newTaskTitle = ""
                            }
                        }) {
                            Text(tab)
                                .foregroundColor(selectedTab == (tab == "Active" ? 0 : 1) ? .white : .gray)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .background(selectedTab == (tab == "Active" ? 0 : 1) ? Color.blue.opacity(0.3) : Color.clear)
                                .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    Spacer()
                }
                
                // Input field (now under tabs)
                if isAddingTask && selectedTab == 0 {
                    HStack {
                        TextField("Enter task", text: $newTaskTitle)
                            .textFieldStyle(PlainTextFieldStyle())
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(8)
                            .onSubmit {
                                addNewTask()
                            }
                        
                        Button(action: addNewTask) {
                            Image(systemName: "checkmark")
                                .foregroundColor(.green)
                                .font(.system(size: 16, weight: .bold))
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(newTaskTitle.isEmpty)
                    }
                    .padding(.vertical, 4)
                }
                
                // Task List
                ScrollView {
                    VStack(spacing: 8) {
                        let displayTasks = selectedTab == 0 ? activeTasks : completedTasks
                        if displayTasks.isEmpty {
                            Text(selectedTab == 0 ? "No Active Tasks" : "No Completed Tasks")
                                .foregroundColor(.gray)
                                .padding(.top, 20)
                        } else {
                            ForEach(displayTasks) { task in
                                HStack {
                                    Button(action: {
                                        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
                                            tasks[index].isCompleted.toggle()
                                            saveTasks()
                                        }
                                    }) {
                                        Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(task.isCompleted ? .green : .gray)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    
                                    Text(task.title)
                                        .foregroundColor(.white)
                                        .strikethrough(task.isCompleted)
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        tasks.removeAll(where: { $0.id == task.id })
                                        saveTasks()
                                    }) {
                                        Image(systemName: "trash.fill")
                                            .foregroundColor(.red.opacity(0.7))
                                            .font(.system(size: 14))
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
                .frame(maxHeight: 200)
            }
            .padding()
        }
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
            let windowWidth: CGFloat = 1500
            let windowHeight: CGFloat = 1000
            
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
            
            window?.level = .floating
            window?.backgroundColor = NSColor(red: 0x0D/255.0, green: 0x11/255.0, blue: 0x16/255.0, alpha: 1.0)
            
            // Add corner radius to the window itself
            window?.hasShadow = false
            if let windowFrame = window?.contentView?.superview {
                windowFrame.wantsLayer = true
                windowFrame.layer?.cornerRadius = 40
                windowFrame.layer?.masksToBounds = true
            }
            
            window?.contentView = NSHostingView(rootView: contentView)
            window?.makeKeyAndOrderFront(nil)
            
            if let contentView = window?.contentView {
                contentView.wantsLayer = true
                contentView.layer?.cornerRadius = 40
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

struct ContentView: View {
    let username = NSUserName()
    let uptime = formatUptime(ProcessInfo.processInfo.systemUptime)
    
    var body: some View {
        ZStack {
            // Background with color
            Color(red: 0x0D/255.0, green: 0x11/255.0, blue: 0x16/255.0)
                .edgesIgnoringSafeArea(.all)
            
            // Main content
            GeometryReader { geometry in
                HStack(spacing: 20) {
                    // Left Column
                    VStack(spacing: 20) {
                        ProfileCard(username: username, uptime: uptime)
                        TimerCard()
                        QuoteCard(
                            quote: "All our dreams can come true if we have the courage to pursue them",
                            author: "Walt Disney"
                        )
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Middle Column
                    VStack(spacing: 20) {
                        TaskCard()
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Right Column
                    VStack(spacing: 20) {
                        Card {
                            Text("Right Column")
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(20)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 40))
    }
}

func formatUptime(_ seconds: TimeInterval) -> String {
    let days = Int(seconds / 86400)
    let hours = Int((seconds.truncatingRemainder(dividingBy: 86400)) / 3600)
    let minutes = Int((seconds.truncatingRemainder(dividingBy: 3600)) / 60)
    
    var components: [String] = []
    if days > 0 { components.append("\(days)d") }
    if hours > 0 { components.append("\(hours)h") }
    if minutes > 0 { components.append("\(minutes)m") }
    
    return "Uptime: " + components.joined(separator: " ")
}

// Initialize and run the application
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()