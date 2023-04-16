------------------------------------------------------------
-- Copyright (c) 2016 tacigar. All rights reserved.
-- https://github.com/tacigar/maidroid
------------------------------------------------------------
-- Copyright (c) 2023 IceDragon.
-- https://github.com/IceDragon200/hsw_maidroid
------------------------------------------------------------
local mod = assert(hsw_maidroid)

local Groups = assert(foundation.com.Groups)
local fspec = assert(foundation.com.formspec.api)

local yspec
if rawget(_G, "yatm_core") then
  yspec = assert(yatm.formspec)
end

if yspec then
  local function render_formspec(player, assigns)
    local cio = fspec.calc_inventory_offset

    return yspec.render_split_inv_panel(player, 4, 2, { bg = "default" }, function (loc, rect)
      if loc == "main_body" then
        return fspec.button_exit(rect.x + cio(3), rect.y, 1, 0, "apply_name", "Apply") ..
          fspec.field(rect.x, rect.y, 3, 1, "name", "name", assigns.nametag)
      elseif loc == "footer" then
        return ""
      end
      return ""
    end)
  end
else
  local function render_formspec(player, assigns)
    local formspec =
      fspec.size(4, 1.25)
      .. default.gui_bg
      .. default.gui_bg_img
      .. default.gui_slots
      .. fspec.button_exit(3, 0.25, 1, 0.875, "apply_name", "Apply")
      .. fspec.field_area(0.5, 0.5, 2.75, 1, "name", "name", assigns.nametag)

    return formspec
  end
end

local function on_receive_fields(player, form_name, fields, state)
  if fields.name and fields.apply_name then
    local luaentity = state.object:get_luaentity()
    if luaentity then
      luaentity.nametag = fields.name

      luaentity.object:set_properties{
        nametag = fields.name,
      }

      local itemstack = state.itemstack
      itemstack:take_item()
      player:set_wielded_item(itemstack)
    end
  end
end

mod:register_craftitem("nametag", {
  description = mod.S("Nametag"),

  groups = {
    nametag = 1,
  },

  inventory_image  = "maidroid_tool_nametag.png",
  stack_max = 1,

  on_use = function(itemstack, player, pointed_thing)
    if pointed_thing.type ~= "object" then
      return nil
    end

    local obj = pointed_thing.ref
    local luaentity = obj:get_luaentity()

    if not obj:is_player() and luaentity then
      local name = luaentity.name

      local is_nameable = false
      if luaentity.is_nameable then
        local ty = type(luaentity.is_nameable)
        if ty == "boolean" then
          is_nameable = luaentity.is_nameable
        elseif ty == "function" then
          is_nameable = luaentity:is_nameable(player, pointed_thing)
        end
      else
        is_nameable = Groups.has_group(luaentity, "nameable")
      end

      if is_nameable then
        local nametag = luaentity.nametag or ""

        local assigns = {
          nametag = nametag,
          object = obj,
          itemstack = itemstack
        }

        nokore.formspec_bindings:show_formspec(
          user:get_player_name(),
          mod:make_name("nametag"),
          render_formspec(user, assigns),
          {
            state = assigns,
            on_receive_fields = on_receive_fields,
          }
        )
      end
    end

    return nil
  end,
})
