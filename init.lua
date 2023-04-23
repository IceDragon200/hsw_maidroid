------------------------------------------------------------
-- Copyright (c) 2016 tacigar. All rights reserved.
-- https://github.com/tacigar/maidroid
------------------------------------------------------------
-- Copyright (c) 2023 IceDragon.
-- https://github.com/IceDragon200/hsw_maidroid
------------------------------------------------------------

local mod = foundation.new_module("hsw_maidroid", "1.0.0")

mod:require("config.lua")

mod:require("recipe_registry.lua")
mod:require("api.lua")

mod:require("_aux.lua")
mod:require("nodes/core_writer.lua")
mod:require("nodes/egg_writer.lua")
mod:require("items/spirit_core.lua")
mod:require("items/summon_core.lua")
mod:require("items/nametag.lua")
mod:require("entities/dummy_item.lua")
mod:require("entities/maidroid.lua")
mod:require("cores.lua")

mod:require("hooks.lua")

mod:require("recipes.lua")
mod:require("compat.lua")

if minetest.global_exists("yatm_codex") then
  mod:require("codex.lua")
end

if minetest.global_exists("yatm_autotest") then
  mod:require("autotest.lua")
end
