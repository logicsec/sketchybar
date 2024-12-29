local colors = require("colors")
local settings = require("settings")

-- Equivalent to the --bar domain
sbar.bar({
  sticky = true,
  position = "top",
  height = settings.bar.height,
  margin=10,
  color = colors.bar.bg,
  border_color=colors.bar.border,
  border_width=0,
  padding_right=10,
  padding_left=10,
  corner_radius=8,
  blur_radius=6,
  y_offset=settings.y_offset
})
