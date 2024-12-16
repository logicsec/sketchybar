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

-- Function to update space highlighting based on focus
local function update_space_focus(space_name, is_focused)
  local space = spaces_by_name[space_name]
  if space then
    space:set({
      icon = { highlight = is_focused },
      label = { highlight = is_focused },
      background = { 
        color = is_focused and colors.spaces.active or colors.spaces.inactive,
        border_color = is_focused and colors.red or colors.black
      }
    })
  end
end

-- Function to update all space highlights
local function update_all_spaces_focus()
  sbar.exec("aerospace list-workspaces --monitor all --visible", function(visible_spaces)
    -- Create a set of visible spaces for quick lookup
    local visible = {}
    for space in visible_spaces:gmatch("[^\r\n]+") do
      visible[space] = true
    end
    
    -- Update all spaces
    for space_name, _ in pairs(spaces_by_name) do
      update_space_focus(space_name, visible[space_name] or false)
    end
  end)
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
  
  -- Create spaces for each monitor
  for monitor_id, monitor_spaces in pairs(monitors) do
    for _, space_name in ipairs(monitor_spaces) do
      local space = sbar.add("space", space_name, {
        icon = {
          drawing = false
        },
        label = {
          string = space_name,
          color = colors.grey,
          highlight_color = colors.red,
          font = {
            style = settings.font.style_map["SemiBold"],
            size = 10.0,
        },
        },
        padding_right = 1,
        padding_left = 1,
        width = 30,
        background = {
          color = colors.spaces.inactive,
          border_width = 0,
          border_color = colors.black,
        },
        associated_display = monitor_id
      })
      
      -- Store space reference
      spaces_by_name[space_name] = space

      -- Padding space
      local space_padding = sbar.add("item", "space.padding." .. space_name, {
        script = "",
        width = settings.group_paddings,
        associated_display = monitor_id
      })

      -- Subscribe to workspace changes
      space:subscribe("aerospace_workspace_change", function(env)
        update_all_spaces_focus()
      end)

      space:subscribe("mouse.clicked", function()
        sbar.exec("aerospace workspace " .. space_name, function()
          -- After switching workspace, update the focus state
          update_all_spaces_focus()
        end)
      end)

      space:subscribe("space_windows_change", function()
        sbar.exec("aerospace list-windows --format %{app-name} --workspace " .. space_name, function(windows)
          local no_app = true
          local icon_line = ""
          for app in windows:gmatch("[^\r\n]+") do
            no_app = false
            local lookup = app_icons[app]
            local icon = ((lookup == nil) and app_icons["default"] or lookup)
            icon_line = icon_line .. " " .. icon
          end
    
          if (no_app) then
            icon_line = " —"
          end
          sbar.animate("tanh", 10, function()
            space:set({ label = icon_line })
          end)
        end)
      end)

      item_order = item_order .. " " .. space.name .. " " .. space_padding.name
    end
  end
  
  -- Only try to reorder if we have spaces
  if item_order ~= "" then
    sbar.exec("sketchybar --reorder " .. item_order .. " front_app")
  end
  
  -- Initial focus update
  update_all_spaces_focus()
end)