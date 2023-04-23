local mod = assert(hsw_maidroid)

--- Takes a minute, which matches the harmonia_spirits infused coal
local spirit_core_time = 60

--- Crafting hook for Spirit Cores, this will copy the spirit's details into the core
--- When that becomes a thing.
function mod.on_spirit_core_crafted(options)
  local spirit_stack = options.material
  local item_stack = options.result
  --- TODO: Copy spirit stats over to core
end

mod.core_recipes:register_recipe(mod:make_name("spirit_core_default_to_spirit_core_ignis"), {
  description = "Spirit Core Ignis",

  time = spirit_core_time,
  core = {
    name = mod:make_name("spirit_core_default"),
  },
  material = {
    name = "harmonia_spirits:spirit_ignis",
  },
  output = {
    name = mod:make_name("spirit_core_ignis"),
  },
  on_crafted = mod.on_spirit_core_crafted,
})

mod.core_recipes:register_recipe(mod:make_name("spirit_core_default_to_spirit_core_aqua"), {
  description = "Spirit Core Aqua",

  time = spirit_core_time,
  core = {
    name = mod:make_name("spirit_core_default"),
  },
  material = {
    name = "harmonia_spirits:spirit_aqua",
  },
  output = {
    name = mod:make_name("spirit_core_aqua"),
  },
  on_crafted = mod.on_spirit_core_crafted,
})

mod.core_recipes:register_recipe(mod:make_name("spirit_core_default_to_spirit_core_terra"), {
  description = "Spirit Core Terra",

  time = spirit_core_time,
  core = {
    name = mod:make_name("spirit_core_default"),
  },
  material = {
    name = "harmonia_spirits:spirit_terra",
  },
  output = {
    name = mod:make_name("spirit_core_terra"),
  },
  on_crafted = mod.on_spirit_core_crafted,
})

mod.core_recipes:register_recipe(mod:make_name("spirit_core_default_to_spirit_core_ventus"), {
  description = "Spirit Core Ventus",

  time = spirit_core_time,
  core = {
    name = mod:make_name("spirit_core_default"),
  },
  material = {
    name = "harmonia_spirits:spirit_ventus",
  },
  output = {
    name = mod:make_name("spirit_core_ventus"),
  },
  on_crafted = mod.on_spirit_core_crafted,
})

mod.core_recipes:register_recipe(mod:make_name("spirit_core_default_to_spirit_core_umbra"), {
  description = "Spirit Core Umbra",

  time = spirit_core_time,
  core = {
    name = mod:make_name("spirit_core_default"),
  },
  material = {
    name = "harmonia_spirits:spirit_umbra",
  },
  output = {
    name = mod:make_name("spirit_core_umbra"),
  },
  on_crafted = mod.on_spirit_core_crafted,
})

mod.core_recipes:register_recipe(mod:make_name("spirit_core_default_to_spirit_core_lux"), {
  description = "Spirit Core Lux",

  time = spirit_core_time,
  core = {
    name = mod:make_name("spirit_core_default"),
  },
  material = {
    name = "harmonia_spirits:spirit_lux",
  },
  output = {
    name = mod:make_name("spirit_core_lux"),
  },
  on_crafted = mod.on_spirit_core_crafted,
})

mod.core_recipes:register_recipe(mod:make_name("spirit_core_default_to_spirit_core_corrupted"), {
  description = "Spirit Core Corrupted",

  time = spirit_core_time,
  core = {
    name = mod:make_name("spirit_core_default"),
  },
  material = {
    name = "harmonia_spirits:spirit_corrupted",
  },
  output = {
    name = mod:make_name("spirit_core_corrupted"),
  },
  on_crafted = mod.on_spirit_core_crafted,
})
