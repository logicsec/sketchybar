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
local menu_process = nil

-- Functions to handle menu visibility
local function show_menu()
    if not menu_visible then
        -- Kill any existing menu process
        if menu_process then
            sbar.exec("pkill -f apple_menu")
            menu_process = nil
        end
        
        -- Start new menu process
        sbar.exec("~/.config/sketchybar/helpers/event_providers/apple_menu/bin/apple_menu app=menu &")
        menu_visible = true
    end
end

local function hide_menu()
    if menu_visible then
        sbar.exec("pkill -f apple_menu")
        menu_visible = false
        menu_process = nil
    end
end

-- Toggle menu on click only
apple:subscribe("mouse.clicked", function(env)
    if menu_visible then
        hide_menu()
    else
        show_menu()
    end
end)

-- Add mouse.exited to hide menu when mouse leaves
-- apple:subscribe("mouse.exited", function(env)
--     -- Add a small delay to allow clicking inside the menu
--     sbar.delay(0.5, function()
--         hide_menu()
--     end)
-- end)

-- Add this to prevent window from closing when clicking inside it
apple:subscribe("mouse.clicked.inside", function(env)
    return
end)