local colors = require("colors")
local settings = require("settings")
local app_icons = require("helpers.app_icons")

local space_id = sbar.exec("aerospace list-workspaces --focused")

-- Create the front app item
local front_app = sbar.add("item", "front_app", {
	label = {
		drawing = true,
		color = colors.white,
		font = {
			family = settings.font.text,
			style = settings.font.style_map["Semibold"],
			size = 12,
		},
	},
	icon = {
		background = {
			drawing = true,
			image = {
				scale = 0.75,
				padding_right = settings.paddings,
			},
		},
	},
    background = {
        color = colors.bg1,
        border_width = 0,
        height = 26,
      },
	updates = true,
})

-- Event: Front app switched
front_app:subscribe("front_app_switched", function(env)
	sbar.exec("aerospace list-windows --focused --format '%{monitor-id}'", function(monitor_id, exit_code)
		front_app:set({
			icon = {
				background = {
					image = "app." .. env.INFO,
				},
			},
			label = {
				drawing = true,
				string = env.INFO,
			},
			display = monitor_id
		})
	end)
end)

return front_app