------------------------------------------------------------
-- Copyright (c) 2023 IceDragon.
-- https://github.com/IceDragon200/hsw_maidroid
------------------------------------------------------------
local hash_node_position = assert(minetest.hash_node_position)

local function set_node_to_air(pos)
  minetest.set_node(pos, { name = "air" })
end

local function random_pos()
  return {
    x = math.random(0xFFFF) - 0x8000,
    y = math.random(0xFFFF) - 0x8000,
    z = math.random(0xFFFF) - 0x8000,
  }
end

hsw_maidroid.autotest_suite.utils = {
  set_node_to_air = set_node_to_air,
  random_pos = random_pos,
}

hsw_maidroid.autotest_suite:define_property("is_core_writer", {
  description = "Is Core Writer",
  detail = [[
  The device should behave like a core writer
  ]],

  setup = function (suite, state)
    local player = assert(minetest.get_player_by_name("singleplayer"))

    state.player = player

    local inv = state.player:get_inventory()
    state.player.hotbar_index = 1
    state.old_list = stash_inventory_list(inv, "main")

    state.pos = random_pos()
    suite:clear_test_area(state.pos)
    state.node_id = hash_node_position(state.pos)
    minetest.set_node(state.pos, assert(state.node))

    return state
  end,

  tests = {
    ["Can open formspec"] = function (suite, state)
      assert(trigger_rightclick_on_pos(state.pos, state.player))

      local inv = state.player:get_inventory()
      -- print(inv:inspect())
      assert_inventory_is_empty(inv, "main")
    end,
  },

  teardown = function (suite, state)
    suite:clear_test_area(state.pos)

    if state.old_list then
      local inv = state.player:get_inventory()
      inv:set_list("main", state.old_list)
      state.old_list = nil
    end
  end,
})

hsw_maidroid.autotest_suite:define_property("is_egg_writer", {
  description = "Is Egg Writer",
  detail = [[
  The device should behave like a core writer
  ]],

  setup = function (suite, state)
    local player = assert(minetest.get_player_by_name("singleplayer"))

    state.player = player

    local inv = state.player:get_inventory()
    state.player.hotbar_index = 1
    state.old_list = stash_inventory_list(inv, "main")

    state.pos = random_pos()
    suite:clear_test_area(state.pos)
    state.node_id = hash_node_position(state.pos)
    minetest.set_node(state.pos, assert(state.node))

    return state
  end,

  tests = {
    ["Can open formspec"] = function (suite, state)
      assert(trigger_rightclick_on_pos(state.pos, state.player))

      local inv = state.player:get_inventory()
      -- print(inv:inspect())
      assert_inventory_is_empty(inv, "main")
    end,
  },

  teardown = function (suite, state)
    suite:clear_test_area(state.pos)

    if state.old_list then
      local inv = state.player:get_inventory()
      inv:set_list("main", state.old_list)
      state.old_list = nil
    end
  end,
})
