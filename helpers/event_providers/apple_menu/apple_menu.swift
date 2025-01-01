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

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .foregroundColor(isSelected ? .white : .gray)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(isSelected ? Color.blue.opacity(0.3) : Color.clear)
                .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TaskRow: View {
    let task: Task
    let onToggle: (Task) -> Void
    let onDelete: (Task) -> Void
    
    var body: some View {
        HStack {
            Button(action: {
                var updatedTask = task
                updatedTask.isCompleted.toggle()
                onToggle(updatedTask)
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
                onDelete(task)
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

struct TaskCard: View {
    @State private var tasks: [Task] = []
    @State private var selectedTab = 0
    @State private var showingInput = false
    @State private var taskInputView: TaskInputView?
    
    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                // Title and Add Button
                HStack {
                    Text("To-Dos")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: {
                        showingInput.toggle()
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(.white)
                            .frame(width: 30, height: 30)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: {
                        UserDefaults.standard.removeObject(forKey: "savedTasks")
                        tasks.removeAll()
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.white)
                            .frame(width: 30, height: 30)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // Tab Buttons
                HStack(spacing: 20) {
                    TabButton(title: "Active", isSelected: selectedTab == 0) {
                        selectedTab = 0
                    }
                    
                    TabButton(title: "Completed", isSelected: selectedTab == 1) {
                        selectedTab = 1
                    }
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
                                TaskRow(task: task, onToggle: { updatedTask in
                                    if let index = tasks.firstIndex(where: { $0.id == updatedTask.id }) {
                                        tasks[index] = updatedTask
                                        saveTasks()
                                    }
                                }, onDelete: { taskToDelete in
                                    if let index = tasks.firstIndex(where: { $0.id == taskToDelete.id }) {
                                        tasks.remove(at: index)
                                        saveTasks()
                                    }
                                })
                            }
                        }
                    }
                }
                .frame(maxHeight: .infinity, alignment: .top)
            }
            .padding()
        }
        .onAppear {
            if let savedTasksData = UserDefaults.standard.data(forKey: "savedTasks"),
               let decodedTasks = try? JSONDecoder().decode([Task].self, from: savedTasksData) {
                tasks = decodedTasks
            }
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
}

struct TimeCard: View {
    @State private var currentTime = Date()
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, dd MMMM"
        return formatter
    }()
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
    
    var body: some View {
        Card {
            VStack(spacing: 10) {
                Text(timeFormatter.string(from: currentTime))
                    .font(.system(size: 60, weight: .medium))
                    .foregroundColor(.white)
                
                Text(dateFormatter.string(from: currentTime))
                    .font(.system(size: 20))
                    .foregroundColor(.gray)
            }
            .padding()
        }
        .onReceive(timer) { input in
            currentTime = input
        }
    }
}

class TaskInputView: NSView, NSTextFieldDelegate {
    var onSubmit: ((String) -> Void)?
    private var textField: NSTextField!
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupTextField()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupTextField()
    }
    
    private func setupTextField() {
        textField = NSTextField(frame: bounds)
        textField.delegate = self
        textField.placeholderString = "Enter task"
        textField.backgroundColor = NSColor.white.withAlphaComponent(0.1)
        textField.textColor = .white
        textField.isBezeled = false
        textField.drawsBackground = true
        textField.focusRingType = .none
        addSubview(textField)
        
        textField.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            textField.leadingAnchor.constraint(equalTo: leadingAnchor),
            textField.trailingAnchor.constraint(equalTo: trailingAnchor),
            textField.topAnchor.constraint(equalTo: topAnchor),
            textField.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if commandSelector == #selector(NSResponder.insertNewline(_:)) {
            if let text = textField.stringValue.isEmpty ? nil : textField.stringValue {
                onSubmit?(text)
                textField.stringValue = ""
            }
            return true
        }
        return false
    }
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.makeFirstResponder(textField)
    }
}

struct TaskInputViewRepresentable: NSViewRepresentable {
    var onSubmit: (String) -> Void
    
    func makeNSView(context: Context) -> TaskInputView {
        let view = TaskInputView(frame: .zero)
        view.onSubmit = onSubmit
        return view
    }
    
    func updateNSView(_ nsView: TaskInputView, context: Context) {}
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
            let windowWidth: CGFloat = 1200
            let windowHeight: CGFloat = 800
            
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
    @State private var username = "paulknight"
    @State private var uptime = "3h 24m"
    
    var body: some View {
        ZStack {
            // Background color
            Color(NSColor(red: 0x0D/255.0, green: 0x11/255.0, blue: 0x16/255.0, alpha: 1.0))
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
                        .frame(height: 200)
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Middle Column
                    VStack(spacing: 20) {
                        TaskCard()
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Right Column
                    VStack(spacing: 20) {
                        TimeCard()
                        TimeCard()
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(20)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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