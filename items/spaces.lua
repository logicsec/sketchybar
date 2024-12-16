local colors = require("colors")
local icons = require("icons")
local settings = require("settings")
local app_icons = require("helpers.app_icons")

local spaces = {}

for i = 1, 10, 1 do
  local space = sbar.add("space", "space." .. i, {
    space = i,
    icon = {
      drawing = false,
    },
    label = {
      padding_left = 2,
      padding_right = 0,
      color = colors.grey,
      highlight_color = colors.white,
    },
    padding_right = 1,
    padding_left = 1,
    background = {
      color = colors.spaces.inactive,
      border_width = 0,
      border_color = colors.black,
    },
    popup = { background = { border_width = 0, border_color = colors.black } }
  })

  spaces[i] = space

  -- Single item bracket for space items to achieve double border on highlight
  local space_bracket = sbar.add("bracket", { space.name }, {
    background = {
      color = colors.transparent,
      border_color = colors.bg2,
      border_width = 0
    }
  })

  -- Padding space
  sbar.add("space", "space.padding." .. i, {
    space = i,
    script = "",
    width = settings.group_paddings,
  })

  local space_popup = sbar.add("item", {
    position = "popup." .. space.name,
    padding_left = 5,
    padding_right = 0,
    background = {
      drawing = true,
      image = {
        corner_radius = 9,
        scale = 0.2
      }
    }
  })

  space:subscribe("space_change", function(env)
    local selected = env.SELECTED == "true"
    space:set({
      icon = { highlight = selected },
      label = { highlight = selected },
      background = { 
        color = selected and colors.spaces.active or colors.spaces.inactive,
        border_color = selected and colors.red or colors.black
      },
      width = selected and 30 or 30
    })
    space_bracket:set({
      background = { color = colors.transparent, border_color = selected and colors.red or colors.bg2 }
    })
  end)

  space:subscribe("mouse.clicked", function(env)
    if env.BUTTON == "other" then
      space_popup:set({ background = { image = "space." .. env.SID } })
      space:set({ popup = { drawing = "toggle" } })
    else
      local op = (env.BUTTON == "right") and "--destroy" or "--focus"
      sbar.exec("yabai -m space " .. op .. " " .. env.SID)
    end
  end)

  space:subscribe("mouse.entered", function(env)
    space_popup:set({ background = { image = "space." .. env.SID } })
    space:set({ popup = { drawing = "toggle" } })
  end)
  
  space:subscribe("mouse.exited", function(_)
    space:set({ popup = { drawing = false } })
  end)

end

local space_window_observer = sbar.add("item", {
  drawing = false,
  updates = true,
})