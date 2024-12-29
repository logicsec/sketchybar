#!/bin/bash

# Create bin directory if it doesn't exist
mkdir -p bin

# Compile all Swift files together
swiftc -o bin/apple_menu \
    apple_menu.swift \
    Views/TimeView.swift \
    Views/UptimeView.swift \
    Views/CalendarView.swift \
    Views/MediaControllerView.swift \
    Components/Card.swift \
    Settings.swift \
    -framework Cocoa \
    -framework SwiftUI \
    -framework MediaPlayer \
    -framework CoreAudio \
    -framework CoreBluetooth \
    -framework AppKit \
    -framework Foundation
