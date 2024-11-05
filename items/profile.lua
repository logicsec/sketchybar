local icons = require("icons")
local colors = require("colors")
local settings = require("settings")

local current_user = os.getenv("USER")
local profile_pic = string.format("/Users/%s/Pictures/profile.jpg", current_user)

local profile = sbar.add("item", "widgets.profile", {
    position = "right",
    background = {
        image = {
            string = profile_pic,
            corner_radius = 8,
            scale = 0.12,
            drawing = true,
        },
        drawing = true,
        padding_left = 15,
        padding_right = 5,
    },
    icon = {
        drawing = false,
    },
    label = {
        drawing = false,
    }
})
