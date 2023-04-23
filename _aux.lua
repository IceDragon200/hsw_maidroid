------------------------------------------------------------
-- Copyright (c) 2016 tacigar. All rights reserved.
-- https://github.com/tacigar/maidroid
------------------------------------------------------------
-- Copyright (c) 2023 IceDragon.
-- https://github.com/IceDragon200/hsw_maidroid
------------------------------------------------------------
local mod = assert(hsw_maidroid)

local player_service = assert(nokore.player_service)
local Directions = assert(foundation.com.Directions)
local table_merge = assert(foundation.com.table_merge)

local ItemInterface
if rawget(_G, "yatm") then
  if yatm and yatm.items then
    ItemInterface = yatm.items.ItemInterface
  end
end

mod._aux = {}

local STATE_NEW = 0
local STATE_CRAFTING = 1
local STATE_OUTPUT = 2

local ERROR_OK = 0
local ERROR_NO_RECIPE = 10
local ERROR_NO_CORE = 20
local ERROR_NO_MATERIAL = 30
local ERROR_NO_FUEL = 40
local ERROR_OUTPUT_IS_FULL = 100
local ERROR_NO_RECIPE_ROLLBACK = 110

-- swap_node is a helper function that swap two nodes.
local function maybe_swap_node(pos, node, name)
  if node.name ~= name then
    minetest.swap_node(pos, {
      name = name,
      param1 = node.param1,
      param2 = node.param2,
    })
  end
end

-- can_dig is a common callback.
local function can_dig(pos)
  local meta = minetest.get_meta(pos)
  local inventory = meta:get_inventory()
  return (
    inventory:is_empty("main") and
    inventory:is_empty("fuel") and
    inventory:is_empty("material")
  )
end

-- maidroid_tool.shared.generate_writer is a shared
-- function called for registering egg writer and core writer.
function mod._aux.register_writer(nodename, options)
  local description                           = options.description
  local render_formspec                       = options.formspec
  local tiles                                 = options.tiles
  local node_box                              = options.node_box
  local selection_box                         = options.selection_box
  local duration                              = options.duration
  local on_activate                           = options.on_activate
  local on_deactivate                         = options.on_deactivate
  local empty_itemname                        = options.empty_itemname
  local recipe_registry                       = options.recipe_registry
  local on_metadata_inventory_put_to_main     = options.on_metadata_inventory_put_to_main
  local on_metadata_inventory_take_from_main  = options.on_metadata_inventory_take_from_main

  assert(type(render_formspec) == "function", "expected formspec to be a function")

  local active_nodename = nodename .. "_active"

  -- on_timer is a common callback.
  local function on_timer(pos, dtime)
    local node = minetest.get_node_or_nil(pos)
    local meta = minetest.get_meta(pos)

    local inventory = meta:get_inventory()

    local time = meta:get_float("time")
    local time_max = meta:get_float("time_max")
    local craft_state = meta:get_int("craft_state")
    local craft_error = meta:get_int("craft_error")

    while true do
      if craft_state == STATE_NEW then
        maybe_swap_node(pos, node, nodename)

        local core_stack = inventory:get_stack("core", 1)
        local material_stack = inventory:get_stack("material", 1)

        if core_stack:is_empty() then
          craft_error = ERROR_NO_CORE
          break
        end

        if material_stack:is_empty() then
          craft_error = ERROR_NO_MATERIAL
          break
        end

        local recipe =
          recipe_registry:get_matching_recipe(
            core_stack,
            material_stack
          )

        if recipe then
          craft_error = ERROR_OK
          time = recipe.time
          time_max = recipe.time
          local proc_core = recipe.core:make_item_stack()
          local proc_mat = recipe.material:make_item_stack()
          inventory:set_stack("processing", 1, inventory:remove_item("core", proc_core))
          inventory:set_stack("processing", 2, inventory:remove_item("material", proc_mat))
          craft_state = STATE_CRAFTING
          if on_activate then
            on_activate(pos)
          end
        else
          craft_error = ERROR_NO_RECIPE
          break
        end
      elseif craft_state == STATE_CRAFTING then
        local fuel_time = meta:get_float("fuel_time")
        local fuel_time_max = meta:get_float("fuel_time_max")
        local has_fuel = false

        if fuel_time > 0 then
          has_fuel = true
          fuel_time = fuel_time - dtime
        else
          local fuel_stack = inventory:get_stack("fuel", 1)
          local fuel_result, decremented_fuel = minetest.get_craft_result({
            method = "fuel",
            width = 1,
            items = {fuel_stack}
          })

          if fuel_result.time > 0 then
            has_fuel = true
            fuel_time_max = fuel_result.time
            fuel_time = fuel_time_max
            inventory:set_list("fuel", decremented_fuel.items)
          else
            craft_error = ERROR_NO_FUEL
          end
        end

        meta:set_float("fuel_time", fuel_time)
        meta:set_float("fuel_time_max", fuel_time_max)

        if has_fuel then
          if time > 0 then
            maybe_swap_node(pos, node, active_nodename)
            time = time - dtime
            craft_error = ERROR_OK
          end
        else
          maybe_swap_node(pos, node, nodename)
          craft_error = ERROR_NO_FUEL
        end

        if time <= 0 then
          craft_state = STATE_OUTPUT
        else
          break
        end
      elseif craft_state == STATE_OUTPUT then
        maybe_swap_node(pos, node, active_nodename)

        local main_stack = inventory:get_stack("main", 1)

        if main_stack:is_empty() then
          --- can replace safely
          local proc_core = inventory:get_stack("processing", 1)
          local proc_mat = inventory:get_stack("processing", 2)

          local recipe =
            recipe_registry:get_matching_recipe(
              proc_core,
              proc_mat
            )

          if recipe then
            -- recipe found
            craft_error = ERROR_OK
            local result_stack = recipe.output:make_item_stack()
            if recipe.on_crafted then
              recipe.on_crafted{
                recipe = recipe,
                core = proc_core,
                material = proc_mat,
                result = result_stack,
              }
            end

            if inventory:room_for_item("main", result_stack) then
              -- Clear processing
              inventory:set_stack("processing", 1, ItemStack())
              inventory:set_stack("processing", 2, ItemStack())
              -- Write destination stack
              inventory:add_item("main", result_stack)
              time = -1
              time_max = -1
              craft_state = STATE_NEW
              if on_deactivate then
                on_deactivate(pos)
              end
            else
              --- Should never get here, but just in case
              craft_error = ERROR_OUTPUT_IS_FULL
              break
            end
          else
            if inventory:room_for_item("core", proc_core) and
               inventory:room_for_item("material", proc_mat) then
              inventory:add_item("core", proc_core)
              inventory:add_item("material", proc_mat)
              inventory:set_stack("processing", 1, ItemStack())
              inventory:set_stack("processing", 2, ItemStack())
              time = -1
              time_max = -1
              craft_state = STATE_NEW
            else
              --- We are currently stuck in a rollback situation, where the recipe is
              --- null and we need to return the processing items back to their input
              craft_error = ERROR_NO_RECIPE_ROLLBACK
              break
            end
          end
        else
          --- The output is not empty, it MUST be empty to complete the recipe
          craft_error = ERROR_OUTPUT_IS_FULL
          break
        end
      else
        minetest.log("warning", "unexpected writer state=" .. craft_state)
        craft_state = STATE_NEW
      end
    end

    meta:set_float("time", time)
    meta:set_float("time_max", time_max)
    meta:set_int("craft_error", craft_error)
    meta:set_int("craft_state", craft_state)

    return true -- on_timer should return boolean value.
  end

  -- allow_metadata_inventory_put is a common callback.
  local function allow_metadata_inventory_put(_pos, listname, _index, stack, _player)
    local itemname = stack:get_name()

    if listname == "fuel" then
      local fuel_result = minetest.get_craft_result({
        method = "fuel",
        width = 1,
        items = {stack}
      })
      if fuel_result.time > 0 then
        return stack:get_count()
      end
    elseif listname == "material" and recipe_registry:is_material_stack(stack) then
      return stack:get_count()
    elseif listname == "core" and recipe_registry:is_core_stack(stack) then
      return stack:get_count()
    end
    return 0
  end

  -- allow_metadata_inventory_move is a common callback for the node.
  local function allow_metadata_inventory_move(pos, from_list, from_index, _, to_index, _, player)
    local meta = minetest.get_meta(pos)
    local inventory = meta:get_inventory()
    local stack = inventory:get_stack(from_list, from_index)
    return allow_metadata_inventory_put(pos, listname, to_index, stack, player)
  end

  local function allow_metadata_inventory_take(_pos, _listname, _index, stack)
    return stack:get_count() -- maybe add more.
  end

  local function on_refresh_timer(player_name, form_name, state)
    local player = player_service:get_player_by_name(player_name)
    local meta = minetest.get_meta(state.pos)

    state.time = meta:get_float("time")
    state.time_max = meta:get_float("time_max")
    state.fuel_time = meta:get_float("fuel_time")
    state.fuel_time_max = meta:get_float("fuel_time_max")

    return {
      {
        type = "refresh_formspec",
        value = render_formspec(state.pos, player, state),
      }
    }
  end

  local function on_rightclick(pos, node, player)
    local formspec_name =
      nodename .. ":" .. minetest.pos_to_string(pos)

    local meta = minetest.get_meta(pos)

    local assigns = {
      pos = pos,
      node = node,
      time = meta:get_float("time"),
      time_max = meta:get_float("time_max"),
      fuel_time = meta:get_float("fuel_time"),
      fuel_time_max = meta:get_float("fuel_time_max"),
    }
    local formspec = render_formspec(pos, player, assigns)

    nokore.formspec_bindings:show_formspec(
      player:get_player_name(),
      formspec_name,
      formspec,
      {
        state = assigns,
        -- on_receive_fields = on_receive_fields
        timers = {
          -- routinely update the formspec
          refresh = {
            every = 1,
            action = on_refresh_timer,
          },
        },
      }
    )
  end

  local function on_metadata_inventory_put(pos, listname)
    local timer = minetest.get_node_timer(pos)
    timer:start(0.25)

    if listname == "main" then
      if on_metadata_inventory_put_to_main ~= nil then
        on_metadata_inventory_put_to_main(pos) -- call on_metadata_inventory_put_to_main callback.
      end
    end
  end

  local function on_metadata_inventory_move(pos, from_list, from_index, _, to_index, _, player)
    local meta = minetest.get_meta(pos)
    local inventory = meta:get_inventory()
    local stack = inventory:get_stack(from_list, from_index)

    -- listname is not set here, is it? ~Hybrid Dog
    on_metadata_inventory_put(pos, listname, to_index, stack, player)
  end

  local function on_metadata_inventory_take(pos, listname)
    if listname == "main" then
      if on_metadata_inventory_take_from_main ~= nil then
        on_metadata_inventory_take_from_main(pos) -- call on_metadata_inventory_take_from_main callback.
      end
    end
  end

  local item_interface

  if ItemInterface then
    item_interface = ItemInterface.new_directional(function (_self, pos, dir)
      local node = minetest.get_node(pos)
      local new_dir = Directions.facedir_to_face(node.param2, dir)
      if new_dir == Directions.D_DOWN then
        --- Fuel is inserted and extracted from the bottom
        return "fuel"
      elseif new_dir == Directions.D_UP then
        --- Freshly made cores are extracted from the top
        return "main"
      elseif new_dir == Directions.D_EAST or new_dir == Directions.D_WEST then
        --- Material is inserted from the sides
        return "material"
      elseif new_dir == Directions.D_NORTH or new_dir == Directions.D_SOUTH then
        --- And finally the cores are inserted from the front or back
        return "core"
      end

      return nil
    end)

    function item_interface:allow_extract_item(pos, _dir, item_stack_or_count)
      --- Anything can be taken out of its inventory (since processing is inaccessible)
      return true
    end

    function item_interface:allow_insert_item(pos, dir, item_stack)
      local list_name = self:dir_to_inventory_name(pos, dir)
      if list_name then
        return allow_metadata_inventory_put(pos, list_name, 1, item_stack, nil) > 0
      end
      return false
    end

    function item_interface:on_extract_item(pos, dir, item_stack)
      local list_name = self:dir_to_inventory_name(pos, dir)

      if list_name then
        on_metadata_inventory_take(pos, list_name, item_stack)
      end
    end

    function item_interface:on_insert_item(pos, dir, item_stack)
      local list_name = self:dir_to_inventory_name(pos, dir)

      if list_name then
        on_metadata_inventory_put(pos, list_name, item_stack)
      end
    end
  end

  local base_groups = {
    cracky = nokore.dig_class("copper"),
    item_interface_in = 1,
    item_interface_out = 1,
  }

  do -- register a definition of an inactive node.
    local function initialize_inventory(pos)
      local meta = minetest.get_meta(pos)
      local inventory = meta:get_inventory()

      --- fuel + core#input + material#input > processing(2) > main#output
      inventory:set_size("fuel", 1)
      inventory:set_size("core", 1)
      inventory:set_size("material", 1)
      inventory:set_size("processing", 2)
      inventory:set_size("main", 1)
    end

    local function on_construct(pos)
      local meta = minetest.get_meta(pos)
      meta:set_int("version", 20230422)
      meta:set_int("craft_state", STATE_NEW)
      meta:set_int("craft_error", ERROR_OK)
      meta:set_float("time", -1)
      meta:set_float("time_max", -1)

      local inventory = meta:get_inventory()
      initialize_inventory(pos)
    end

    local sounds

    if rawget(_G, "default") then
      sounds = default.node_sound_stone_defaults()
    end

    if rawget(_G, "yatm_core") then
      sounds = yatm.node_sounds:build("stone")
    end

    minetest.register_node(nodename, {
      description                    = description,
      drawtype                       = "nodebox",
      paramtype                      = "light",
      paramtype2                     = "facedir",
      groups                         = table_merge(base_groups, {}),
      is_ground_content              = false,
      sounds                         = sounds,
      node_box                       = node_box,
      selection_box                  = selection_box,
      tiles                          = tiles.inactive,
      can_dig                        = can_dig,
      on_timer                       = on_timer,
      on_construct                   = on_construct,
      on_rightclick                  = on_rightclick,
      on_metadata_inventory_put      = on_metadata_inventory_put,
      on_metadata_inventory_move     = on_metadata_inventory_move,
      on_metadata_inventory_take     = on_metadata_inventory_take,
      allow_metadata_inventory_put   = allow_metadata_inventory_put,
      allow_metadata_inventory_move  = allow_metadata_inventory_move,
      allow_metadata_inventory_take  = allow_metadata_inventory_take,
      item_interface                 = item_interface,
    })

  end -- end register inactive node.

  do -- register a definition of an active node.
    local sounds

    if rawget(_G, "default") then
      sounds = default.node_sound_stone_defaults()
    end

    if rawget(_G, "yatm_core") then
      sounds = yatm.node_sounds:build("stone")
    end

    minetest.register_node(active_nodename, {
      drawtype                       = "nodebox",
      paramtype                      = "light",
      paramtype2                     = "facedir",
      groups                         = table_merge(base_groups, {
        not_in_creative_inventory = 1,
      }),
      is_ground_content              = false,
      sounds                         = sounds,
      node_box                       = node_box,
      selection_box                  = selection_box,
      tiles                          = tiles.active,
      can_dig                        = can_dig,
      on_timer                       = on_timer,
      on_rightclick                  = on_rightclick,
      on_metadata_inventory_put      = on_metadata_inventory_put,
      on_metadata_inventory_move     = on_metadata_inventory_move,
      on_metadata_inventory_take     = on_metadata_inventory_take,
      allow_metadata_inventory_put   = allow_metadata_inventory_put,
      allow_metadata_inventory_move  = allow_metadata_inventory_move,
      allow_metadata_inventory_take  = allow_metadata_inventory_take,
      item_interface                 = item_interface,
    })
  end -- end register active node.
end
