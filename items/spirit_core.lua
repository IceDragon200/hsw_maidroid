------------------------------------------------------------
-- Copyright (c) 2023 IceDragon.
-- https://github.com/IceDragon200/hsw_maidroid
------------------------------------------------------------
local mod = assert(hsw_maidroid)

local VARIANTS = {
  default = {
    description = mod.S("Spirit Core [Default]"),
  },
  corrupted = {
    description = mod.S("Spirit Core [Corrupted]"),
  },
  aqua = {
    description = mod.S("Spirit Core [Aqua]"),
  },
  ignis = {
    description = mod.S("Spirit Core [Ignis]"),
  },
  lux = {
    description = mod.S("Spirit Core [Lux]"),
  },
  terra = {
    description = mod.S("Spirit Core [Terra]"),
  },
  umbra = {
    description = mod.S("Spirit Core [Umbra]"),
  },
  ventus = {
    description = mod.S("Spirit Core [Ventus]"),
  },
}

for basename, entry in pairs(VARIANTS) do
  mod:register_tool("spirit_core_" .. basename, {
    description = entry.description,

    stack_max = 1,

    groups = {
      spirit_core = 1,
      ["spirit_core_" .. basename] = 1,
    },

    inventory_image = "maidroid_spirit_core."..basename..".png",

    harmonia = {
      attribute = basename,
    },
  })
end
