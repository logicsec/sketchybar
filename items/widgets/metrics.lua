local icons = require("icons")
local colors = require("colors")
local settings = require("settings")

sbar.exec("killall cpu_load >/dev/null; $CONFIG_DIR/helpers/event_providers/cpu_load/bin/cpu_load cpu_update 2.0")
sbar.exec("killall memory_load >/dev/null; $CONFIG_DIR/helpers/event_providers/memory_load/bin/memory_load memory_update 2.0")
sbar.exec("killall hdd_load >/dev/null; $CONFIG_DIR/helpers/event_providers/hdd_load/bin/hdd_load hdd_update 2.0")

local hdd = sbar.add("item", "widgets.hdd" , 52, {
  position = "right",
  background = {
    height = 22,
    color = { alpha = 0 },
    border_width = 0,
    drawing = true,
  },
  icon = { 
    string = icons.hdd,
    color = colors.yellow 
  },
  label = {
    string = "??T",
    font = {
      family = settings.font.numbers,
      style = settings.font.style_map["Bold"],
    },
    align = "right",
    padding_right = 0,
  },
  padding_right = settings.paddings + 6
})

local memory = sbar.add("item", "widgets.memory" , 42, {
  position = "right",
  background = {
    height = 22,
    color = { alpha = 0 },
    border_width = 0,
    drawing = true,
  },
  icon = { 
    string = icons.memory,
    color = colors.teal 
  },
  label = {
    string = "??%",
    font = {
      family = settings.font.numbers,
      style = settings.font.style_map["Bold"],
    },
    align = "right",
    padding_right = 0,
  },
  padding_right = settings.paddings + 6
})

local cpu = sbar.add("item", "widgets.cpu" , 42, {
  position = "right",
  background = {
    height = 22,
    color = { alpha = 0 },
    border_width = 0,
    drawing = true,
  },
  icon = { 
    string = icons.cpu,
    color = colors.red 
  },
  label = {
    string = "??%",
    font = {
      family = settings.font.numbers,
      style = settings.font.style_map["Bold"],
    },
    align = "right",
    padding_right = 0,
  },
  padding_right = settings.paddings + 6
})

cpu:subscribe("cpu_update", function(env)
  -- Also available: env.user_load, env.sys_load
  cpu:set({
    label = env.total_load .. "%",
  })
end)

memory:subscribe("memory_update", function(env)
  memory:set({
      label = env.memory_load,
  })
end)

hdd:subscribe("hdd_update", function(env)
  hdd:set({
      label = env.available,
  })
end)

cpu:subscribe("mouse.clicked", function(env)
  sbar.exec("open -a 'Activity Monitor'")
end)

memory:subscribe("mouse.clicked", function(env)
  sbar.exec("open -a 'Activity Monitor'")
end)

-- Background around the cpu item
sbar.add("bracket", "widgets.metrics.bracket", { cpu.name, memory.name, hdd.name }, {
  background = { color = colors.bg1 }
})

-- Background around the cpu item
sbar.add("item", "widgets.cpu.padding", {
  position = "right",
  width = settings.group_paddings
})
