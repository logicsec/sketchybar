local icons = require("icons")
local colors = require("colors")

-- Convert color to hex string
local function to_hex(color)
    -- Assuming color is in format 0xAARRGGBB
    return string.format("%08x", color)
end

-- Create the Apple menu item with a specific name
local apple = sbar.add("item", "apple.logo", {
    position = "left",
    icon = {
        string = icons.apple,
        font = {
            family = "SF Pro",
            style = "SemiBold",
            size = 15.0
        },
        color = colors.red,
        padding_left = 8,
        padding_right = 8,
    },
    label = { drawing = false },
})

-- Track menu visibility
local menu_visible = false

-- Functions to handle menu visibility
local function show_menu()
    if not menu_visible then
        local panel_color = to_hex(colors.popup.bg)
        local card_color = to_hex(colors.popup.card)
        sbar.exec(string.format(
            "~/.config/sketchybar/helpers/event_providers/apple_menu/bin/apple_menu %s %s",
            panel_color,
            card_color
        ))
        menu_visible = true
    end
end

local function hide_menu()
    if menu_visible then
        sbar.exec("pkill -SIGUSR1 apple_menu")
        menu_visible = false
    end
end

-- Show menu on hover
apple:subscribe("mouse.clicked", function(env)
    show_menu()
end)

-- Add this to prevent window from closing when clicking inside it
apple:subscribe("mouse.clicked.inside", function(env)
    return
end)

-- Track when the menu closes itself
apple:subscribe("mouse.exited.global", function(env)
    menu_visible = false
end)
