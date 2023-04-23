------------------------------------------------------------
-- Copyright (c) 2016 tacigar. All rights reserved.
-- https://github.com/tacigar/maidroid
------------------------------------------------------------
-- Copyright (c) 2023 IceDragon.
-- https://github.com/IceDragon200/hsw_maidroid
------------------------------------------------------------
local mod = assert(hsw_maidroid)

--- @namespace hsw_maidroid

-- maidroid.registered_maidroids represents a table that contains
-- definitions of maidroid registered by maidroid.register_maidroid.
mod.registered_maidroids = {}

-- maidroid.registered_cores represents a table that contains
-- definitions of core registered by maidroid.register_core.
mod.registered_cores = {}

--- @const core_recipes: RecipeRegistry
mod.core_recipes = mod.RecipeRegistry:new()

--- Reports whether a item is a behaviour core.
---
--- @spec is_behaviour_core(item_stack: ItemStack): Boolean
function mod.is_behaviour_core(item_stack)
  if not item_stack or item_stack:is_empty() then
    return false
  end
  if mod.registered_cores[item_stack:get_name()] then
    return true
  end
  return false
end

--- Reports whether a name is maidroid's name.
---
--- @spec is_maidroid(name: String): Boolean
function mod.is_maidroid(name)
  if mod.registered_maidroids[name] then
    return true
  end
  return false
end

---------------------------------------------------------------------

--- Registers a definition of a new core.
---
--- @spec register_core(core_name: String, def: Table): void
function mod.register_core(core_name, def)
  assert(type(core_name) == "string", "expected core_name to be string")
  assert(type(def) == "table", "expected core definition to be a table")

  mod.registered_cores[core_name] = def

  minetest.register_tool(core_name, {
    description     = def.description,
    groups = {
      maidroid_behaviour_core = 1,
    },
    stack_max       = 1,
    inventory_image = def.inventory_image,
  })
end
