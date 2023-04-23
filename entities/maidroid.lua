------------------------------------------------------------
-- Copyright (c) 2016 tacigar. All rights reserved.
-- https://github.com/tacigar/maidroid
------------------------------------------------------------
-- Copyright (c) 2023 IceDragon.
-- https://github.com/IceDragon200/hsw_maidroid
------------------------------------------------------------
local mod = assert(hsw_maidroid)

local fspec = assert(foundation.com.formspec.api)
local Groups = assert(foundation.com.Groups)
local string_starts_with = assert(foundation.com.string_starts_with)
local string_trim_leading = assert(foundation.com.string_trim_leading)

local is_player = assert(minetest.is_player)

local product_name = mod:make_name("maidroid")

local MODEL_NAME = "maidroid.b3d"

--- @namespace hsw_maidroid

--- Represents the animation frame data of "models/maidroid.b3d".
---
--- @const ANIMATION_FRAMES: {
---   [name: String]: { x: Integer, y: Integer },
--- }
mod.ANIMATION_FRAMES = {
  --- Standing normally
  STAND      = {x =   1, y =  19},
  --- Standing and lifting something
  STAND_LIFT = {x =  20, y =  24},
  --- Standing while holding something with both arms
  STAND_HOLD = {x =  25, y =  29},
  --- Dropping something that was held
  STAND_DROP = {x =  30, y =  34},
  --- Standing (idling), it's the same as standing normally currently, so meh
  STAND_IDLE = {x =  35, y =  70},
  --- Sitting
  SIT        = {x =  81, y =  89},
  --- Sitting and lifting something
  SIT_LIFT   = {x =  90, y =  94},
  --- Sitting while holding something
  SIT_HOLD   = {x =  95, y =  99},
  --- Dropping that was held while sitting
  SIT_DROP   = {x = 100, y = 104},
  --- Laying down
  LAY        = {x = 162, y = 165},
  --- Walking
  WALK       = {x = 168, y = 187},
  --- Mining (while standing)
  MINE       = {x = 189, y = 198},
  --- Mining (while walking)
  WALK_MINE  = {x = 200, y = 219},
  --- Walking while holding something
  WALK_HOLD  = {x = 230, y = 249},
}

mod.OLD_ANIMATION_FRAMES = {
  STAND     = {x =   1, y =  78},
  SIT       = {x =  81, y = 160},
  LAY       = {x = 162, y = 165},
  WALK      = {x = 168, y = 187},
  MINE      = {x = 189, y = 198},
  WALK_MINE = {x = 200, y = 219},
}

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

--- Returns a name of a maidroid's current hair color.
---
--- @spec #get_hair_color(): String
function mod.maidroid.get_hair_color(self)
  return self.hair_color
end

--- Returns a name of a maidroid's current hair color.
---
--- @spec #set_hair_color(hair_color: String): void
function mod.maidroid.set_hair_color(self, hair_color)
  self.hair_color = hair_color
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
  local position = self.object:get_pos()

  local all_objects = minetest.get_objects_inside_radius(position, range_distance)
  local player_position
  local distance
  for _, object in pairs(all_objects) do
    if object:is_player() then
      player_position = object:get_pos()
      distance = vector.distance(position, player_position)

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

  return vector.add(vector.round(self.object:get_pos()), direction)
end

-- maidroid.maidroid.get_front_node returns a node that exists in front of the maidroid.
function mod.maidroid.get_front_node(self)
  local front = self:get_front()
  return minetest.get_node(front)
end

-- maidroid.maidroid.get_look_direction returns a normalized vector that is
-- the maidroid's looking direction.
function mod.maidroid.get_look_direction(self)
  local yaw = self.object:get_yaw()
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

-- maidroid.maidroid.get_head_item_stack returns the maidroid's head item's stack.
function mod.maidroid.get_head_item_stack(self)
  local inv = self:get_inventory()
  return inv:get_stack("head_item", 1)
end

-- maidroid.maidroid.set_head_item_stack sets maidroid's head item stack.
function mod.maidroid.set_head_item_stack(self, stack)
  local inv = self:get_inventory()
  inv:set_stack("head_item", 1, stack)
end

-- maidroid.maidroid.get_back_item_stack returns the maidroid's back item's stack.
function mod.maidroid.get_back_item_stack(self)
  local inv = self:get_inventory()
  return inv:get_stack("back_item", 1)
end

-- maidroid.maidroid.set_back_item_stack sets maidroid's back item stack.
function mod.maidroid.set_back_item_stack(self, stack)
  local inv = self:get_inventory()
  inv:set_stack("back_item", 1, stack)
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

  local stack
  local wield_stack
  for i = 1, main_size do
    stack = inv:get_stack("main", i)
    if pred(stack:get_name()) then
      wield_stack = inv:get_stack("wield_item", 1)
      inv:set_stack("wield_item", 1, stack)
      inv:set_stack("main", i, wield_stack)
      return true
    end
  end
  return false
end

--- Determines if the maidroid has a name or not
---
--- @spec #is_named(): Boolean
function mod.maidroid.is_named(self)
  return self.nametag and self.nametag ~= ""
end

-- maidroid.maidroid.has_item_in_main reports whether the maidroid has item.
function mod.maidroid.has_item_in_main(self, pred)
  local inv = self:get_inventory()
  local stacks = inv:get_list("main")

  local itemname
  for _, stack in ipairs(stacks) do
    itemname = stack:get_name()
    if pred(itemname) then
      return true
    end
  end
end

-- maidroid.maidroid.change_direction change direction to destination and velocity vector.
function mod.maidroid.change_direction(self, destination)
  local position = self.object:get_pos()
  local direction = vector.subtract(destination, position)
  direction.y = 0
  local velocity = vector.multiply(vector.normalize(direction), 1.5)

  self.object:set_velocity(velocity)
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
  self.object:set_velocity(velocity)
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

-- create_inventory creates a new inventory, and returns it.
local function create_inventory(self)
  self.inventory_name = product_name .. "_" .. tostring(self.manufacturing_number)
  local inventory = minetest.create_detached_inventory(self.inventory_name, {
    on_put = function(inv, listname, index, stack, player)
      if listname == "core" then
        local core_name = stack:get_name()
        local core = mod.registered_cores[core_name]
        core.on_start(self)

        self:update_infotext()
        self:refresh_texture()
      end
    end,

    allow_put = function(inv, listname, index, stack, player)
      -- only cores can put to a core inventory.
      if listname == "main" then
        return stack:get_count()
      elseif listname == "core" and mod.is_behaviour_core(stack) then
        return stack:get_count()
      elseif listname == "back_item" then
        return 1
      elseif listname == "head_item" then
        return 1
      elseif listname == "wield_item" then
        return 1
      elseif listname == "aux" then
        return 1
      elseif listname == "spirit_core" then
        local def = stack:get_definition()
        if def and Groups.has_group(def, "spirit_core") then
          return 1
        end
      end
      return 0
    end,

    on_take = function(inv, listname, index, stack, player)
      if listname == "core" then
        local core_name = stack:get_name()
        local core = mod.registered_cores[core_name]
        core.on_stop(self)

        self:update_infotext()
        self:refresh_texture()
      end
    end,

    allow_take = function(inv, listname, index, stack, player)
      if listname == "wield_item" then
        return 1
      end
      return stack:get_count()
    end,

    on_move = function(inv, from_list, from_index, to_list, to_index, count, player)
      if to_list == "core" or from_list == "core" then
        local core_name = inv:get_stack(to_list, to_index):get_name()
        local core = mod.registered_cores[core_name]

        if to_list == "core" then
          core.on_start(self)
        elseif from_list == "core" then
          core.on_stop(self)
        end

        self:update_infotext()
      end
    end,

    allow_move = function(inv, from_list, from_index, to_list, to_index, count, player)
      if to_list == "wield_item" then
        return 1
      end

      if to_list == "main" then
        return count
      elseif to_list == "core" and mod.is_behaviour_core(inv:get_stack(from_list, from_index)) then
        return count
      end

      return 0
    end,
  })

  --- Main Inventory
  inventory:set_size("main", 16)
  ---
  inventory:set_size("core",  1)
  inventory:set_size("spirit_core",  1)
  inventory:set_size("wield_item", 1)
  inventory:set_size("back_item", 1)
  inventory:set_size("head_item", 1)
  --- Auxillary Slots
  inventory:set_size("aux", 2)

  return inventory
end

local function generate_default_texture()
  return "maidroid_model.skin.default.png^maidroid_model.hair.base.png^maidroid_model.clothing.victorian.black.png^maidroid_model.eyes.default.png"
end

--- Generates the texture string for the given maidroid
---
--- @spec #generate_texture(): String
local function generate_texture(self)
  --- Typically skin tones have a name
  local skin_tone_name = self.skin_tone_name or "default"
  --- But hair color is indexed by its colorstring
  local hair_color = self.hair_color or "#FFFFFF"
  --- Clothing is fixed for now, until new textures are added
  local clothing_style_name = self.clothing_style_name or "victorian.black"
  --- Eye styles are also fixed for now
  local eye_style_name = self.eye_style_name or "default"

  local skin_tone = mod.get_skin_tone(skin_tone_name) or mod.get_skin_tone("default")

  local eyes

  if self:get_core() then
    eyes = "^maidroid_model.eyes."..eye_style_name..".png"
  else
    eyes = "^maidroid_model.eyes.closed.png"
  end

  return ""
    .. "maidroid_model.skin."..skin_tone.name..".png"
    .. "^(maidroid_model.hair.base.png^[multiply:"..hair_color..")"
    .. "^maidroid_model.clothing."..clothing_style_name..".png"
    .. eyes
end

-- create_formspec_string returns a string that represents a formspec definition.
local render_formspec

--- @spec #render_formspec(PlayerRef, state: Table): String
if foundation.is_module_present("yatm_core") then
  function render_formspec(self, player, state)
    local cio = assert(fspec.calc_inventory_offset)

    local texture = generate_texture(self)
    local inv_name = "detached:" .. self.inventory_name

    state.tabs = {
      mod.S("Inventory"),
      mod.S("Appearance"),
    }

    return yatm.formspec_render_split_inv_panel(player, 10, 4, { bg = "default" }, function (loc, rect)
      if loc == "main_body" then
        local model_w = 2

        local animation

        if self.pause then
          animation = mod.ANIMATION_FRAMES.SIT
        else
          animation = mod.ANIMATION_FRAMES.WALK_MINE
        end

        local formspec =
          fspec.tabheader(
            0,
            0,
            nil, -- w
            1, -- h
            "tab", -- name
            state.tabs,
            state.current_tab_index,
            false, -- is_transparent
            true -- draw border
          )
          .. fspec.box(
            rect.x,
            rect.y,
            model_w,
            rect.h,
            "#222222"
          )
          .. fspec.model(
            rect.x,
            rect.y,
            model_w,
            rect.h,
            "model",
            MODEL_NAME,
            texture,
            0,
            180,
            false,
            true,
            animation.x,
            animation.y,
            7.5
          )

        if state.current_tab_index == 1 then
          --- Inventory
          local x = rect.x + cio(model_w)

          return formspec
            .. fspec.list(inv_name, "main", x, rect.y, 4, 4)
            ---
            .. fspec.label(x + cio(4.0), rect.y + 0.25, "Core")
            .. fspec.list(inv_name, "core", x + cio(4.0), rect.y + 0.5, 1, 1)
            --
            .. fspec.label(x + cio(4.0), rect.y + cio(1) + 0.5, "Spirit Core")
            .. fspec.list(inv_name, "spirit_core", x + cio(4.0), rect.y + cio(1) + 0.75, 1, 1)
            --
            .. fspec.label(x + cio(5.0), rect.y + 0.25, "Wield")
            .. fspec.list(inv_name, "wield_item", x + cio(5.0), rect.y + 0.5, 1, 1)
            --
            .. fspec.label(x + cio(6.0), rect.y + 0.25, "Head")
            .. fspec.list(inv_name, "head_item", x + cio(6.0), rect.y + 0.5, 1, 1)
            --
            .. fspec.label(x + cio(7.0), rect.y + 0.25, "Back")
            .. fspec.list(inv_name, "back_item", x + cio(7.0), rect.y + 0.5, 1, 1)
            --
            .. fspec.label(x + cio(6.0), rect.y + cio(1) + 0.5, "Aux")
            .. fspec.list(inv_name, "aux", x + cio(6.0), rect.y + cio(1) + 0.75, 2, 1)
        elseif state.current_tab_index == 2 then
          --- Appearance
          local x = rect.x + cio(model_w)
          state.appearance_tab = state.appearance_tab or "main"

          if state.appearance_tab == "main" then
            local button_w = (rect.w - x) / 3

            return formspec
              .. fspec.label(x, rect.y + 0.25, "Choose One")
              .. fspec.button(x, rect.y + 0.5, button_w, 1, "set_appearance_tab_skin", "Skin")
              .. fspec.button(x + button_w, rect.y + 0.5, button_w, 1, "set_appearance_tab_hair", "Hair")
              .. fspec.button(x + button_w * 2, rect.y + 0.5, button_w, 1, "set_appearance_tab_dress", "Dress")
          elseif state.appearance_tab == "skin" then
            return formspec
              .. fspec.button(x, rect.y, 1, 0.5, "set_appearance_tab_main", "Back")
              .. fspec.label(x + 1, rect.y + 0.25, "Skin Tone")
              .. mod.render_skin_tone_palette{
                basename = "set_skin_tone_",
                x = x,
                y = rect.y + 0.5,
                w = rect.w - cio(model_w),
                h = rect.h - 2,
                cols = true,
                current_value = self.skin_tone_name,
                show_label = false,
                show_tooltip = true
              }
          elseif state.appearance_tab == "hair" then
            return formspec
              .. fspec.button(x, rect.y, 1, 0.5, "set_appearance_tab_main", "Back")
              .. fspec.label(x + 1, rect.y + 0.25, "Hair Color")
              .. mod.render_hair_color_palette{
                basename = "set_hair_color_",
                x = x,
                y = rect.y + 0.5,
                w = rect.w - cio(model_w),
                h = rect.h - 2,
                cols = true,
                current_value = self.hair_color,
                show_label = false,
                show_tooltip = true
              }
          elseif state.appearance_tab == "dress" then
            return formspec
              .. fspec.button(x, rect.y, 1, 0.5, "set_appearance_tab_main", "Back")
              .. fspec.label(x + 1, rect.y + 0.25, "Dress Style")
          end
        end
      elseif loc == "footer" then
        return ""
      end
      return ""
    end)
  end
else
  function render_formspec(self, player, assigns)
    local inv_name = "detached:" .. self.inventory_name

    return fspec.size(8, 9)
      .. default.gui_bg
      .. default.gui_bg_img
      .. default.gui_slots
      .. fspec.list(inv_name, "main", rect.x, rect.y, 4, 4)
      .. fspec.label(rect.x + 4.5, rect.y + 1, "Core")
      .. fspec.list(inv_name, "core", rect.x + 4.5, rect.y + 1.5, 1, 1)
      .. fspec.label(rect.x + 5.5, rect.y + 1, "Wield")
      .. fspec.list(inv_name, "wield_item", rect.x + 5.5, rect.y + 1.5, 1, 1)
      .. fspec.label(rect.x + 6.5, rect.y + 1, "Head")
      .. fspec.list(inv_name, "head_item", rect.x + 6.5, rect.y + 1.5, 1, 1)
      .. fspec.label(rect.x + 6.5, rect.y + 2, "Back")
      .. fspec.list(inv_name, "back_item", rect.x + 6.5, rect.y + 2.5, 1, 1)
      .. fspec.list("current_player", "main", 0, 5, 8, 1)
      .. fspec.list("current_player", "main", 0, 6.2, 8, 3, 8)
  end
end

local function on_receive_fields(player, form_name, fields, state)
  local should_refresh = false
  for key, value in pairs(fields) do
    if key == "tab" then
      state.current_tab_index = tonumber(value)
      should_refresh = true
    elseif string_starts_with(key, "set_skin_tone_") then
      local skin_tone_name = string_trim_leading(key, "set_skin_tone_")
      local skin_tone = mod.get_skin_tone(skin_tone_name)

      if skin_tone then
        state.entity:set_skin_tone_name(skin_tone.name)
        should_refresh = true
      end
    elseif string_starts_with(key, "set_hair_color_") then
      local hair_color_id = string_trim_leading(key, "set_hair_color_")
      local hair_color = mod.get_hair_color(hair_color_id)

      if hair_color then
        --- Funny enough, the name is the color
        state.entity:set_hair_color(hair_color.name)
        should_refresh = true
      end
    elseif string_starts_with(key, "set_appearance_tab_") then
      local appearance_tab = string_trim_leading(key, "set_appearance_tab_")
      if appearance_tab == "main" or
         appearance_tab == "skin" or
         appearance_tab == "hair" or
         appearance_tab == "dress" then
        state.appearance_tab = appearance_tab
        should_refresh = true
      else
        minetest.log("warning", "unexpected appearance_tab=" .. appearance_tab)
      end
    end
  end

  if should_refresh then
    return false, render_formspec(state.entity, player, state)
  else
    return false, nil
  end
end

local function on_rightclick(self, user)
  local state = {
    current_tab_index = 1,
    entity = self
  }

  if is_player(user) then
    nokore.formspec_bindings:show_formspec(
      user:get_player_name(),
      mod:make_name("maidroid"),
      render_formspec(self, user, state),
      {
        state = state,
        on_receive_fields = on_receive_fields,
      }
    )
  end
end

--- Should be called whenever a property that would affect the maidroid's texture is changed to
--- force an immediate refresh of that texture.
---
--- @spec #refresh_texture(): void
local function refresh_texture(self)
  self.object:set_properties{
    textures = {
      generate_texture(self)
    }
  }
end

local function initialize_attachments(self)
  -- attach dummy wield item to new maidroid.
  local dummy_wield_item = minetest.add_entity(
    self.object:get_pos(),
    mod:make_name("dummy_item")
  )
  dummy_wield_item:set_attach(
    self.object,
    "Arm_R",
    {x = 0.065, y = 0.50, z = -0.15},
    {x = -45, y = 0, z = 0}
  )
  dummy_wield_item:get_luaentity().maidroid_object = self.object
  dummy_wield_item:get_luaentity().slot_id = "wield_item"

  local dummy_back_item = minetest.add_entity(
    self.object:get_pos(),
    mod:make_name("dummy_item")
  )
  dummy_back_item:set_attach(
    self.object,
    "Body",
    {x = 0.0, y = 0.40, z = -4/16},
    {x = 0, y = 0, z = 0}
  )
  dummy_back_item:get_luaentity().maidroid_object = self.object
  dummy_back_item:get_luaentity().slot_id = "back_item"

  local dummy_head_item = minetest.add_entity(
    self.object:get_pos(),
    mod:make_name("dummy_item")
  )
  dummy_head_item:set_attach(
    self.object,
    "Head",
    {x = 0.0, y = 0.70, z = 0.0},
    {x = 0, y = 0, z = 0}
  )
  dummy_head_item:get_luaentity().maidroid_object = self.object
  dummy_head_item:get_luaentity().slot_id = "head_item"
end

local function load_from_staticdata(self, staticdata)
  local data = minetest.deserialize(staticdata)

  self.pause = data["pause"] or false
  self.manufacturing_number = data["manufacturing_number"]
  self.nametag = data["nametag"]
  self.owner_name = data["owner_name"]

  self.skin_tone_name = data["skin_tone_name"] or "default"
  self.hair_color = data["hair_color"] or "#FFFFFF"
  self.clothing_style_name = data["clothing_style_name"] or "victorian.black"
  self.eye_style_name = data["eye_style_name"] or "default"

  local inventory = create_inventory(self)
  for list_name, list in pairs(data["inventory"]) do
    inventory:set_list(list_name, list)
  end
end

-- on_activate is a callback function that is called when the object is created or recreated.
local function on_activate(self, staticdata)
  -- parse the staticdata, and compose a inventory.
  if not staticdata or staticdata == "" then
    self.manufacturing_number = mod.manufacturing_data[product_name]
    mod.manufacturing_data[product_name] = mod.manufacturing_data[product_name] + 1
    create_inventory(self)

  else
    -- if static data is not empty string, this object has beed already created.
    load_from_staticdata(self, staticdata)
  end

  self:update_infotext()

  self.object:set_nametag_attributes{
    text = self.nametag
  }

  initialize_attachments(self)

  local core = self:get_core()
  if core == nil then
    self.object:set_velocity{x = 0, y = 0, z = 0}
    self.object:set_acceleration{x = 0, y = -10, z = 0}
  else
    core.on_start(self)
  end

  if self.pause then
    self:set_animation(mod.ANIMATION_FRAMES.SIT)
  end

  self:refresh_texture()
end

-- get_staticdata is a callback function that is called when the object is destroyed.
local function get_staticdata(self)
  local inventory = self:get_inventory()
  local data = {
    --- remember pause state
    pause = self.pause,
    skin_tone_name = self.skin_tone_name,
    hair_color = self.hair_color,
    clothing_style_name = self.clothing_style_name,
    eye_style_name = self.eye_style_name,

    manufacturing_number = self.manufacturing_number,
    nametag = self.nametag,
    owner_name = self.owner_name,
    inventory = {},
  }

  -- set lists.
  for list_name, list in pairs(inventory:get_lists()) do
    local new_list = {}
    for i, item in ipairs(list) do
      new_list[i] = item:to_string()
    end
    data["inventory"][list_name] = new_list
  end

  return minetest.serialize(data)
end

-- maidroid.maidroid.pickup_item pickup items placed and put it to main slot.
local function pickup_item(self)
  local pos = self.object:get_pos()
  local radius = 1.0
  local all_objects = minetest.get_objects_inside_radius(pos, radius)

  for _, obj in ipairs(all_objects) do
    if not obj:is_player() and obj:get_luaentity() then
      local itemstring = obj:get_luaentity().itemstring

      if minetest.registered_items[itemstring] ~= nil then
        local inv = self:get_inventory()
        local stack = ItemStack(itemstring)
        local leftover = inv:add_item("main", stack)

        minetest.add_item(obj:get_pos(), leftover)
        obj:get_luaentity().itemstring = ""
        obj:remove()
      end
    end
  end
end

-- on_step is a callback function that is called every delta times.
local function on_step(self, dtime)
  -- if owner didn't login, the maidroid does nothing.
  if not minetest.get_player_by_name(self.owner_name) then
    return
  end

  -- pickup surrounding item.
  pickup_item(self)

  -- do core method.
  if not self.pause then
    local core = self:get_core()
    if core then
      core.on_step(self, dtime)
    end
  end
end

-- on_punch is a callback function that is called when a player punch then.
local function on_punch(self, puncher, time_from_last_punch, tool_capabilities, dir)
  local core = self:get_core()
  if self.pause == true then
    self.pause = false
    if core then
      core.on_resume(self)
    end
  else
    self.pause = true
    if core then
      core.on_pause(self)
    end
    self:set_animation(mod.ANIMATION_FRAMES.SIT)
  end

  self:update_infotext()
end

-- register a definition of a new maidroid.
mod.registered_maidroids[product_name] = {}
mod.manufacturing_data = mod.manufacturing_data or {}
mod.manufacturing_data[product_name] = mod.manufacturing_data[product_name] or 0

minetest.register_entity(assert(product_name), {
  -- basic initial properties
  initial_properties = {
    hp_max = 20,
    weight = 10,
    mesh = MODEL_NAME,
    textures = {
      generate_default_texture(),
    },

    physical = true,
    visual = "mesh",
    visual_size = {x = 7.5, y = 7.5},
    collisionbox = {-0.25, -0.375, -0.25, 0.25, 0.75, 0.25},
    is_visible = true,
    makes_footstep_sound = true,
    infotext = "",
    nametag = "",

    shaded = true,

    static_save = true,
  },

  groups = {
    nameable = 1,
  },

  -- extra initial properties
  pause                        = false,
  manufacturing_number         = -1,
  owner_name                   = "",

  -- callback methods.
  on_activate                  = on_activate,
  on_step                      = on_step,
  on_rightclick                = on_rightclick,
  on_punch                     = on_punch,
  get_staticdata               = get_staticdata,

  -- extra methods.
  get_inventory                = assert(mod.maidroid.get_inventory),
  get_core                     = assert(mod.maidroid.get_core),
  get_core_name                = assert(mod.maidroid.get_core_name),
  get_nearest_player           = assert(mod.maidroid.get_nearest_player),
  get_front                    = assert(mod.maidroid.get_front),
  get_front_node               = assert(mod.maidroid.get_front_node),
  get_look_direction           = assert(mod.maidroid.get_look_direction),
  set_animation                = assert(mod.maidroid.set_animation),
  set_yaw_by_direction         = assert(mod.maidroid.set_yaw_by_direction),
  get_back_item_stack          = assert(mod.maidroid.get_back_item_stack),
  set_back_item_stack          = assert(mod.maidroid.set_back_item_stack),
  get_head_item_stack          = assert(mod.maidroid.get_head_item_stack),
  set_head_item_stack          = assert(mod.maidroid.set_head_item_stack),
  get_wield_item_stack         = assert(mod.maidroid.get_wield_item_stack),
  set_wield_item_stack         = assert(mod.maidroid.set_wield_item_stack),
  add_item_to_main             = assert(mod.maidroid.add_item_to_main),
  move_main_to_wield           = assert(mod.maidroid.move_main_to_wield),
  is_named                     = assert(mod.maidroid.is_named),
  has_item_in_main             = assert(mod.maidroid.has_item_in_main),
  change_direction             = assert(mod.maidroid.change_direction),
  change_direction_randomly    = assert(mod.maidroid.change_direction_randomly),
  update_infotext              = assert(mod.maidroid.update_infotext),
  get_owner_name               = assert(mod.maidroid.get_owner_name),
  set_owner_name               = assert(mod.maidroid.set_owner_name),
  refresh_texture              = assert(refresh_texture),
  get_skin_tone_name           = assert(mod.maidroid.get_skin_tone_name),
  set_skin_tone_name           = assert(mod.maidroid.set_skin_tone_name),
  get_hair_color               = assert(mod.maidroid.get_hair_color),
  set_hair_color               = assert(mod.maidroid.set_hair_color),
})
