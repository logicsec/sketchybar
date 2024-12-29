import Cocoa
import SwiftUI

struct Settings {
    struct FontSettings {
        let family: String
        let size: CGFloat
    }
    
    struct FontConfig {
        static let text = FontSettings(
            family: "FiraMono Nerd Font",
            size: 14.0
        )
        
        static let numbers = FontSettings(
            family: "FiraMono Nerd Font",
            size: 14.0
        )
        
        static let icons = "SF Pro Text"
        
        static let styleMap: [String: String] = [
            "Regular": "Regular",
            "Semibold": "Medium",
            "Bold": "Bold",
            "Heavy": "Bold",
            "Black": "ExtraBold"
        ]
        
        static let overrides: [String: FontSettings] = [
            "TimeView": FontSettings(
                family: "FiraMono Nerd Font",
                size: 80.0
            ),
            "UptimeView": FontSettings(
                family: "FiraMono Nerd Font",
                size: 14.0
            )
        ]
    }
    
    struct CalendarConfig {
        // Colors
        static let todayColor: Color = .blue
        static let selectedBackgroundColor: Color = .blue
        static let selectedTextColor: Color = .white
        static let defaultTextColor: Color = Color(NSColor.labelColor)
        static let dimmedTextColor: Color = Color(NSColor.tertiaryLabelColor)
        static let headerTextColor: Color = Color(NSColor.secondaryLabelColor)
        
        // Font sizes
        static let dayNumberSize: CGFloat = 14
        static let weekdayHeaderSize: CGFloat = 12
        static let monthYearSize: CGFloat = 14
        
        // Layout
        static let dayHeight: CGFloat = 24
        static let gridSpacing: CGFloat = 8
        static let headerSpacing: CGFloat = 12
        static let buttonSpacing: CGFloat = 4
    }
    
    struct AppConfig {
        static let cornerRadius: CGFloat = 25
        static let offsetX: CGFloat = 5
        static let offsetY: CGFloat = 60
    }
    
    static func getFontSettings(for viewName: String? = nil) -> FontSettings {
        if let viewName = viewName,
           let override = FontConfig.overrides[viewName] {
            return override
        }
        return FontConfig.text
    }
    
    static func getNumberFontSettings() -> FontSettings {
        return FontConfig.numbers
    }
    
    static func getIconFont() -> String {
        return FontConfig.icons
    }
    
    static func getFontStyle(_ style: String) -> String {
        return FontConfig.styleMap[style] ?? style
    }
    
    static var cornerRadius: CGFloat {
        AppConfig.cornerRadius
    }
    
    static var appOffsetY: CGFloat {
        AppConfig.offsetY
    }
    
    static var appOffsetX: CGFloat {
        AppConfig.offsetX
    }
    
    // This is no longer needed since we're not loading from Lua anymore
    static func loadSettings() {
        // No-op as settings are now hardcoded
    }
}
