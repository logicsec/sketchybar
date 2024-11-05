return {
  black = 0xff181819,
  white = 0xffe2e2e3,
  red = 0xFFe78284,
  green = 0xFFa6d189,
  blue = 0xFF8caaee,
  yellow = 0xFFe5c890,
  orange = 0xffD08770,
  magenta = 0xffb39df3,
  grey = 0xff7f8490,
  teal = 0xFF81c8be,
  transparent = 0x00000000,

  bar = {
    bg = 0xF2232634,
    border = 0xff2c2e34,
  },
  popup = {
    bg = 0xc02c2e34,
    border = 0xff7f8490
  },
  spaces = {
    active = 0xff414559,
    inactive = 0xff303446
  },
  bg1 = 0xff303446,
  bg2 = 0xff414559,

  with_alpha = function(color, alpha)
    if alpha > 1.0 or alpha < 0.0 then return color end
    return (color & 0x00ffffff) | (math.floor(alpha * 255.0) << 24)
  end,
}
