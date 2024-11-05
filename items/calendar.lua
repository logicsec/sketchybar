local settings = require("settings")
local colors = require("colors")

-- Padding item required because of bracket
sbar.add("item", { position = "right", width = settings.group_paddings })

local time = sbar.add("item", {
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

local date = sbar.add("item", {
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

sbar.add("bracket", { date.name, time.name }, {
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

