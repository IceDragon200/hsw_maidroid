------------------------------------------------------------
-- Copyright (c) 2023 IceDragon.
-- https://github.com/IceDragon200/hsw_maidroid
------------------------------------------------------------
local mod = assert(hsw_maidroid)

mod:register_tool("summon_core_empty", {
  description = mod.S("Empty Maidroid Summoning Core"),

  inventory_image = "maidroid_summon_core_empty.png",

  stack_max = 1,
})

mod:register_tool("summon_core", {
  description = mod.S("Maidroid Summoning Core"),
  inventory_image = "maidroid_summon_core.png",
  stack_max = 1,

  on_use = function(itemstack, player, pointed_thing)
    if pointed_thing.above ~= nil then
      -- set maidroid's direction.
      local new_maidroid = minetest.add_entity(pointed_thing.above, mod:make_name("maidroid"))
      local luaentity = new_maidroid:get_luaentity()

      luaentity:set_yaw_by_direction(
        vector.subtract(player:get_pos(), new_maidroid:get_pos())
      )
      luaentity:set_owner_name(player:get_player_name())
      luaentity:update_infotext()

      itemstack:take_item(1)
      local empty_core = ItemStack(mod:make_name("summon_core_empty"))
      local inv = player:get_inventory()
      if inv:room_for_item("main", empty_core) then
        inv:add_item("main", empty_core)
      else
        minetest.add_item(player:get_pos(), empty_core)
      end
      return itemstack
    end
    return nil
  end,
})
