local colors = require("colors")
local icons = require("icons")
local settings = require("settings")
local app_icons = require("helpers.app_icons")

local item_order = ""
local spaces_by_name = {}

-- Simple JSON array parser for our specific case
local function parse_workspace_json(json_str)
  if not json_str then return {} end
  if type(json_str) == "table" then return json_str end
  
  local spaces = {}
  -- Remove brackets and split by commas
  local items = json_str:gsub("^%[", ""):gsub("%]$", ""):gsub("%s+", "")
  for item in items:gmatch("{[^}]+}") do
    local workspace = item:match('"workspace"%s*:%s*"([^"]+)"')
    local monitor_id = item:match('"monitor%-id"%s*:%s*(%d+)')
    if workspace and monitor_id then
      table.insert(spaces, {
        workspace = workspace,
        ["monitor-id"] = tonumber(monitor_id)
      })
    end
  end
  return spaces
end

sbar.exec("aerospace list-workspaces --all --format '%{workspace}%{monitor-id}' --json", function(spaces_json)
  local spaces = parse_workspace_json(spaces_json)
  
  -- Group spaces by monitor
  local monitors = {}
  for _, space_info in ipairs(spaces) do
    local monitor_id = space_info["monitor-id"]
    monitors[monitor_id] = monitors[monitor_id] or {}
    table.insert(monitors[monitor_id], space_info.workspace)
  end

  for monitor_id, monitor_spaces in pairs(monitors) do
    for _, space_name in ipairs(monitor_spaces) do
        local space = sbar.add("item", "space." .. space_name, {
          icon = {
            font = {
              style = settings.font.style_map["SemiBold"],
              size = 10.0,
            },
            string = space_name,
            padding_left = 7,
            padding_right = 3,
            color = colors.white,
            highlight_color = colors.red,
          },
          label = {
            padding_right = 12,
            color = colors.grey,
            highlight_color = colors.white,
            font = "sketchybar-app-font:Regular:16.0",
            y_offset = -1,
          },
          padding_right = 1,
          padding_left = 1,
          background = {
            color = colors.bg1,
            border_width = 1,
            height = 26,
            border_color = colors.black,
          },
          associated_display = monitor_id
        })

        local space_bracket = sbar.add("bracket", { space.name }, {
          background = {
            color = colors.transparent,
            border_color = colors.bg2,
            height = 28,
            border_width = 2
          }
        })

      -- Padding space
      local space_padding = sbar.add("item", "space.padding." .. space_name, {
        script = "",
        width = settings.group_paddings,
        associated_display = monitor_id
      })

      space:subscribe("aerospace_workspace_change", function(env)
        local selected = env.FOCUSED_WORKSPACE == space_name
        local color = selected and colors.grey or colors.bg2
        space:set({
          icon = { highlight = selected, },
          label = { highlight = selected },
          background = { border_color = selected and colors.black or colors.bg2 }
        })
        space_bracket:set({
          background = { border_color = selected and colors.grey or colors.bg2 }
        })
      end)

      space:subscribe("mouse.clicked", function()
        sbar.exec("aerospace workspace " .. space_name)
      end)

      item_order = item_order .. " " .. space.name .. " " .. space_padding.name
    end
  end
  sbar.exec("sketchybar --reorder " .. item_order .. " front_app")
end)