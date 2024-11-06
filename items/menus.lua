local colors = require("colors")
local icons = require("icons")
local settings = require("settings")
local app_icons = require("helpers.app_icons")

local function getAppIcon(app_name)
    return app_icons[app_name] or app_icons["default"]
end

local menu_watcher = sbar.add("item", {
  drawing = false,
  updates = false,
})

local space_menu_swap = sbar.add("item", {
  drawing = false,
  updates = true,
})

sbar.add("event", "swap_menus_and_spaces")

local max_items = 15
local menu_items = {}
for i = 1, max_items do
  local menu = sbar.add("item", "menu." .. i, {
    padding_left = settings.paddings,
    padding_right = settings.paddings,
    drawing = false,
    icon = { drawing = false },
    label = {
      padding_left = 6,
      padding_right = 6,
    },
    click_script = "$CONFIG_DIR/helpers/menus/bin/menus -s " .. i,
  })

  menu_items[i] = menu
end

sbar.add("bracket", { '/menu\\..*/' }, {
  background = { color = colors.bg1 }
})

local menu_padding = sbar.add("item", "menu.padding", {
  drawing = false,
  width = 5
})

local function update_menus(space_id)
  sbar.exec("$CONFIG_DIR/helpers/menus/bin/menus -l", function(menus)
    sbar.set('/menu\\..*/', { drawing = false })
    menu_padding:set({ drawing = true })

    local id = 1

    for menu in string.gmatch(menus, '[^\r\n]+') do
      local label = ""
      local icon = nil
      local icon_line = ""

      if id == 1 then
        menu_items[id]:set({
          icon = {
            drawing = false,
            padding_left = 10,
            font = "sketchybar-app-font:Regular:12.0",
            string = getAppIcon(menu)
          },
          label = {
            drawing = true,
            string = menu,
            color = colors.white,
            font = {
              style = settings.font.style_map["Bold"],
              size = 12.0,
          },
          },
          drawing = true,
          space = space_id,
        })
      else
        label = menu
        if id <= max_items then
          menu_items[id]:set({
            label = {
              string = label,
              color = colors.quicksilver,
              font = {
                  style = settings.font.style_map["SemiBold"],
                  size = 12.0,
              }
            },
            drawing = true,
            space = space_id,
          })
        else
          break 
        end
      end

      id = id + 1
    end
  end)
end


menu_watcher:subscribe("front_app_switched", function()
  sbar.exec("yabai -m query --windows --window | jq -r '.space'", function(space_id, exit_code)
    update_menus(space_id)
    sbar.set("/menu\\..*/", { drawing = false })  -- Clear previous menu state
    sbar.set("/menu\\..*/", { drawing = true })  -- Show menus for the new space
  end)
end)

space_menu_swap:subscribe("swap_menus_and_spaces", function(env)
  local drawing = menu_items[1]:query().geometry.drawing == "on"
  if drawing then
    menu_watcher:set({ updates = false })
    sbar.set("/menu\\..*/", { drawing = false })
  else
    menu_watcher:set({ updates = true })
    sbar.exec("yabai -m query --windows --window | jq -r '.space'", function(space_id, exit_code)
      update_menus(space_id)  -- Update menus based on the active space
      sbar.set("/menu\\..*/", { drawing = true })  -- Show updated menus
    end)
  end
end)

return menu_watcher
