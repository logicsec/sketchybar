# Custom SketchyBar Configuration

A highly customized configuration for [SketchyBar](https://github.com/FelixKratz/SketchyBar), featuring various plugins for system monitoring, media control, weather updates, and more.

## 📋 Prerequisites

Before setting up this configuration, ensure you have the following installed:

1. **SketchyBar**
   ```bash
   brew install sketchybar
   ```

2. **Yabai** (Window Manager)
   ```bash
   brew install koekeishiya/formulae/yabai
   ```

3. **SF Symbols** (for icons)
   ```bash
   brew install --cask sf-symbols
   ```

4. **Nerd Fonts** (for additional icons)
   ```bash
   brew tap homebrew/cask-fonts
   brew install --cask font-hack-nerd-font
   ```

5. **SQLite3** (for data management)
   ```bash
   brew install sqlite3
   ```

6. **jq** (for JSON parsing)
   ```bash
   brew install jq
   ```

## 🗂 Repository Structure

```
.
├── items/                  # Item configurations
│   ├── apple.sh           # Apple menu items
│   ├── datetime.sh        # Date and time display
│   ├── focus.sh           # Focus mode settings
│   ├── front_app.sh       # Front application display
│   ├── media.sh           # Media controls
│   ├── metrics.sh         # System metrics
│   ├── network.sh         # Network status
│   ├── notifications.sh   # Notification center
│   ├── profile.sh         # Profile settings
│   └── spaces.sh          # Workspace spaces
├── plugins/               # Plugin scripts
│   ├── helpers/          # Helper functions
│   ├── launchers/        # Application launchers
│   ├── apple.sh          # Apple menu functionality
│   ├── battery.sh        # Battery monitoring
│   ├── brew.sh           # Homebrew updates
│   ├── cpu.sh            # CPU monitoring
│   ├── date.sh           # Date functions
│   ├── disk.sh           # Disk usage
│   ├── focus.sh          # Focus mode
│   ├── front_app.sh      # Active application
│   ├── icon_map_fn.sh    # Icon mapping
│   ├── mail.sh           # Mail notifications
│   ├── media.sh          # Media controls
│   ├── memory.sh         # RAM usage
│   ├── messages.sh       # Message notifications
│   ├── network.sh        # Network monitoring
│   ├── sound_click.sh    # Sound effects
│   ├── sound.sh          # Volume control
│   ├── space.sh          # Space management
│   ├── time_hm.sh        # Time format
│   ├── time.sh          # Time display
│   ├── weather.sh        # Weather information
│   └── window_title.sh   # Window title display
├── colors.sh             # Color definitions
├── icons.sh              # Icon definitions
└── sketchybarrc         # Main configuration
```

## ⚙️ Setup

1. Clone this repository to your SketchyBar config directory:
   ```bash
   git clone https://github.com/yourusername/sketchybar-config ~/.config/sketchybar
   ```

2. Make all scripts executable:
   ```bash
   chmod +x ~/.config/sketchybar/**/*.sh
   chmod +x ~/.config/sketchybar/*.sh
   ```

3. Set up environment variables (for plugins that need them):
   ```bash
   cp ~/.config/sketchybar/.env.example ~/.config/sketchybar/.env
   ```
   Edit the `.env` file with your API keys and preferences.

4. Start SketchyBar:
   ```bash
   brew services start sketchybar
   ```

## 🔧 Configuration

### Weather Plugin
Requires a Weather API key. See [weather setup](./plugins/weather.md) for details.

### Focus Mode
Integrates with macOS Focus modes. Configure in `plugins/focus.sh`.

### Media Controls
Supports various media players including:
- Apple Music
- Spotify
- Chrome
- Safari

### System Monitoring
Includes plugins for:
- CPU usage
- Memory usage
- Disk space
- Network traffic
- Battery status

### Profile
Ensure you update the plugins/profile.sh file with your own image path. This is used for the profile menu image. 

## 🎨 Customization

### Colors
Edit `colors.sh` to modify the color scheme.

### Icons
Modify `icons.sh` to change icons. This configuration uses:
- SF Symbols
- Nerd Fonts

## 🛠 Troubleshooting

1. Check SketchyBar logs:
   ```bash
   tail -f /tmp/sketchybar_log
   ```

2. Verify permissions:
   ```bash
   ls -la ~/.config/sketchybar/
   ```

3. Reset SketchyBar:
   ```bash
   brew services restart sketchybar
   ```

## 📝 Contributing

Feel free to submit issues and enhancement requests!

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [FelixKratz](https://github.com/FelixKratz) for creating SketchyBar
- Various contributors from the SketchyBar community