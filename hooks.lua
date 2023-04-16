------------------------------------------------------------
-- Copyright (c) 2016 tacigar. All rights reserved.
-- https://github.com/tacigar/maidroid
------------------------------------------------------------
-- Copyright (c) 2023 IceDragon.
-- https://github.com/IceDragon200/hsw_maidroid
------------------------------------------------------------
local mod = assert(hsw_maidroid)

local FILENAME = minetest.get_worldpath() .. "/manufacturing_data"

minetest.register_on_shutdown(function()
  local file = io.open(FILENAME, "w")
  file:write(minetest.serialize(mod.manufacturing_data))
  file:close()
end)

minetest.register_on_mods_loaded(function ()
  -- maidroid.manufacturing_data represents a table that contains manufacturing data.
  -- this table's keys are product names, and values are manufacturing numbers
  -- that has been already manufactured.
  mod.manufacturing_data = mod.manufacturing_data or {}

  local file = io.open(FILENAME, "r")
  if file ~= nil then
    local data = file:read("*a")
    file:close()
    mod.manufacturing_data = minetest.deserialize(data)
  end
end)
