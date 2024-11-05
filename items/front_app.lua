local colors = require("colors")
local settings = require("settings")
local app_icons = require("helpers.app_icons")

local function getAppIcon(app_name)
    return app_icons[app_name] or app_icons["default"]
end

local space_id = sbar.exec("yabai -m query --windows --window | jq -r '.space'")

local front_app = sbar.add("item", "front_app", {
    position = "left",
    padding_right = 0,
    background = {
        padding_right = 10,
        padding_left = 10,
        color = colors.bg1,
        border_width = 0,
        height = 25
    },
    label = {
        drawing = false,
        padding_left = 10,
        padding_right = 10,
        color = colors.quicksilver,
        font = {
            style = settings.font.style_map["SemiBold"],
            size = 12.0,
        },
    },
    icon = {
        drawing = true,
        padding_left = 10,
        padding_right = 10,
        font = "sketchybar-app-font:Regular:12.0",
        string = getAppIcon("default"),
        color = colors.orange
    },
    updates = true,
    space = space_id,
})

front_app:subscribe("mouse.entered", function(env)
    local selected = env.SELECTED == "true"
    sbar.animate("elastic", 10, function()
        front_app:set({
            background = {
                padding_right = 10,
                padding_left = 10,
                color = colors.bg2,
            },
            label = {
                drawing = false,
                padding_left = 10,
                padding_right = 10,

                color = colors.pastel,
                font = {
                    style = settings.font.style_map["SemiBold"],
                },
            },
            updates = true,
        })
    end)
end)


front_app:subscribe("front_app_switched", function(env)
    sbar.animate("elastic", 10, function()
        local space_id = sbar.exec("yabai -m query --windows --window | jq -r '.space'", function(space_id, exit_code)
            front_app:set({
                label = {
                    drawing = false,
                    string = env.INFO
                },
                icon = {
                    drawing = true,
                    font = "sketchybar-app-font:Regular:12.0",
                    string = getAppIcon(env.INFO)
                },
                space = space_id,
            })
        end)
    end)
end)

front_app:subscribe("mouse.exited", function(env)
    local selected = env.SELECTED == "true"
    sbar.animate("elastic", 10, function()
        front_app:set({
            position = "left",
            background = {

                color = colors.bg1,
            },
            label = {
                drawing = false,
                padding_left = 10,
                padding_right = 10,
                color = colors.quicksilver,
                font = {
                    style = settings.font.style_map["SemiBold"],
                    size = 12.0,
                },
            },
            updates = true,
        })
    end)
end)

front_app:subscribe("mouse.clicked", function(env)
    -- Trigger and animate actions
    sbar.trigger("swap_menus_and_spaces")
    sbar.animate("elastic", 10, function()
        sbar.exec("yabai -m query --windows --window | jq -r '.space'", function(space_id, exit_code)
            front_app:set({
                position = "left",
                background = {
                    color = colors.bg1,
                },
                label = {
                    drawing = false,
                    color = colors.pastel,
                },
                updates = true,
                space = space_id,
            })
        end)
    end)
end)
