return {
  black = 0xff232a2d,
  white = 0xffe2e2e3,
  red = 0xffe57474,
  green = 0xff8ccf7e,
  blue = 0xff67b0e8,
  yellow = 0xffe5c76b,
  orange = 0xffd07360,
  magenta = 0xffc47fd5,
  grey = 0xff7f8490,
  teal = 0xff6cbfbf,
  transparent = 0x00000000,

  bar = {
    bg = 0xFF111825,
    border = 0xff2c2e34,
  },
  popup = {
    bg = 0xF2232634,
    border = 0xff7f8490,
    card = 0xff232634,
  },
  spaces = {
    active = 0xff474b54,
    inactive = 0xff474b54,
  },
  bg1 = 0xff282f3b,
  bg2 = 0xff414559,

  with_alpha = function(color, alpha)
    if alpha > 1.0 or alpha < 0.0 then return color end
    return (color & 0x00ffffff) | (math.floor(alpha * 255.0) << 24)
  end,
}
