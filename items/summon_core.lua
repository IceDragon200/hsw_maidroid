------------------------------------------------------------
-- Copyright (c) 2023 IceDragon.
-- https://github.com/IceDragon200/hsw_maidroid
------------------------------------------------------------
local mod = assert(hsw_maidroid)

mod:register_tool("summon_core_empty", {
  description = mod.S("Empty Maidroid Summoning Core"),

  inventory_image = "maidroid_summon_core_empty.png",

  stack_max = 1,

  on_use = function (item_stack, player, pointed_thing)
    if pointed_thing.type == "object" then
      local obj = pointed_thing.ref
      if obj then
        local luaentity = obj:get_luaentity()
        if luaentity and mod.is_maidroid(luaentity.name) then
          local pos = obj:get_pos()

          --- Prepare New Core
          local new_stack = ItemStack(mod:make_name("summon_core"))
          local meta = new_stack:get_meta()
          local new_description =
            new_stack:get_definition().description .. "\n"
            .. "Contains a Maidroid"

          if luaentity.nametag and luaentity.nametag ~= "" then
            --「」“”
            new_description = new_description .. " \"" .. luaentity.nametag .. "\""
          end
          meta:set_string("static_data", luaentity:get_staticdata())
          meta:set_string(
            "description",
            new_description
          )

          --- Consume this core
          item_stack:take_item(1)
          --- Attempt to add the new core
          local inv = player:get_inventory()
          if inv:room_for_item("main", new_stack) then
            inv:add_item("main", new_stack)
          else
            --- it couldn't be added, so we'll need to drop it instead
            minetest.add_item(drop_pos, leftover)
          end
          --- Finally Remove the item
          obj:remove()

          minetest.sound_play("maidroid_tool_capture_rod_use", {
            pos = pos,
          })

          return item_stack
        else
          -- The entity is not a maidroid
          minetest.chat_send_player(
            player:get_player_name(),
            "The core does not react to this"
          )
        end
      end
    end
    return nil
  end,
})

mod:register_tool("summon_core", {
  description = mod.S("Maidroid Summoning Core"),
  inventory_image = "maidroid_summon_core.png",
  stack_max = 1,

  on_use = function(item_stack, player, pointed_thing)
    if pointed_thing.above ~= nil then
      local meta = item_stack:get_meta()
      -- set maidroid's direction.
      local static_data = meta:get("static_data") or ""
      local new_maidroid = minetest.add_entity(
        pointed_thing.above,
        mod:make_name("maidroid"),
        static_data
      )
      local luaentity = new_maidroid:get_luaentity()

      luaentity:set_yaw_by_direction(
        vector.subtract(player:get_pos(), new_maidroid:get_pos())
      )
      if luaentity.owner_name == nil or luaentity.owner_name == "" then
        luaentity:set_owner_name(player:get_player_name())
        --- TODO: maybe add a callback here for when a maidroid gains an owner
      end
      luaentity:update_infotext()

      item_stack:take_item(1)
      local empty_core = ItemStack(mod:make_name("summon_core_empty"))
      local inv = player:get_inventory()
      if inv:room_for_item("main", empty_core) then
        inv:add_item("main", empty_core)
      else
        minetest.add_item(player:get_pos(), empty_core)
      end
      minetest.sound_play("maidroid_tool_capture_rod_open_egg", {
        pos = new_maidroid:get_pos()
      })
      return item_stack
    end
    return nil
  end,
})
