local mod = assert(hsw_maidroid)

if rawget(_G, "default") then
  mod:require("compat/minetest_game/recipes.lua")
end
