------------------------------------------------------------
-- Copyright (c) 2016 tacigar. All rights reserved.
-- https://github.com/tacigar/maidroid
------------------------------------------------------------
-- Copyright (c) 2023 IceDragon.
-- https://github.com/IceDragon200/hsw_maidroid
------------------------------------------------------------
local mod = assert(hsw_maidroid)

-- maidroid.animation_frames represents the animation frame data
-- of "models/maidroid.b3d".
mod.ANIMATION_FRAMES = {
  STAND     = {x =   1, y =  78},
  SIT       = {x =  81, y = 160},
  LAY       = {x = 162, y = 165},
  WALK      = {x = 168, y = 187},
  MINE      = {x = 189, y = 198},
  WALK_MINE = {x = 200, y = 219},
}

-- maidroid.registered_maidroids represents a table that contains
-- definitions of maidroid registered by maidroid.register_maidroid.
mod.registered_maidroids = {}

-- maidroid.registered_cores represents a table that contains
-- definitions of core registered by maidroid.register_core.
mod.registered_cores = {}

-- maidroid.registered_eggs represents a table that contains
-- definition of egg registered by maidroid.register_egg.
mod.registered_eggs = {}

--- Reports whether a item is a core item by the name.
---
--- @spec is_core(item_name: String): Boolean
function mod.is_core(item_name)
  if mod.registered_cores[item_name] then
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

-- maidroid.maidroid represents a table that contains common methods
-- for maidroid object.
-- this table must be contains by a metatable.__index of maidroid self tables.
-- minetest.register_entity set initial properties as a metatable.__index, so
-- this table's methods must be put there.
mod.maidroid = {}

--- Returns a inventory of a maidroid.
---
--- @spec #get_inventory(): InventoryRef
function mod.maidroid.get_inventory(self)
  return minetest.get_inventory {
    type = "detached",
    name = self.inventory_name,
  }
end

--- Returns a name of a maidroid's current owner.
---
--- @spec #get_owner_name(): String
function mod.maidroid.get_owner_name(self)
  return self.owner_name
end

--- Returns a name of a maidroid's current owner.
---
--- @spec #set_owner_name(owner_name: String): void
function mod.maidroid.set_owner_name(self, owner_name)
  self.owner_name = owner_name
end

--- Returns a name of a maidroid's current skin tone.
---
--- @spec #get_skin_tone_name(): String
function mod.maidroid.get_skin_tone_name(self)
  return self.skin_tone_name
end

--- Returns a name of a maidroid's current skin tone.
---
--- @spec #set_skin_tone_name(skin_tone_name: String): void
function mod.maidroid.set_skin_tone_name(self, skin_tone_name)
  self.skin_tone_name = skin_tone_name
  self:refresh_texture()
end

--- Returns a name of a maidroid's current core.
---
--- @spec #get_core_name(): String
function mod.maidroid.get_core_name(self)
  local inv = self:get_inventory()
  return inv:get_stack("core", 1):get_name()
end

--- Returns a maidroid's current core definition.
---
--- @spec #get_core(): MaidroidCore | nil
function mod.maidroid.get_core(self)
  local name = self:get_core_name()
  if name ~= "" then
    return mod.registered_cores[name]
  end
  return nil
end

--- Returns a player object who is the nearest to the maidroid.
---
--- @spec #get_nearest_player(range_distance: Number): PlayerRef
function mod.maidroid.get_nearest_player(self, range_distance)
  local player, min_distance = nil, range_distance
  local position = self.object:getpos()

  local all_objects = minetest.get_objects_inside_radius(position, range_distance)
  for _, object in pairs(all_objects) do
    if object:is_player() then
      local player_position = object:getpos()
      local distance = vector.distance(position, player_position)

      if distance < min_distance then
        min_distance = distance
        player = object
      end
    end
  end
  return player
end

--- Returns a position in front of the maidroid.
---
--- @spec #get_front(): minetest.vector
function mod.maidroid.get_front(self)
  local direction = self:get_look_direction()
  if math.abs(direction.x) >= 0.5 then
    if direction.x > 0 then direction.x = 1 else direction.x = -1 end
  else
    direction.x = 0
  end

  if math.abs(direction.z) >= 0.5 then
    if direction.z > 0 then direction.z = 1 else direction.z = -1 end
  else
    direction.z = 0
  end

  return vector.add(vector.round(self.object:getpos()), direction)
end

-- maidroid.maidroid.get_front_node returns a node that exists in front of the maidroid.
function mod.maidroid.get_front_node(self)
  local front = self:get_front()
  return minetest.get_node(front)
end

-- maidroid.maidroid.get_look_direction returns a normalized vector that is
-- the maidroid's looking direction.
function mod.maidroid.get_look_direction(self)
  local yaw = self.object:getyaw()
  return vector.normalize{x = -math.sin(yaw), y = 0.0, z = math.cos(yaw)}
end

-- maidroid.maidroid.set_animation sets the maidroid's animation.
-- this method is wrapper for self.object:set_animation.
function mod.maidroid.set_animation(self, frame)
  self.object:set_animation(frame, 15, 0)
end

-- maidroid.maidroid.set_yaw_by_direction sets the maidroid's yaw
-- by a direction vector.
function mod.maidroid.set_yaw_by_direction(self, direction)
  self.object:setyaw(math.atan2(direction.z, direction.x) - math.pi / 2)
end

-- maidroid.maidroid.get_wield_item_stack returns the maidroid's wield item's stack.
function mod.maidroid.get_wield_item_stack(self)
  local inv = self:get_inventory()
  return inv:get_stack("wield_item", 1)
end

-- maidroid.maidroid.set_wield_item_stack sets maidroid's wield item stack.
function mod.maidroid.set_wield_item_stack(self, stack)
  local inv = self:get_inventory()
  inv:set_stack("wield_item", 1, stack)
end

-- maidroid.maidroid.add_item_to_main add item to main slot.
-- and returns leftover.
function mod.maidroid.add_item_to_main(self, stack)
  local inv = self:get_inventory()
  return inv:add_item("main", stack)
end

-- maidroid.maidroid.move_main_to_wield moves itemstack from main to wield.
-- if this function fails then returns false, else returns true.
function mod.maidroid.move_main_to_wield(self, pred)
  local inv = self:get_inventory()
  local main_size = inv:get_size("main")

  for i = 1, main_size do
    local stack = inv:get_stack("main", i)
    if pred(stack:get_name()) then
      local wield_stack = inv:get_stack("wield_item", 1)
      inv:set_stack("wield_item", 1, stack)
      inv:set_stack("main", i, wield_stack)
      return true
    end
  end
  return false
end

-- maidroid.maidroid.is_named reports the maidroid is still named.
function mod.maidroid.is_named(self)
  return self.nametag ~= ""
end

-- maidroid.maidroid.has_item_in_main reports whether the maidroid has item.
function mod.maidroid.has_item_in_main(self, pred)
  local inv = self:get_inventory()
  local stacks = inv:get_list("main")

  for _, stack in ipairs(stacks) do
    local itemname = stack:get_name()
    if pred(itemname) then
      return true
    end
  end
end

-- maidroid.maidroid.change_direction change direction to destination and velocity vector.
function mod.maidroid.change_direction(self, destination)
  local position = self.object:getpos()
  local direction = vector.subtract(destination, position)
  direction.y = 0
  local velocity = vector.multiply(vector.normalize(direction), 1.5)

  self.object:setvelocity(velocity)
  self:set_yaw_by_direction(direction)
end

-- maidroid.maidroid.change_direction_randomly change direction randonly.
function mod.maidroid.change_direction_randomly(self)
  local direction = {
    x = math.random(0, 5) * 2 - 5,
    y = 0,
    z = math.random(0, 5) * 2 - 5,
  }
  local velocity = vector.multiply(vector.normalize(direction), 1.5)
  self.object:setvelocity(velocity)
  self:set_yaw_by_direction(direction)
end

-- maidroid.maidroid.update_infotext updates the infotext of the maidroid.
function mod.maidroid.update_infotext(self)
  local infotext = ""
  local core_name = self:get_core_name()

  if core_name ~= "" then
    if self.pause then
      infotext = infotext .. "this maidroid is paused\n"
    else
      infotext = infotext .. "this maidroid is active\n"
    end
    infotext = infotext .. "[Core] : " .. core_name .. "\n"
  else
    infotext = infotext .. "this maidroid is inactive\n[Core] : None\n"
  end
  infotext = infotext .. "[Owner] : " .. self.owner_name
  self.object:set_properties{infotext = infotext}
end

-- register empty item entity definition.
-- this entity may be hold by maidroid's hands.
do
  mod:register_craftitem("dummy_empty_craftitem", {
    wield_image = "maidroid_dummy_empty_craftitem.png",
  })

  local function on_activate(self, staticdata)
    self.object:set_properties{
      textures = {
        mod:make_name("dummy_empty_craftitem")
      }
    }
  end

  local function on_step(self, dtime)
    if self.maidroid_object then
      local luaentity = self.maidroid_object:get_luaentity()
      if luaentity then
        local stack = luaentity:get_wield_item_stack()

        if stack:get_name() ~= self.itemname then
          if stack:is_empty() then
            self.itemname = ""
            self.object:set_properties{
              textures = {
                mod:make_name("dummy_empty_craftitem"),
              }
            }
          else
            self.itemname = stack:get_name()
            self.object:set_properties{
              textures = {
                self.itemname
              }
            }
          end
        end
        return
      end
    end

    -- if cannot find maidroid, delete empty item.
    self.object:remove()
    return
  end

  minetest.register_entity(mod:make_name("dummy_item"), {
    hp_max         = 1,
    visual         = "wielditem",
    visual_size    = {x = 0.025, y = 0.025},
    collisionbox   = {0, 0, 0, 0, 0, 0},
    physical       = false,
    textures       = {"air"},
    on_activate    = on_activate,
    on_step        = on_step,
    itemname       = "",
    maidroid_object  = nil
  })
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
    stack_max       = 1,
    description     = def.description,
    inventory_image = def.inventory_image,
  })
end
