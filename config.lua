--
-- HSW Maidroid Config
--

--- @namespace hsw_maidroid
local mod = assert(hsw_maidroid)

local fspec = assert(foundation.com.formspec.api)
local Color = assert(foundation.com.Color)

mod.config = mod.config or {}

-- Default Skin Tones
mod.config.skin_tones = mod.config.skin_tones or {}
mod.config.hair_colors = mod.config.hair_colors or {}

--- @type ColorEntry: {
---   name: String,
---   description: String,
---   color: Color,
---   color_string: ColorSpec,
--- }

--- @type ColorCache: {
---   count: Integer,
---   ordered: ColorEntry[],
--- }

--- @type ColorMap: {
---   [name: String]: ColorEntry,
--- }

--- @spec build_color_palette_cache(ColorMap): ColorCache
function mod.build_color_pallete_cache(colors_map)
  local defa = colors_map["default"]
  local base = foundation.com.table_copy(colors_map)
  base["default"] = nil
  local entries = foundation.com.table_values(base)
  entries = foundation.com.list_sort_by(entries, function (entry)
    return entry.description
  end)

  local ordered

  if defa then
    ordered = foundation.com.list_concat({defa}, entries)
  else
    ordered = entries
  end

  return {
    count = #ordered,
    ordered = ordered,
  }
end

--- @type HairColor: ColorEntry
--- @type SkinTone: ColorEntry

--- @spec get_hair_color(name: String): SkinTone
function mod.get_hair_color(name)
  return mod.config.hair_colors[name]
end

--- @spec fetch_hair_color(name: String): SkinTone
function mod.fetch_hair_color(name)
  local result = mod.config.hair_colors[name]
  if not result then
    error("skin tone name=" .. name .. " not found")
  end
  return result
end

--- @spec register_hair_color(name: String, description: String, color: Color): SkinTone
function mod.register_hair_color(name, description, color)
  local def = {
    name = name,
    description = assert(description),
    color = assert(color),
    color_string = Color.to_string24(color),
  }
  mod.config.hair_colors[name] = def
  mod.config.hair_color_cache = nil
  return def
end

--- @spec get_hair_color_cache(): ColorCache
function mod.get_hair_color_cache()
  if not mod.config.hair_color_cache then
    mod.config.hair_color_cache = mod.build_color_pallete_cache(mod.config.hair_colors)
  end

  return mod.config.hair_color_cache
end

--- @spec get_skin_tone(name: String): SkinTone
function mod.get_skin_tone(name)
  return mod.config.skin_tones[name]
end

--- @spec fetch_skin_tone(name: String): SkinTone
function mod.fetch_skin_tone(name)
  local result = mod.config.skin_tones[name]
  if not result then
    error("skin tone name=" .. name .. " not found")
  end
  return result
end

--- @spec register_skin_tone(name: String, description: String, color: Color): SkinTone
function mod.register_skin_tone(name, description, color)
  local def = {
    name = name,
    description = assert(description),
    color = assert(color),
    color_string = Color.to_string24(color),
  }
  mod.config.skin_tones[name] = def
  mod.config.skin_tone_cache = nil
  return def
end

--- @spec get_skin_tone_cache(): ColorCache
function mod.get_skin_tone_cache()
  if not mod.config.skin_tone_cache then
    mod.config.skin_tone_cache = mod.build_color_pallete_cache(mod.config.skin_tones)
  end

  return mod.config.skin_tone_cache
end

--- @type RenderColorPalleteOptions: {
---   palette_cache?: ColorCache,
---   basename?: String = "swt_",
---   x: Number,
---   y: Number,
---   w: Number,
---   h: Number,
---   cols?: Number | Boolean = 1,
---   current_value?: String,
---   show_label?: Boolean = false,
---   show_tooltip?: Boolean = false
--- }

--- @spec mod.render_color_palette(options: RenderColorPalleteOptions): String
function mod.render_color_palette(options)
  local cache = assert(options.palette_cache, "expected a palette cache")

  local formspec = ""

  local basename = options.basename or "swt_"

  local x = options.x
  local y = options.y
  local w = options.w
  local h = options.h -- kind of unusued?
  local cols = options.cols

  if cols == true then
    -- shoutout to chatgpt, because I'm a dumb-dumb and couldn't figure this one out on my own.
    local area = assert(w, "expected w(idth)") * assert(h, "expected h(eight)")
    local area_per_cell = area / cache.count
    local acw = math.sqrt(area_per_cell)
    cols = math.floor(w / acw)
  elseif cols == false then
    cols = 1
  else
    cols = cols or 1
  end

  local cw = w / cols
  local ch = cw

  local cx
  local cy

  local texture_name
  local label
  local element_name

  local current_value = options.current_value
  local show_label = options.show_label or false
  local show_tooltip = options.show_tooltip or false

  for idx, skin_tone in ipairs(cache.ordered) do
    cx = (idx - 1) % cols
    cy = math.floor((idx - 1) / cols)

    texture_name = "maidroid_gui_swatch_button.png^[multiply:"..skin_tone.color_string

    if current_value == skin_tone.name then
      texture_name = texture_name .. "^maidroid_gui_swatch_border.png"
    end

    if show_label then
      label = skin_tone.description
    else
      label = ""
    end

    element_name = basename .. skin_tone.name

    formspec = formspec
      .. fspec.image_button(
        x + cx * cw,
        y + cy * ch,
        cw,
        ch,
        texture_name,
        element_name,
        label
      )

    if show_tooltip then
      formspec = formspec
        .. fspec.tooltip_element(element_name, skin_tone.description)
    end
  end

  return formspec
end

--- @mutative options
--- @spec mod.render_hair_color_palette(options: RenderColorPalleteOptions): String
function mod.render_hair_color_palette(options)
  options.palette_cache = mod.get_hair_color_cache()
  return mod.render_color_palette(options)
end

--- @mutative options
--- @spec mod.render_skin_tone_palette(options: RenderColorPalleteOptions): String
function mod.render_skin_tone_palette(options)
  options.palette_cache = mod.get_skin_tone_cache()
  return mod.render_color_palette(options)
end

---
--- Register Skin Tones
---
do
  --- Very dark
  mod.register_skin_tone("gunmetal",   "Gunmetal",   Color.new( 41,  39,  41))
  --- Natural Skin Tones
  mod.register_skin_tone("chocolate",  "Chocolate",  Color.new( 40,  23,  11))
  mod.register_skin_tone("espresso",   "Espresso",   Color.new( 97,  51,  16))
  mod.register_skin_tone("golden",     "Golden",     Color.new(121,  66,  27))
  mod.register_skin_tone("umber",      "Umber",      Color.new(181, 102,  68))
  mod.register_skin_tone("bronze",     "Bronze",     Color.new(121,  66,  27))
  mod.register_skin_tone("almond",     "Almond",     Color.new(146,  95,  58))
  mod.register_skin_tone("band",       "Band",       Color.new(173, 137,  96))
  mod.register_skin_tone("honey",      "Honey",      Color.new(205, 150,  90))
  mod.register_skin_tone("amber",      "Amber",      Color.new(189, 100,  52))
  mod.register_skin_tone("sienna",     "Sienna",     Color.new(210, 158, 119))
  mod.register_skin_tone("beige",      "Beige",      Color.new(245, 193, 129))
  mod.register_skin_tone("limestone",  "Limestone",  Color.new(239, 192, 145))
  mod.register_skin_tone("rose_beige", "Rose Beige", Color.new(248, 213, 161))
  mod.register_skin_tone("sand",       "Sand",       Color.new(248, 217, 151))
  mod.register_skin_tone("warm_ivory", "Warm Ivory", Color.new(253, 231, 169))
  mod.register_skin_tone("pale_ivory", "Pale Ivory", Color.new(252, 224, 195))
  --- Maidroid Original Skin Tone
  mod.register_skin_tone("default",    "Default",    Color.new(253, 218, 198))
end

---
--- Register Hair Colors
---
do
  --- Sourced from https://folio.procreate.com/discussions/10/28/23012
  -- Highlights
  mod.register_hair_color("#dcc49b", "A#dcc49b", Color.from_colorstring("#dcc49b"))
  mod.register_hair_color("#ccb284", "A#ccb284", Color.from_colorstring("#ccb284"))
  mod.register_hair_color("#ebbc8e", "A#ebbc8e", Color.from_colorstring("#ebbc8e"))
  mod.register_hair_color("#c84e37", "A#c84e37", Color.from_colorstring("#c84e37"))
  mod.register_hair_color("#c6570b", "A#c6570b", Color.from_colorstring("#c6570b"))
  mod.register_hair_color("#925b3e", "A#925b3e", Color.from_colorstring("#925b3e"))
  mod.register_hair_color("#5c4026", "A#5c4026", Color.from_colorstring("#5c4026"))
  mod.register_hair_color("#7c3c39", "A#7c3c39", Color.from_colorstring("#7c3c39"))
  mod.register_hair_color("#544e4d", "A#544e4d", Color.from_colorstring("#544e4d"))
  mod.register_hair_color("#68707d", "A#68707d", Color.from_colorstring("#68707d"))
  -- Base Colors
  mod.register_hair_color("#a68154", "B#a68154", Color.from_colorstring("#a68154"))
  mod.register_hair_color("#c5a46d", "B#c5a46d", Color.from_colorstring("#c5a46d"))
  mod.register_hair_color("#db9d63", "B#db9d63", Color.from_colorstring("#db9d63"))
  mod.register_hair_color("#65110c", "B#65110c", Color.from_colorstring("#65110c"))
  mod.register_hair_color("#862109", "B#862109", Color.from_colorstring("#862109"))
  mod.register_hair_color("#4f2a11", "B#4f2a11", Color.from_colorstring("#4f2a11"))
  mod.register_hair_color("#372213", "B#372213", Color.from_colorstring("#372213"))
  mod.register_hair_color("#472220", "B#472220", Color.from_colorstring("#472220"))
  mod.register_hair_color("#342422", "B#342422", Color.from_colorstring("#342422"))
  mod.register_hair_color("#21201f", "B#21201f", Color.from_colorstring("#21201f"))
  -- Shadows
  mod.register_hair_color("#775c31", "C#775c31", Color.from_colorstring("#775c31"))
  mod.register_hair_color("#806d54", "C#806d54", Color.from_colorstring("#806d54"))
  mod.register_hair_color("#853f29", "C#853f29", Color.from_colorstring("#853f29"))
  mod.register_hair_color("#310e15", "C#310e15", Color.from_colorstring("#310e15"))
  mod.register_hair_color("#5a1613", "C#5a1613", Color.from_colorstring("#5a1613"))
  mod.register_hair_color("#472220", "C#472220", Color.from_colorstring("#472220"))
  mod.register_hair_color("#171008", "C#171008", Color.from_colorstring("#171008"))
  mod.register_hair_color("#310e15", "C#310e15", Color.from_colorstring("#310e15"))
  mod.register_hair_color("#120e10", "C#120e10", Color.from_colorstring("#120e10"))
  mod.register_hair_color("#050608", "C#050608", Color.from_colorstring("#050608"))
  --- White
  mod.register_hair_color("#ffffff", "Default", Color.new(255, 255, 255))
end
