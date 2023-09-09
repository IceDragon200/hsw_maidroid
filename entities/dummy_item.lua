------------------------------------------------------------
-- Copyright (c) 2016 tacigar. All rights reserved.
-- https://github.com/tacigar/maidroid
------------------------------------------------------------
-- Copyright (c) 2023 IceDragon.
-- https://github.com/IceDragon200/hsw_maidroid
------------------------------------------------------------
local mod = assert(hsw_maidroid)

do
  -- register empty item entity definition.
  -- this entity may be held by in maidroid's primary hands (right-handed).
  mod:register_craftitem("dummy_empty_craftitem", {
    wield_image = "maidroid_dummy_empty_craftitem.png",

    groups = {
      not_in_creative_inventory = 1,
    }
  })

  local function on_activate(self, _staticdata)
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
        local stack

        if self.slot_id == "back_item" then
          stack = luaentity:get_back_item_stack()
        elseif self.slot_id == "head_item" then
          stack = luaentity:get_head_item_stack()
        elseif self.slot_id == "wield_item" then
          stack = luaentity:get_wield_item_stack()
        else
          self.object:remove()
          return
        end

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

    -- if we cannot find the associated maidroid, delete the empty item.
    self.object:remove()
    return
  end

  minetest.register_entity(mod:make_name("dummy_item"), {
    initial_properties = {
      hp_max          = 1,
      visual          = "wielditem",
      visual_size     = {x = 0.025, y = 0.025},
      collisionbox    = {0, 0, 0, 0, 0, 0},
      physical        = false,
      textures        = {"air"},
    },
    on_activate     = on_activate,
    on_step         = on_step,
    itemname        = "",
    maidroid_object = nil,
    -- the item is transient and will be reloaded by the maidroid as needed
    static_save     = false,
  })
end
