--- @namespace hsw_maidroid
local mod = assert(hsw_maidroid)

local list_map = assert(foundation.com.list_map)

--- @class ItemIngredient
local ItemIngredient = foundation.com.Class:extends("hsw_maidroid.ItemIngredient")
do
  local ic = ItemIngredient.instance_class

  ItemIngredient.ERR_OK = 0
  ItemIngredient.ERR_NAME_MISMATCH = 10
  ItemIngredient.ERR_STACK_EMPTY = 11
  ItemIngredient.ERR_STACK_SMALL = 12

  --- @spec #initialize(Table): void
  function ic:initialize(def)
    self.name = assert(def.name, "expected an item name")
    self.count = def.count or 1
    self.metadata = def.metadata

    assert(type(self.count) == "number", "expected count to be a integer")
  end

  --- @spec #matches_item_stack(ItemStack): (Boolean, error_code?: Integer)
  function ic:matches_item_stack(item_stack)
    if not item_stack or item_stack:is_empty() then
      return false, ItemIngredient.ERR_STACK_EMPTY
    end

    if item_stack:get_count() < self.count then
      return false, ItemIngredient.ERR_STACK_SMALL
    end

    if item_stack:get_name() ~= self.name then
      return false, ItemIngredient.ERR_NAME_MISMATCH
    end

    -- TODO: check metadata

    return true, ItemIngredient.ERR_OK
  end

  --- @spec #make_item_stack(): ItemStack
  function ic:make_item_stack()
    return ItemStack({
      name = self.name,
      count = self.count,
      metadata = self.metadata,
    })
  end
end

--- @class ItemOutput
local ItemOutput = foundation.com.Class:extends("hsw_maidroid.ItemOutput")
do
  local ic = ItemOutput.instance_class

  --- @spec #initialize(Table): void
  function ic:initialize(def)
    self.name = assert(def.name, "expected an item name")
    self.count = def.count or 1
    self.metadata = def.metadata
  end

  --- @spec #make_item_stack(): ItemStack
  function ic:make_item_stack()
    return ItemStack({
      name = self.name,
      count = self.count,
      metadata = self.metadata,
    })
  end
end

--- @class Recipe
local Recipe = foundation.com.Class:extends("hsw_maidroid.Recipe")
do
  local ic = assert(Recipe.instance_class)

  --- @spec #initialize(name: String, def: Table): void
  function ic:initialize(name, def)
    assert(type(name) == "string", "expected recipe name to be a string")
    assert(type(def) == "table", "expected recipe definition to be a table")

    --- @member name: String
    self.name = name

    --- @member description?: String
    self.description = def.description

    --- @member core: ItemIngredient
    self.core = ItemIngredient:new(assert(def.core))
    --- @member material: ItemIngredient
    self.material = ItemIngredient:new(assert(def.material))
    --- @member output: ItemOutput
    self.output = ItemOutput:new(assert(def.output))

    --- @member time: Integer
    self.time = assert(def.time)

    --- @mutative result
    --- @member on_crafted?: ({
    ---   recipe: Recipe,
    ---   core: ItemStack,
    ---   material: ItemStack,
    ---   result: ItemStack,
    --- }) => void
    self.on_crafted = def.on_crafted
  end

  --- @spec #matches(
  ---   core_item_stack: ItemStack,
  ---   material_item_stack: ItemStack
  --- ): (Boolean, error_code: Integer)
  function ic:matches(core_item_stack, material_item_stack)
    local okay
    local error_code

    okay, error_code = self.core:matches_item_stack(core_item_stack)
    if not okay then
      return okay, error_code
    end

    okay, error_code = self.material:matches_item_stack(material_item_stack)
    if not okay then
      return okay, error_code
    end

    return true, ItemIngredient.ERR_OK
  end
end

--- @class RecipeRegistry
local RecipeRegistry = foundation.com.Class:extends("hsw_maidroid.RecipeRegistry")
do
  local ic = assert(RecipeRegistry.instance_class)

  --- @spec #initialize(): void
  function ic:initialize()
    ic._super.initialize(self)

    --- @member m_recipes: { [name: String]: Recipe }
    self.m_recipes = {}

    --- @member m_index: Table
    self.m_index = {}

    --- @member m_cores: Table
    self.m_cores = {}

    --- @member m_materials: Table
    self.m_materials = {}
  end

  --- @spec #register_recipe(name: String, definition: Table): void
  function ic:register_recipe(name, definition)
    assert(type(definition) == "table")

    if self.m_recipes[name] then
      error("recipe previously registered name=" .. name)
    end

    local recipe = Recipe:new(name, definition)
    self.m_recipes[name] = recipe

    self.m_index[recipe.core.name] = self.m_index[recipe.core.name] or {}
    self.m_index[recipe.core.name][recipe.material.name] = name

    self.m_cores[recipe.core.name] = true
    self.m_materials[recipe.material.name] = true
  end

  --- @spec #is_core_stack(ItemStack): Boolean
  function ic:is_core_stack(item_stack)
    if not item_stack or item_stack:is_empty() then
      return false
    end

    return self.m_cores[item_stack:get_name()] == true
  end

  --- @spec #is_material_stack(ItemStack): Boolean
  function ic:is_material_stack(item_stack)
    if not item_stack or item_stack:is_empty() then
      return false
    end

    return self.m_materials[item_stack:get_name()] == true
  end

  --- @spec get_matching_recipe(
  ---   core_item_stack: ItemStack,
  ---   material_item_stack: ItemStack
  --- ): Recipe | nil
  function ic:get_matching_recipe(core_item_stack, material_item_stack)
    if not core_item_stack or not material_item_stack then
      return nil
    end

    local material_idx = self.m_index[core_item_stack:get_name()]
    if not material_idx then
      return nil
    end

    local recipe_name = material_idx[material_item_stack:get_name()]
    if not recipe_name then
      return nil
    end

    local recipe = self.m_recipes[recipe_name]
    if not recipe then
      return nil
    end

    if not recipe:matches(core_item_stack, material_item_stack) then
      return nil
    end

    return recipe
  end
end

mod.RecipeRegistry = RecipeRegistry
