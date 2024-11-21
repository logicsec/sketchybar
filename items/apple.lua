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
local function toggle_menu()
    if menu_visible then
        menu_visible = false
    else
        sbar.exec("~/.config/sketchybar/helpers/event_providers/apple_menu/bin/apple_menu app=menu")
        menu_visible = true
    end
end

-- Toggle menu on click
apple:subscribe("mouse.clicked", function(env)
    toggle_menu()
end)

apple:subscribe("mouse.entered", function(env)
    toggle_menu()
end)

-- Add this to prevent window from closing when clicking inside it
apple:subscribe("mouse.clicked.inside", function(env)
    return
end)

-- Remove or comment out the mouse.exited.global subscription
-- apple:subscribe("mouse.exited.global", function(env)
--     menu_visible = false
-- end)
