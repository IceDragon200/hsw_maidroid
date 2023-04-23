------------------------------------------------------------
-- Copyright (c) 2016 tacigar. All rights reserved.
-- https://github.com/tacigar/maidroid
------------------------------------------------------------
-- Copyright (c) 2023 IceDragon.
-- https://github.com/IceDragon200/hsw_maidroid
------------------------------------------------------------
local mod = assert(hsw_maidroid)

local fspec = assert(foundation.com.formspec.api)

local yspec
if rawget(_G, "yatm_core") then
  yspec = assert(yatm.formspec)
end

do -- register core writer
  local node_box = {
    type = "fixed",
    fixed = {
      {-0.4375,   -0.25, -0.4375,  0.4375,  0.1875,  0.4375},
      { 0.1875,  0.3125,  0.0625,  0.4375,   0.375,   0.125},
      { -0.375,  0.1875,  -0.375,   0.375,    0.25,   0.375},
      {-0.0625,    -0.5, -0.0625,  0.0625,   0.375,  0.0625},
      {  0.375,  0.1875,  0.0625,  0.4375,   0.375,   0.125},
      { -0.375,    -0.5,  -0.375,   0.375,   -0.25,   0.375},
    },
  }

  local selection_box = {
    type = "fixed",
    fixed = {
      {-0.4375, -0.5, -0.4375, 0.4375, 0.25, 0.4375},
    },
  }

  local function render_formspec(pos, player, state)
    local spos = pos.x .. "," .. pos.y .. "," .. pos.z

    local cio = fspec.calc_inventory_offset
    local inv_name =  "nodemeta:"..spos

    local time = math.max(state.time, 0)
    local time_max = math.max(state.time_max, 1)
    local arrow_percent = 0
    local meter_percent = 0
    if time_max > 0 then
      arrow_percent = math.floor(100 * (1 - (time / time_max)))
      meter_percent = (arrow_percent * 8) % 100
    end

    if yspec then
      return yspec.render_split_inv_panel(player, 4, 4, { bg = "default" }, function (loc, rect)
        if loc == "main_body" then
          -- fuel
          -- core
          -- material
          -- processing
          -- main
          return ""
            .. fspec.label(rect.x + 1, rect.y + 0.25, "Output")
            .. fspec.list(inv_name, "main", rect.x + 1, rect.y + 0.5, 1, 1)
            .. fspec.label(rect.x, rect.y + 2.25, "Fuel")
            .. fspec.list(inv_name, "fuel", rect.x, rect.y + 2.5, 1, 1)
            .. fspec.label(rect.x + 2, rect.y + 2.25, "Core")
            .. fspec.list(inv_name, "core", rect.x + 2, rect.y + 2.5, 1, 1)
            .. fspec.label(rect.x + cio(1) + 2, rect.y + 2.25, "Material")
            .. fspec.list(inv_name, "material", rect.x + cio(1) + 2, rect.y + 2.5, 1, 1)
            .. fspec.image(rect.x + 1, rect.y + 1.5, 1, 2,
              "maidroid_tool_gui_arrow.png^[lowpart:" .. arrow_percent .. ":maidroid_tool_gui_arrow_filled.png"
            )
            .. fspec.image(rect.x + 0.5, rect.y + 3.5, 2, 1,
              "maidroid_tool_gui_meter.png^[lowpart:" .. meter_percent .. ":maidroid_tool_gui_meter_filled.png^[transformR270"
            )
        elseif loc == "footer" then
          return ""
            .. fspec.list_ring("current_player", "main")
            .. fspec.list_ring(inv_name, "fuel")
            .. fspec.list_ring("current_player", "main")
            .. fspec.list_ring(inv_name, "core")
            .. fspec.list_ring("current_player", "main")
            .. fspec.list_ring(inv_name, "material")
            .. fspec.list_ring("current_player", "main")
            .. fspec.list_ring(inv_name, "main")
        end
        return ""
      end)
    end

    if rawget(_G, "default") then
      -- function (time)
      --   return "size[8,9]"
      --     .. default.gui_bg
      --     .. default.gui_bg_img
      --     .. default.gui_slots
      --     .. "label[3.75,0;Core]"
      --     .. "list[current_name;main;3.5,0.5;1,1;]"
      --     .. "label[2.75,2;Coal]"
      --     .. "list[current_name;fuel;2.5,2.5;1,1;]"
      --     .. "label[4.75,2;Dye]"
      --     .. "list[current_name;dye;4.5,2.5;1,1;]"
      --     .. "image[3.5,1.5;1,2;maidroid_tool_gui_arrow.png^[lowpart:"
      --     .. arrow_percent
      --     .. ":maidroid_tool_gui_arrow_filled.png]"
      --     .. "image[3.1,3.5;2,1;maidroid_tool_gui_meter.png^[lowpart:"
      --     .. meter_percent
      --     .. ":maidroid_tool_gui_meter_filled.png^[transformR270]"
      --     .. "list[current_player;main;0,5;8,1;]"
      --     .. "list[current_player;main;0,6.2;8,3;8]"
      -- end

      return "size[8,9]" ..
        default.gui_bg ..
        default.gui_bg_img ..
        default.gui_slots ..
        "label[3.75,0;Core]" ..
        "list[current_name;main;3.5,0.5;1,1;]" ..
        "label[2.75,2;Coal]" ..
        "list[current_name;fuel;2.5,2.5;1,1;]" ..
        "label[4.75,2;Dye]" ..
        "list[current_name;material;4.5,2.5;1,1;]" ..
        "image[3.5,1.5;1,2;maidroid_tool_gui_arrow.png]" ..
        "image[3.1,3.5;2,1;maidroid_tool_gui_meter.png^[transformR270]" ..
        "list[current_player;main;0,5;8,1;]" ..
        "list[current_player;main;0,6.2;8,3;8]"
    end
  end

  local tiles = {
    ["inactive"] = {
      "maidroid_tool_core_writer_top.png",
      "maidroid_tool_core_writer_bottom.png",
      "maidroid_tool_core_writer_right.png",
      "maidroid_tool_core_writer_right.png^[transformFX",
      "maidroid_tool_core_writer_front.png^[transformFX",
      "maidroid_tool_core_writer_front.png",
    },

    ["active"] = {
      "maidroid_tool_core_writer_top.png",
      "maidroid_tool_core_writer_bottom.png",
      "maidroid_tool_core_writer_right.png",
      "maidroid_tool_core_writer_right.png^[transformFX",
      {
        backface_culling = false,
        name = "maidroid_tool_core_writer_front_active.png^[transformFX",

        animation = {
          type      = "vertical_frames",
          aspect_w  = 16,
          aspect_h  = 16,
          length    = 1.5,
        },
      },
      {
        backface_culling = false,
        name = "maidroid_tool_core_writer_front_active.png",

        animation = {
          type      = "vertical_frames",
          aspect_w  = 16,
          aspect_h  = 16,
          length    = 1.5,
        },
      },
    },
  }

  local function on_deactivate(pos)

  end

  local function on_activate(pos)

  end

  local function on_metadata_inventory_put_to_main(pos)

  end

  local function on_metadata_inventory_take_from_main(pos)

  end

  mod._aux.register_writer(mod:make_name("core_writer"), {
    description                           = mod.S("Maidroid Core Writer"),
    formspec                              = render_formspec,
    tiles                                 = tiles,
    node_box                              = node_box,
    selection_box                         = selection_box,
    duration                              = 40,
    on_activate                           = on_activate,
    on_deactivate                         = on_deactivate,
    empty_itemname                        = mod:make_name("core_empty"),
    recipe_registry                       = assert(mod.core_recipes),
    on_metadata_inventory_put_to_main     = on_metadata_inventory_put_to_main,
    on_metadata_inventory_take_from_main  = on_metadata_inventory_take_from_main,
  })
end
