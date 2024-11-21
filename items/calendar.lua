local settings = require("settings")
local colors = require("colors")

-- Convert color to hex string
local function to_hex(color)
  -- Assuming color is in format 0xAARRGGBB
  return string.format("%08x", color)
end

-- Padding item required because of bracket
sbar.add("item", { position = "right", width = settings.group_paddings })

local time = sbar.add("item", "time", {
  icon = {
    drawing = false,
    color = colors.white,
    padding_left = 8,
    font = {
      style = settings.font.style_map["Black"],
      size = 12.0,
    },
  },
  label = {
    color = colors.white,
    padding_right = 12,
    padding_left = 12,
    align = "right",
    font = { family = settings.font.numbers },
  },
  position = "right",
  update_freq = 30,
  padding_left = 1,
  padding_right = 1,
  background = {
    color = colors.red,
    border_width = 0,
    corner_radius = 5,
    padding_right = 0
  },
})

local date = sbar.add("item", "date", {
  icon = {
    drawing = false,
    color = colors.white,
    padding_left = 8,
    font = {
      style = settings.font.style_map["Black"],
      size = 12.0,
    },
  },
  label = {
    color = colors.white,
    padding_right = 12,
    padding_left = 12,
    align = "right",
    font = { family = settings.font.numbers },
  },
  position = "right",
  update_freq = 30,
  padding_left = 1,
  padding_right = 1,
  background = {
    color = colors.transparent,
    border_width = 0,
    corner_radius = 0,
    padding_right = 0
  },
})

sbar.add("bracket", "datetime", { date.name, time.name }, {
  background = {
    color = colors.bg1
  },
  padding_right = 0
})

-- Padding item required because of bracket
sbar.add("item", { position = "right", width = settings.group_paddings })

-- Subscribe to update the time and date
date:subscribe({ "forced", "routine", "system_woke" }, function(env)
  date:set({ label = os.date("%a %b %d") })
end)

time:subscribe({ "forced", "routine", "system_woke" }, function(env)
  time:set({ label = os.date("%H:%M") })
end)

-- Track menu visibility
local menu_visible = false

-- Functions to handle menu visibility
local function toggle_menu()
  if menu_visible then
      menu_visible = false
  else
      sbar.exec("~/.config/sketchybar/helpers/event_providers/apple_menu/bin/apple_menu app=date")
      menu_visible = true
  end
end

-- Add click handlers for both time and date
time:subscribe("mouse.clicked", function(env)
    toggle_menu()
end)

date:subscribe("mouse.clicked", function(env)
    toggle_menu()
end)

time:subscribe("mouse.entered", function(env)
    toggle_menu()
end)

date:subscribe("mouse.entered", function(env)
    toggle_menu()
end)

-- Handle window closing when clicking outside
time:subscribe("mouse.clicked.outside", function(env)
    if menu_visible then
        sbar.exec("pkill -SIGUSR1 apple_menu")
        menu_visible = false
    end
end)

date:subscribe("mouse.clicked.outside", function(env)
    if menu_visible then
        sbar.exec("pkill -SIGUSR1 apple_menu")
        menu_visible = false
    end
end)

-- Prevent window from closing when clicking inside
time:subscribe("mouse.clicked.inside", function(env)
    return
end)

date:subscribe("mouse.clicked.inside", function(env)
    return
end)