------------------------------------------------------------
-- Copyright (c) 2016 tacigar. All rights reserved.
-- https://github.com/tacigar/maidroid
------------------------------------------------------------

maidroid = {}

maidroid.modname = "maidroid"
maidroid.modpath = minetest.get_modpath(maidroid.modname)

dofile(maidroid.modpath .. "/api.lua")
dofile(maidroid.modpath .. "/register.lua")
dofile(maidroid.modpath .. "/crafting.lua")

maidroid_tool = {}

maidroid_tool.modname = "maidroid_tool"
maidroid_tool.modpath = minetest.get_modpath(maidroid_tool.modname)

dofile(maidroid_tool.modpath .. "/_aux.lua")
dofile(maidroid_tool.modpath .. "/core_writer.lua")
dofile(maidroid_tool.modpath .. "/egg_writer.lua")
dofile(maidroid_tool.modpath .. "/crafting.lua")
dofile(maidroid_tool.modpath .. "/nametag.lua")
dofile(maidroid_tool.modpath .. "/capture_rod.lua")

maidroid_core = {}

maidroid_core.modname = "maidroid_core"
maidroid_core.modpath = minetest.get_modpath(maidroid_core.modname)

dofile(maidroid_core.modpath .. "/cores/_aux.lua")
dofile(maidroid_core.modpath .. "/cores/empty.lua")
dofile(maidroid_core.modpath .. "/cores/basic.lua")
dofile(maidroid_core.modpath .. "/cores/farming.lua")
dofile(maidroid_core.modpath .. "/cores/torcher.lua")
if minetest.global_exists("pdisc") then
  dofile(maidroid_core.modpath .. "/cores/ocr.lua")
end
